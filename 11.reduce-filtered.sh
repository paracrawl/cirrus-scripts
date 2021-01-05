#!/bin/bash
set -euo pipefail

. ./config.sh
. ./functions.sh

# Makes a batch list (a list of all .classified.gz files for a single collection/language pair)
function make_batch_list {
	local lang=$1
	local collection=$2
	local batch_list=${COLLECTIONS[$collection]}-batches/11.${lang}-${TARGET_LANG}

	if ! test -e $batch_list; then
		find ${COLLECTIONS[$collection]}-cleaning/${TARGET_LANG}-${lang}/ \
			-mindepth 1 \
			-maxdepth 1 \
			-type f \
			-regex ".*/[0-9]+\.filtered${BICLEANER_THRESHOLD/./}\.gz$" \
			> $batch_list.$$ \
			&& mv $batch_list.$$ $batch_list
	fi

	echo $batch_list
}

lang=$1
shift

collections=$@
collection_hash=$(printf "%s\n" $collections | sort | join_by -)

# Load the bicleaner model for this language as we need the $BICLEANER_THRESHOLD
bicleaner_model $lang

declare -a batch_lists
batch_count=0

for collection in $collections; do
	batch_list=$(make_batch_list $lang $collection)
	batch_count=$(( $batch_count + $(cat $batch_list | wc -l) ))
	batch_lists+=( $batch_list )
done

output_file="${DATA}/cleaning/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.${collection_hash}.filtered${BICLEANER_THRESHOLD/./}.gz"

if [ ! -f $output_file ]; then
	prompt "Scheduling 1-1 for combining $batch_count batches across ${#batch_lists[@]} collections\n"
	if confirm; then
		schedule \
			-J reduce-filtered-${lang} \
			--time 36:00:00 \
			--exclusive \
			-e ${SLURM_LOGS}/11.reduce-filtered-%A.err \
			-o ${SLURM_LOGS}/11.reduce-filtered-%A.out \
			11.reduce-filtered ${output_file} ${batch_lists[@]}
	fi
fi
