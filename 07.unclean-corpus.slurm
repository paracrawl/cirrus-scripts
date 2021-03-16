#!/bin/bash
set -euo pipefail

DEST=$1
TARGET_SHARDS=$2
shift 2

TMPSFX=${JOB_ID:-$$}

cat $@ \
| while read batch; do
	find $batch -maxdepth 1 -type f -regex '.*/aligned-[0-9]*.gz$' | while read match; do
		echo $match 1>&2
		paste <(gzip -cd ${match} \
				| awk -F '\t' '{ print 0.0 "\t" $1 "\t"  $2}' \
				| docjoin \
					-r ${TARGET_SHARDS}/$(basename $(dirname $batch))/$(echo $match | sed 's/.*-\([0-9]*\)\.gz/\1/')/url.gz \
					-l $(dirname ${match})/url.gz) \
			  <(gzip -cd $match | cut -f4) \
			  <(gzip -cd $match | cut -f3) \
			  <(gzip -cd $match | cut -f5-)
	done
done \
| gzip -c > $DEST.$TMPSFX

mv $DEST.$TMPSFX $DEST
