## Convert lett files to warcs for processing with the paracrawl pipeline
The lett files that we receive are organised in crawl directories. 
Each lett file comes from a single domain, hence the filesize can vary widely. 
The general naming convention is: `LettDirName_DomainName.CrawlDate_vX.lett.xz`, the crawl date being in the form: YYYY-MM-DD. 
For example: `9e_suntech-metals.com.2020-12-28_v2.lett.xz` is within directory `9e`, has content from `suntech-metals.com`, was crawled on 28/12/2020 with v2 of the software.    
The content in the lett files is organised in 5 columns:
```
lang \t encoding_type \t document_type \t url \t base64_encoded_content \n
```   
We only use columns 4 (url) and 5 (base64 encoded content, which we decode) and the crawl date (which is extracted from the filename) and discard with all other columns. More reliable language (column 1) detection happens downstream in the pipeline while encoding type and document type information (columns 2 & 3) are  not reliable.  
In order for the generated warc to be valid (so it can be processed by the pipeline) some other HTTP headers ((e.g. website creation date)) need to be populated. Since this is information that is not used anywhere in the pipeline but needs to exist nonetheless, these are filled with the same fixed strings for all records.  
***
### Requirements
- python3.5+
- warcio, `pip install warcio`
***
### Operation
The script has been designed to operate on one directory at a time. 
It expects the name of a directory and it will sequentially process all lett files in the directory
and produce warc files of circa 1GB of size. It will thus combine many smaller lett files together or split
large files into smaller ones. To reduce complexity, when a lett file is split into more than one warc file,
we do not make use of the option to introduce continuation of warcs records (since the pipeline does not make use of this information anyway).
Warc files will be saved in a user-defined output folder (variable OUTPATH in the code).
Individual warc files will follow the naming convention: WarcBaseName-LettDIR-N.warc.gz, where: LettDIR is the directory being processed and N is an integer
(staring from 0).  
The code will log processing information and any errors that occured in appropriately named \*.log and \*.err log files.  
Logs will be placed in a user-defined log folder (variable LOGPATH in the code)".  
The naming convention for log files is: philipp-lett2warc-dir-LettDIR.log, philipp-lett2warc-dir-LettDIR.err  
By default the script will discharge any partially corrupted records (defined as records which include at least 4 consecutive null bytes)
and keep a record of ignored files in the \*.err log files.  
***
### Usage
Basic use:  
```
    python3 lett2warc.py -d path/to/input/lett-directory \
                         -o path/to/output/directory \
                         -l paht/to/log/dir \
                         -n "phillip_crawl"
                         -s 1e9
```
where the arguments are:  
```
    - Mandatory:
        -d [--lett-dir]:        str, directory containing the lett files to be processed
    - Optional:
        -o [--output-dir]:      str, directory that will hold the files produced (will be created if non-existent)
        -l [--log-dir]:         str, directory to store process logs (will be created if non-existent)
        -s [--warc-size-limit]: int, Maximum size (in bytes) of each individual warc file (default: 1e9)
        -n [--warc-base-name]:  str, the basename to use when saving warc files.  [default: "philipp_crawl"].
```
Parallel processing:
- create a list of the directories that will be processed, e.g.:
```
    LP=/path/to/lett/dir && find $LP -depth 1 -type d | xargs -I% echo % > lett_dir_list.lst
```
- use gnu parallel to allocate groups of directories to different processes, e.g., 
```
    cat lett_dir_list.lst | parallel -j 16 -k python3 lett2warc.py '-d {} -o /path/to/output/dir -l /path/to/log/dir'
```
__N.B.:__ The script will try to pick up the crawl date (format YYYY-MM-DD) from the lett filename and put it in the relevant http header in the WARC.
If the filename does not include the crawl date then the current date will be used instead. In the absence of information, the current date is also used for the http headers \"Expires\" and \"Last-Modified\".  
