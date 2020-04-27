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
	local lang="$1" batches=($2)

	local output=${batches[0]}/aligned-$(basename ${batches[1]}).gz

	# Test if the file was created
	if [ ! -f $output ]; then
		echo $output
		return
	fi

	# Test if it contains fewer or equal number of lines as the input (as in
	# our current setup we try to associate each sentence with one English at
	# most. Note that we still end up with at most N repetitions as each batch
	# in the English shard can have a match.)
	local lines_aligned lines_foreign
	if lines_aligned=$(gzip -cd $output | wc -l) \
		&& lines_foreign=$(docenc -d ${batches[0]}/tokenised_en.gz | wc -l) \
		&& test $lines_aligned -le $lines_foreign; then
		: # Good
	else
		echo $output
		return
	fi
}

export -f validate

for lang in $*; do
	make_batch_list $collection $lang | parallel --line-buffer -j $THREADS validate $lang
done
