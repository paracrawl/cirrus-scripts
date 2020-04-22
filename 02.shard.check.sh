#!/bin/bash
set -euo pipefail
. ./config.csd3
. ./functions.sh

THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	local mime_cnt=$(gzip -cd $1/mime.gz | wc -l)
	local source_cnt=$(gzip -cd $1/source.gz | wc -l)
	local doc_cnt=$(gzip -cd $1/plain_text.gz | wc -l)
	if test ! "$mime_cnt" -eq "$source_cnt" || test ! "$source_cnt" -eq "$doc_cnt"; then
		echo $1/plain_text.gz
	fi
}

export -f validate

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate 
done
		
