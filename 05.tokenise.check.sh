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
	
	if [[ "$lang" == "$TARGET_LANG" ]]; then
		local input=sentences
		local output=tokenised
	else
		local input="sentences_${TARGET_LANG}"
		local output="tokenised_${TARGET_LANG}"
	fi

	if is_marked_valid 05-$TARGET_LANG $1 $input.gz $output.gz ; then
		return
	fi


	local docs_tk docs_st
	if test -e $1/$output.gz \
	  && docs_tk=$(gzip -cd $1/$output.gz | wc -l) \
	  && docs_st=$(gzip -cd $1/$input.gz | wc -l) \
	  && test $docs_st -eq $docs_tk; then
		: # Good!
	else
		echo $1/$output.gz
		return
	fi
	
	local lines_tk lines_st
	if lines_tk=$(gzip -cd $1/$output.gz | base64 -d | wc -l) \
	  && lines_st=$(gzip -cd $1/$input.gz | base64 -d | wc -l) \
	  && test $lines_st -eq $lines_tk; then
		: # Good!
	else
		echo $1/$output.gz
		return
	fi

	mark_valid 05-$TARGET_LANG $1
}

export -f validate is_marked_valid mark_valid

for lang in $@; do
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate $lang
done
		
