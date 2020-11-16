#!/bin/bash
set -euo pipefail
. config.csd3
. functions.sh
. translate.sh
THREADS=${THREADS:-4}

collection=$1
shift

function validate () {
	set -euo pipefail

	local lang=$1
	shift
	
	local input="sentences"
	local output="sentences_${TARGET_LANG}"

	if is_marked_valid 04-$TARGET_LANG $1 $input.gz $output.gz ; then
		return
	fi

	# Test equal number of documents
	local docs_tk docs_st
	if docs_tk=$(gzip -cd $1/$output.gz | wc -l) \
		&& docs_st=$(gzip -cd $1/$input.gz | wc -l) \
		&& test $docs_st -eq $docs_tk; then
		: # Good
	else
		echo $1/$output.gz
		return
	fi

	# Test equal number of sentences
	local lines_tk lines_st
	if lines_tk=$($DOCENC -d $1/$output.gz | wc -l) \
		&& lines_st=$($DOCENC -d $1/$input.gz | wc -l) \
		&& test $lines_st -eq $lines_tk; then
		: # Good
	else
		echo $1/$output.gz
		return
	fi

	mark_valid 04-$TARGET_LANG $1
}

cleanup () {
	local MNAME="`basename $MODEL`"
        echo "Cleaning up..."
        if [ -s  "${SCRATCH}/${MNAME}" ]; then
                echo "Found file:" "${SCRATCH}/${MNAME}"
        else
                echo "Could not find file:"  "${SCRATCH}/${MNAME}"
        fi
        rm -rf "${SCRATCH}/${MNAME}"
        echo "Clean up done."
        }
export -f validate is_marked_valid mark_valid cleanup

in="sentences"
out="sentences_${TARGET_LANG}"

for lang in $@; do
	# Skip this for English, nothing to translate there
	if [[ "$lang" == "$TARGET_LANG" ]]; then
		continue
	fi
	ls -d $DATA/$collection-shards/$lang/*/* | parallel --line-buffer -j $THREADS validate $lang

	if [ "$?" -eq "0" ] ; then
		eval model_${lang}_${TARGET_LANG}
		cleanup
	fi
done
		
