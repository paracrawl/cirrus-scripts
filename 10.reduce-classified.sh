#!/bin/bash
set -euo pipefail

. ./config.csd3
. ./functions.sh

function make_batch_list {
	echo "make_batch_list $@" >&2
	local collection=$1 lang=$2
	local batch_list=${COLLECTIONS[$collection]}-batches/10.${lang}-${TARGET_LANG}

	if ! test -e $batch_list; then
		find ${COLLECTIONS[$collection]}-cleaning/${TARGET_LANG}-${lang}/ \
			-mindepth 1 \
			-maxdepth 1 \
			-type f \
			-regex ".*/${TARGET_LANG}-${lang}\.${collection}\.[0-9]+\.classified.gz$" \
			> $batch_list
	fi

	echo $batch_list
}

lang=$1
shift

collections=$@
collection_hash=$(printf "%s\n" $collections | sort | join_by -)

declare -a batch_lists
batch_count=0

for collection in $collections; do
	batch_list=$(make_batch_list $collection $lang)
	batch_count=$(( $batch_count + $(cat $batch_list | wc -l) ))
	batch_lists+=( $batch_list )
done

output_file="${DATA}/cleaning/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.${collection_hash}.classified.gz"

if [ ! -f $output_file ]; then
	prompt "Scheduling 1-1 for combining $batch_count batches across ${#batch_lists[@]} collections\n"
	if confirm; then
		schedule \
			-J reduce-classified-${lang} \
			--time 24:00:00 \
			--cpus-per-task 1 \
			-e ${SLURM_LOGS}/10.reduce-classified-%A.err \
			-o ${SLURM_LOGS}/10.reduce-classified-%A.out \
			10.reduce-classified ${output_file} ${batch_lists[@]}
	fi
fi
