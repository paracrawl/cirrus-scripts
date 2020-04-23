#!/bin/bash
set -euo pipefail
. config.csd3
. functions.sh

THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	if is_marked_valid 02 $1 mime.gz source.gz plain_text.gz url.gz ; then
		return 0
	fi

	local mime_cnt=$(gzip -cd $1/mime.gz | wc -l)
	local source_cnt=$(gzip -cd $1/source.gz | wc -l)
	local doc_cnt=$(gzip -cd $1/plain_text.gz | wc -l)
	local url_cnt=$(gzip -cd $1/url.gz | wc -l)
	if test ! "$mime_cnt" -eq "$source_cnt" \
		|| test ! "$source_cnt" -eq "$doc_cnt" \
		|| test ! "$doc_cnt" -eq "$url_cnt"; then
		echo $1/plain_text.gz
	else
		mark_valid 02 $1
	fi
}

export -f validate is_marked_valid mark_valid

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate 
done
		
