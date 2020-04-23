#!/bin/bash
set -euo pipefail
. config.csd3
. functions.sh

THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	local lang=$1
	shift
	
	local input=sentences
	local output=sentences_en

	if is_marked_valid 04 $1 $input.gz $output.gz ; then
		return
	fi
	
	# Test equal number of documents
	local docs_st=$(gzip -cd $1/$input.gz | wc -l)
	local docs_tk=$(gzip -cd $1/$output.gz | wc -l)
	if test ! $docs_st -eq $docs_tk; then
		echo $1/$output.gz
		return
	fi

	# Test equal number of sentences
	local lines_st=$($DOCENC -d $1/$input.gz | wc -l)
	local lines_tk=$($DOCENC -d $1/$output.gz | wc -l)
	if test ! $lines_st -eq $lines_tk; then
		echo $1/$output.gz
		return
	fi

	mark_valid 04 $1
}

export -f validate is_marked_valid mark_valid

for lang in $@; do
	# Skip this for English, nothing to translate there
	if [[ "$lang" == "en" ]]; then
		continue
	fi

	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate $lang
done
		
