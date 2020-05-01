#!/bin/bash
set -euo pipefail
. config.csd3
. functions.sh

THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	set -euo pipefail
	
	local lang=$1
	shift

	set -euo pipefail
	
	if [[ "$lang" == "en" ]]; then
		local input=sentences
		local output=tokenised
	else
		local input=sentences_en
		local output=tokenised_en
	fi

	if is_marked_valid 05 $1 $input.gz $output.gz ; then
		return
	fi

	local docs_tk docs_st
	if docs_tk=$(gzip -cd $1/$output.gz | wc -l) \
	  && docs_st=$(gzip -cd $1/$input.gz | wc -l) \
	  && test $docs_st -eq $docs_tk; then
		: # Good!
	else
		echo $1/$output.gz
		return
	fi
	
	local lines_tk lines_st
	if lines_tk=$(docenc -d $1/$output.gz | wc -l) \
	  && lines_st=$(docenc -d $1/$input.gz | wc -l) \
	  && test $lines_st -eq $lines_tk; then
		: # Good!
	else
		echo $1/$output.gz
		return
	fi

	mark_valid 05 $1
}

export -f validate is_marked_valid mark_valid

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate $lang
done
		
