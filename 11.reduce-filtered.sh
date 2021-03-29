#!/bin/bash
set -euo pipefail

. ./env/init.sh
. ./config.sh
. ./functions.sh

lang=$1
shift

collections=$@
collection_hash=$(printf "%s\n" $collections | sort | join_by -)

# Load the bicleaner model for this language as we need the $BICLEANER_THRESHOLD
bicleaner_model $lang

declare -a batch_lists
batch_count=0

for collection in $collections; do
	batch_list=$(make_batch_list 11 $collection $lang)
	batch_count=$(( $batch_count + $(cat $batch_list | wc -l) ))
	batch_lists+=( $batch_list )
done

output_file="${DATA_CLEANING}/${TARGET_LANG}-${lang}/${TARGET_LANG%~*}-${lang%~*}.${collection_hash}.filtered${BICLEANER_THRESHOLD/./}.gz"

if [ ! -f $output_file ] || ! $RETRY; then
	prompt "Scheduling 1-1 for combining $batch_count batches across ${#batch_lists[@]} collections\n"
	if confirm; then
		schedule \
			-J reduce-filtered-${lang} \
			--time 36:00:00 \
			--exclusive \
			-e ${SLURM_LOGS}/11.reduce-filtered-%A.err \
			-o ${SLURM_LOGS}/11.reduce-filtered-%A.out \
			${SCRIPTS}/11.reduce-filtered ${output_file} ${batch_lists[@]}
	fi
fi
