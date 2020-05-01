#!/bin/bash
set -euo pipefail
. ./config.csd3
. ./functions.sh

THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	set -euo pipefail
	
	if is_marked_valid 03 $1 plain_text.gz sentences.gz ; then
		return 0
	fi

	local docs_st docs_pt
	if docs_st=$(gzip -cd $1/sentences.gz | wc -l) \
		&& docs_pt=$(gzip -cd $1/plain_text.gz | wc -l) \
		&& test "$docs_pt" -eq "$docs_st"; then
		: # Good
	else
		echo $1/sentences.gz
		return
	fi
	
	mark_valid 03 $1
}

export -f validate is_marked_valid mark_valid

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate 
done
		
