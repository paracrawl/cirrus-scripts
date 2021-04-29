# batch_dedupe
Deduplicate batches inside shards while maintaining column integrity.

```
Usage: [options] <path/to/batch> [<path> ...]

Batch options:
  -c [ --combined ] arg                 Columns that should be combined
  -d [ --derived ] arg                  Columns that are derived
  -u [ --unique ] arg                   Column to deduplicate on
  -o [ --output ] arg (=.)              Output path
  -b [ --bytes ] arg (=1073741824)      Maximum batch size (uncompressed)
  -l [ --limit ] arg (=18446744073709551615)
                                        Maximum number of combined values in a
                                        row
  -g [ --glue ] arg (= )                Glue between combined values
  -v [ --verbose ]                      Print progress updates
  -h [ --help ]                         Produce help message
```

## Example
```
batch_dedupe \
	--verbose \
	--bytes $(( 3 * 1024 * 1024 * 1024 )) \
	--limit $(( 1024 * 1024 )) \
	--combined source.gz url.gz \
	--derived sentences.gz sentences_en.gz \
	--unique sentences.gz \
	-- \
	batch1/ batch2/ batch3/
```

This command will read through *batch1* to *batch3*, opening columns *source.gz*,
*url.gz*, *sentences.gz* and *sentences_en.gz*. It will look at *sentences.gz* (the
--unique option) to determine whether a row is unique or not. If it is a
duplicate, the line in *sentences.gz* and *sentences_en.gz* (the --derived option)
will be skipped as they are apparently duplicates.
The line in *source.gz* and *url.gz* (the --combined option) will
be appended to the *source.gz* and *url.gz* line of the original unique record.
The separator for this can be changed with --glue, a space character is the
default.

## Memory usage
Lines from columns specified in `--derived` are only kept in memory one at a time.
If the record is deemed unique, they're sent to a unbound memory queue for
compression & writing. Worst case this queue can contain a full uncompressed
output batch per file mentioned in `--derived`. It cannot grow larger than
`--bytes`.

Additionally, all values for the columns mentioned in `--combined` are kept in
memory until the end of the process. If specified, this is somewhat limited by
`--limit`.

Finally, an index of unique records is kept based of the size
`(uint64_t) hash + (int64_t. offset`. But compared to the other two, this is
relatively minor.

# merge_sort
Basically `sort --merge` but accepts gzipped input files, and files can be
specified through stdin instead of arguments, so there's no limit to the
number of files.

Only works if files are already sorted with the same sort flags as merge-sort
is called with.

```
Usage: [-k key] [-t delim] [-h] [-f filelist] [file ...]

Options:
  -k [ --key ] arg (=1,)            Column(s) key to use as the deduplication
                                    string. Can be multiple ranges separated by
                                    commas. Each range can have n(umeric) or
                                    r(reverse) as flag.
  -t [ --field-separator ] arg (=	) Field separator
  -o [ --output ] arg (=-)          Output file
  -j [ --threads ] arg (=4)         Thread count
  -f [ --files-from ] arg           Read file names from separate file (or '-'
                                    for stdin)
  -h [ --help ]                     Produce help message
```

## Speed
Files are decompressed in threads, so in theory, if there are at least more than
one input files, this should be faster than `gzip cd * | cat`.
