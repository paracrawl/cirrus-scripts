#!/bin/bash
set -euo pipefail
. ./env/init.sh
. ./config.sh
. ./functions.sh

function make_batch_list_all() {
	local collection=$1
	local language=$2
	local batch_list=${COLLECTIONS[$collection]}-batches/00.${language}~dedup
	if [ ! -e $batch_list ]; then
		for shard in $(seq 0 255); do
			printf "%s" ${COLLECTIONS[$collection]}-shards/${language}~dedup/${shard}
			local shard_dir=${COLLECTIONS[$collection]}-shards/${language}/${shard}
			if [[ -d "$shard_dir" ]]; then
				printf "\t%s" $shard_dir
			fi
			printf "\n"
		done > $batch_list
	fi
	
	echo $batch_list
}

function make_batch_list_retry() {
	local collection=$1
	local language=$2
	local batch_list=${COLLECTIONS[$collection]}-batches/00.${language}.$(date '+%Y%m%d%H%M%S')
	cat $(make_batch_list_all $collection $language) | while read line; do
		if [ ! -d "${line%%$'\t'*}" ]; then
			echo "$line"
		fi
	done > $batch_list
	echo $batch_list
}

collection=$1
shift

for language in $@; do
	# batch list is in format: <shard to generate> \t [shards to read from \t ...]
	batch_list=$(make_batch_list $collection $language)
	job_list=$(make_job_list $batch_list)
	if [ ! -z "$job_list" ]; then
		prompt "$batch_list: Run $job_list merge-dedupe?"
		if confirm; then
			schedule \
				-J dedupe-${language}-${collection} \
				-a $job_list \
				--time 24:00:00 \
				--cpus-per-task 4 \
				-e ${SLURM_LOGS}/00.dedupe-%A_%a.err \
				-o ${SLURM_LOGS}/01.dedupe-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/00.merge-dedupe $language
		fi
	fi
done
