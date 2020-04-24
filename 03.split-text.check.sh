#!/bin/bash
set -euo pipefail
. ./config.csd3
. ./functions.sh

THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	if is_marked_valid 03 $1 plain_text.gz sentences.gz ; then
		return 0
	fi

	local docs_st=$(gzip -cd $1/sentences.gz | wc -l)
	local docs_pt=$(gzip -cd $1/plain_text.gz | wc -l)
	if test ! "$docs_pt" -eq "$docs_st"; then 
		echo $1/sentences.gz
	else
		mark_valid 03 $1
	fi
}

export -f validate is_marked_valid mark_valid

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate 
done
		
