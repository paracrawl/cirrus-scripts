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
			<(ls -d ${DATA}/${collection}-shards/en/$(basename $shard)/*)
	done
}

function validate {
	set -euo pipefail
	
	local lang="$1" batches=($2)

	local output=${batches[0]}/aligned-$(basename ${batches[1]}).gz

	# Test if the file was created
	if [ ! -f $output ]; then
		echo $output
		return
	fi

	# General note: Testing on url.gz here for speed if possible, as those files
	# are way smaller but should already have the same number of documents as
	# the sentences.gz given check 02.shard.check.sh succeeded.

	# There cannot be more sentences in the output than there were in the input.
	local lines_aligned lines_en
	if lines_aligned=$(gzip -cd $output | wc -l) \
		&& lines_en=$(docenc -d ${batches[0]}/sentences.gz | wc -l) \
		&& test $lines_aligned -le $lines_en; then
		: # Good
	else
		echo $output
		return
	fi

	local docs_lang=$(gzip -cd ${batches[0]}/url.gz | wc -l)
	local docs_en=$(gzip -cd ${batches[1]}/url.gz | wc -l)

	# All indices mentioned in the output should be inside the ranges of the 
	# aligned documents.
	gzip -cd $output | cut -f1-2 | while read index_aligned index_en; do
		if test "$index_aligned" -gt "$docs_lang" 2>/dev/null; then
			echo "Document index $index_aligned is not inside $lang/url.gz ($docs_lang)" >&2
			echo $output
			return
		fi
	
		if test "$index_en" -gt "$docs_en" 2>/dev/null; then
			echo "Document index $index_en is not inside en/url.gz ($docs_en)" >&2
			echo $output
			return
		fi
	done
}

export -f validate

for lang in $*; do
	make_batch_list $collection $lang | parallel --line-buffer -j $THREADS validate $lang
done
