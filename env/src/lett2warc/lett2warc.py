''' Convert lett files to warcs.\n
From the information in the lett files we only use columns 4 (url) and 5 (base64 encoded content).\n
We discard language information (column 1), encoding and document type information (columns 2 & 3 - they 
do not appear to be reliable) and extracted clean test (column 5, since we are doing that later on in our pipeline 
anyway and we want processing consistency).\n
The HTTP headers of the warc files are not valid but are filled (with the same information for all records) to enable
downstream processing with the other parts of the paracrawl pipeline.

The script has been designed to run on one directory at a time. 
It expects the name of a directory and it will sequentially process all lett files in the directory
and produce warcs of circa 1GB of size. It will thus combine many smaller lett files together or split
large files into smaller ones. To reduce complexity, when a lett file is split into more than one warc file,
we are not introducing continuation of warcs records (out pipeline doesnot make use of this information anyway).

Warc files will be saved in a user-defined output folder.
Individual warc files will follow the naming convention: WARC_BASENAME-DIRPROCESSED-N.warc.gz, 
where: DIRPROCESSED is the directory being processed and N is an integer (staring from 0).

The code will log sucessfull completion of processing of warc files and any errors in appropriate log files.
Logs will be placed inside the user-defined log folder.
The naming convention for log files is: WARC_BASENAME-lett2warc-dir-DIRPROCESSED.log, philipp-lett2warc-dir-DIRPROCESSED.err  

The script will discarge any partially corrupted records (defined as records which include at least 4 consecutive null bytes)
and keep a record of ignored files in the *.err log files. 

ARGUMENTS:
    - Mandatory:
        -d [--lett_dir]:        str, directory containing the lett files to be processed
    - Optional:
        -o [--output_dir]:      str, directory that will hold the files produced (will be created if non-existent)
        -l [--log_dir]:         str, directory to store process logs (will be created if non-existent)
        -s [--warc_size_limit]: int, Maximum size (in bytes) of each individual warc file (default: 1e9)
	-n [--base-warc-name]:  str, the basename to use to save produced warcs, the lettdirname and the incremental warc id will be added to it
				[default: "philipp_crawl"]
USAGE:
    - Basic use:
    >>> python3 lett2warc.py -d lettDirectory
    - For parallel processing one has to create a list of the directories that will be processed and then: 
    >>> ls $path/to/dir/of/dirs > listOFdirectories.lst
    >>> ls /fs/startiger0/pkoehn/lett | awk 'length($0)==2{printf "/fs/startiger0/pkoehn/lett/"$0 "\n"}' >\
    >>>                                                                                 lett_dir_list.lst
    >>> cat lett_dir_list.lst | parallel -j 6 -k python3 lett2warc.py '-d {}'
    - Using non-default direcotries and gnu-parallel to process files in parallel
    >>> head -n256 lett_dir_list.lst | tail -n64 | parallel -j 16 -k python3 lett2warc.py '-d {} -o /fs/hodor0/sminas/philipp_crawl -l /fs/hodor0/sminas/philipp_crawl/logs -c True'
'''

import os
import sys
import io
import argparse
import re
from datetime import datetime
import time
from pathlib import Path
import base64
from warcio.warcwriter import WARCWriter
from warcio.statusandheaders import StatusAndHeaders
import lzma
import logging
import logging.handlers

def runner(WARC_SIZE_LIMIT, DIR2PROCESS, OUTPATH, LOGPATH, WARC_BASENAME):
    # script parameters
    DIR2PROCESS = Path(DIR2PROCESS)
    OUTPATH = Path(OUTPATH)
    LOGPATH = Path(LOGPATH)
    OUTPATH.mkdir(parents=True, exist_ok=True)
    LOGPATH.mkdir(parents=True, exist_ok=True)
    LOGFILE = LOGPATH / (WARC_BASENAME + "-lett2warc-dir-" + DIR2PROCESS.absolute().name)
    FILES2PROCESS = sorted(list(DIR2PROCESS.glob("*.lett.xz")), \
                            key=os.path.getsize, reverse=True)
    # lett_dir=/fs/startiger0/pkoehn/lett/
    # logging setup
    f = logging.Formatter(fmt='%(name)s:%(levelname)s: %(message)s '
        '(%(asctime)s)',# %(filename)s:%(lineno)d)',
        datefmt="%Y-%m-%d %H:%M:%S")
    info_handlers = [
        logging.handlers.WatchedFileHandler(filename=str(LOGFILE.absolute())+".log", encoding='utf8'),
        logging.StreamHandler()
    ]
    info_logger = logging.getLogger(name="info_log")
    info_logger.setLevel(logging.DEBUG)
    for h in info_handlers:
        h.setFormatter(f)
        h.setLevel(logging.DEBUG)
        info_logger.addHandler(h)
    error_handler = logging.handlers.WatchedFileHandler(filename=str(LOGFILE.absolute())+".err", encoding='utf8')
    error_handler.setFormatter(f)
    error_handler.setLevel(logging.ERROR)
    error_logger = logging.getLogger(name="error_log")
    error_logger.setLevel(logging.ERROR)
    error_logger.addHandler(error_handler)
    # main code
    file_i = 0
    warc_i = 0
    record_i = 0
    warc_line_i = 0
    error_i = 0
    n_corrupted = 0
    warc_filename = OUTPATH/ (WARC_BASENAME + "-" + DIR2PROCESS.absolute().name + "-" + str(warc_i) + ".warc.gz")
    f_out = open(warc_filename, 'wb')
    warc_writer = WARCWriter(f_out, gzip=True)
    writer = warc_writer
    WARC_TYPE = "N"
    CREATION_DATE = datetime.now().replace(microsecond=0).isoformat()
    date_pattern = re.compile("\d{4}-\d{2}-\d{2}")
    datefrmt = "%Y-%m-%dT%H:%M:%S"
    t1 = time.time()
    logging.info("Starting processing lett directory {} ...".format(DIR2PROCESS.absolute().name))
    if len(FILES2PROCESS) == 0: 
        error_logger.error("No lett.xz files found in provided directory. Verify that the path is correct.")
        return
    else:
        msg = "\n" + "+-"*40 + "\n"
        msg += "Started processing lett directory: {}\n".format(DIR2PROCESS.absolute().name)
        msg += "\n" + "+-"*40 + "\n"
        error_logger.error(msg)
        info_logger.info(msg)
    for current_lett_file in FILES2PROCESS:
        datestr = re.findall(date_pattern, os.path.basename(current_lett_file))
        if len(datestr) > 0:
            # does the filename contain crawl date information?
            datestr = datestr[-1] + "T00:00:00"
        else:
            datestr = CREATION_DATE
        CRAWL_DATE = datetime.strptime(datestr, datefrmt).isoformat()
        filesize = 0
        file_line_i = 0
        with lzma.open(current_lett_file, "rb") as f_in:
            try:
                if not f_in.read(1): 
                    error_logger.error("File has no content. File:{}".format(str(current_lett_file)))
                    error_i += 1
                    # raise Exception("File has no content!")
                    continue
                else:
                    info_logger.info("Processing file:{}.".format(current_lett_file))
                    f_in.seek(0)
                for line in f_in:
                    try:
                        parts = line.split(b"\t")
                        url = parts[3].decode("utf-8")
                        content = base64.b64decode(parts[4])
                        record_i += 1
                        file_line_i += 1
                        null_index = content.find(b'\x00\x00\x00\x00')
                        if null_index >= 0:
                            n_corrupted += 1
                            error_logger.error("Corrupted record. URI:{} File:{}".format(url, current_lett_file.absolute().name))
                            continue
                        warc_line_i += 1
                        filesize = f_out.tell()
                        headers_list = [('Content-Type', 'text/html; charset=UTF-8'), ('Date', CRAWL_DATE), \
                                        ('Expires', CREATION_DATE), \
                                        ('Last-Modified', CREATION_DATE), \
                                        ('Content-Length', str(len(content)))]
                        http_headers = StatusAndHeaders('200 OK', headers_list, protocol='HTTP/1.0')
                        record = writer.create_warc_record(url, 'response',
                                                            payload=io.BytesIO(content),
                                                            http_headers=http_headers)
                        writer.write_record(record)
                    except Exception as Error:
                        error_logger.error("Error in file:{} url:{} record:{}. Error type:{}".format(
                                            current_lett_file.absolute().name, url, file_line_i, Error))
                        error_i += 1
                    # check size of warcfile 
                    # if larger than 1GB then break into 2 or more
                    if filesize >= WARC_SIZE_LIMIT:
                        f_out.close()
                        info_logger.info("Completed warc {}, containing {} records. Moving on...".format(warc_filename, warc_line_i))
                        warc_i += 1
                        warc_filename = OUTPATH / (WARC_BASENAME + "-" + DIR2PROCESS.absolute().name + "-" + str(warc_i) + ".warc.gz")
                        f_out = open(warc_filename, 'wb')
                        warc_writer = WARCWriter(f_out, gzip=True)
                        writer = warc_writer
                        warc_line_i = 0
                info_logger.info("Processed file: {}, containing {} records.".format(current_lett_file, file_line_i))
            except Exception as Error:
                error_logger.error("Damaged file:{}, Error message:{}".format(current_lett_file, Error))
                error_i += 1
        file_i += 1
    t2 = time.time()
    try:
        f_out.close()
        info_logger.info("Completed warc {}, containing {} records. Moving on...".format(warc_filename.absolute().name, warc_line_i))
    except Exception as Error:
        info_logger.warning("Attempted to close warcfile that is already closed. Error:", Error)
    info_logger.info("Completed processing of lett directory \"{}\".Processed {} files, {} records, {} corrupted files, {} errors. \nTotal processing time: {:2.4f}m".format(
                        DIR2PROCESS.absolute().name, file_i, record_i, n_corrupted, error_i, (t2-t1)/60.))

if __name__ == "__main__":

    parser = argparse.ArgumentParser(prog=os.path.basename(sys.argv[0]), formatter_class=argparse.ArgumentDefaultsHelpFormatter, description=__doc__)

    groupM = parser.add_argument_group("Mandatory")
    groupM.add_argument('-d', '--lett_dir', type=str, required=True, help="Directory containing the lett files to be processed.") 

    groupO = parser.add_argument_group('Optional')
    groupO.add_argument('-s', '--warc_size_limit', type=float, required=False, 
                        help="Maximum size (in bytes) of each individual warc file.", 
                        default=1e9)
    # valhala
    groupO.add_argument('-o', '--output_dir', type=str, required=False,
                        help="Full path to store the produced warc files (will be created if non-existent).",
                        default="/fs/lofn0/sminas/philipp_crawl")
    groupO.add_argument('-l', '--log_dir', type=str, required=False,
                        help="Full path to store process logs (will be created if non-existent).",
                        default="/fs/lofn0/sminas/philipp_crawl/logs")
    groupO.add_argument('-n', '--warc-base-name', type=str, required=False,
                        help="Basename to use for saving produced warcs and logs. The lett file directory and (autogenerated) incremental warc_id will be added to it.",
                        default="philipp_crawl")

    args = vars(parser.parse_args())

    runner( WARC_SIZE_LIMIT=args['warc_size_limit'], 
            DIR2PROCESS=args['lett_dir'], 
            OUTPATH=args['output_dir'], 
            LOGPATH=args['log_dir'],
            WARC_BASENAME=args['warc_base_name'] )
