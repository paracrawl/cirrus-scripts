#!/bin/bash
set -euo pipefail
. config.csd3
. functions.sh

THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	set -euo pipefail

	if is_marked_valid 02 $1 mime.gz source.gz plain_text.gz url.gz ; then
		return 0
	fi

	local mime_cnt source_cnt doc_cnt url_cnt
	if mime_cnt=$(gzip -cd $1/mime.gz | wc -l) \
		&& source_cnt=$(gzip -cd $1/source.gz | wc -l) \
		&& doc_cnt=$(gzip -cd $1/plain_text.gz | wc -l) \
		&& url_cnt=$(gzip -cd $1/url.gz | wc -l) \
		&& test "$mime_cnt" -eq "$source_cnt" \
		&& test "$source_cnt" -eq "$doc_cnt" \
		&& test "$doc_cnt" -eq "$url_cnt"; then
		mark_valid 02 $1
	else
		echo $1/plain_text.gz
	fi
}

export -f validate is_marked_valid mark_valid

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate 
done
		
