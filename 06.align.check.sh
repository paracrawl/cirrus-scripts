#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. config.csd3
. functions.sh

collection=$1
shift

THREADS=${THREADS:-8}

function make_batch_list {
	local collection="$1" lang="$2"
	for shard in $(ls -d ${DATA}/${collection}-shards/${lang}/*); do
		join -j2 \
			<(ls -d $shard/*) \
			<(ls -d ${DATA}/${collection}-shards/${TARGET_LANG}/$(basename $shard)/*)
	done
}

function validate {
	set -euo pipefail
	
	local lang="$1" batches=($2)

	local ref_batch_id=$(basename ${batches[1]})

	local output=${batches[0]}/aligned-${ref_batch_id}.gz

	# Test if the file was created
	if [ ! -f $output ]; then
		echo $output
		return
	fi

	if is_marked_valid 06-$TARGET_LANG-$ref_batch_id ${batches[0]} $output tokenised_${TARGET_LANG}.gz $(realpath ${batches[1]}/tokenised.gz); then
		return
	fi

	# General note: Testing on url.gz here for speed if possible, as those files
	# are way smaller but should already have the same number of documents as
	# the sentences.gz given check 02.shard.check.sh succeeded.

	# There cannot be more sentences in the output than there were in the input.
	local lines_aligned lines_ref
	if lines_aligned=$(gzip -cd $output | wc -l) \
		&& lines_ref=$(gzip -cd ${batches[0]}/sentences.gz | base64 -d | wc -l) \
		&& test $lines_aligned -le $lines_ref; then
		: # Good
	else
		echo $output
		return
	fi

	local docs_src=$(gzip -cd ${batches[0]}/url.gz | wc -l)
	local docs_ref=$(gzip -cd ${batches[1]}/url.gz | wc -l)

	# All indices mentioned in the output should be inside the ranges of the 
	# aligned documents.
	gzip -cd $output | cut -f1-2 | while read index_aligned index_ref; do
		if test "$index_aligned" -gt "$docs_src" 2>/dev/null; then
			echo "Document index $index_aligned is not inside $lang/url.gz ($docs_src)" >&2
			echo $output
			return
		fi
	
		if test "$index_ref" -gt "$docs_ref" 2>/dev/null; then
			echo "Document index $index_ref is not inside ${TARGET_LANG}/url.gz ($docs_ref)" >&2
			echo $output
			return
		fi
	done

	mark_valid 06-$TARGET_LANG-$ref_batch_id ${batches[0]}
}

export -f validate is_marked_valid mark_valid

for lang in $*; do
	make_batch_list $collection $lang | parallel --line-buffer -j $THREADS validate $lang
done
