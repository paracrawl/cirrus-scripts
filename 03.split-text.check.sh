#!/bin/bash
set -euo pipefail
. ./config.csd3
. ./functions.sh

THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	local docs_pt=$(gzip -cd $1/plain_text.gz | wc -l)
	local docs_st=$(gzip -cd $1/sentences.gz | wc -l)
	if test ! "$docs_pt" -eq "$docs_st"; then 
		echo $1/sentences.gz
		return
	fi
}

export -f validate

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate 
done
		
