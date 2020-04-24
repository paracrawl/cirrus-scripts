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
	
	if [[ "$lang" == "en" ]]; then
		local input=sentences
		local output=tokenised
	else
		local input=sentences_en
		local output=tokenised_en
	fi

	if is_marked_valid 05 $1 $input.gz $output.gz; then
		return
	fi

	local docs_tk=$(gzip -cd $1/$output.gz | wc -l)
	local docs_st=$(gzip -cd $1/$input.gz | wc -l)
	if test ! $docs_st -eq $docs_tk; then
		echo $1/$output.gz
		return
	fi

	local lines_tk=$(docenc -d $1/$output.gz | wc -l)
	local lines_st=$(docenc -d $1/$input.gz | wc -l)
	if test ! $lines_st -eq $lines_tk; then
		echo $1/$output.gz
		return
	fi

	mark_valid 05 $1
}

export -f validate is_marked_valid mark_valid

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate $lang
done
		
