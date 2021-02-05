#!/bin/bash
set -euo pipefail
. ./env/init.sh
. ./config.sh
. ./functions.sh

# Note: tasks-per-batch here determines how many parts the sharding is split into
export BATCHES_PER_TASK=128
export TASKS_PER_BATCH=1 # more than 1 is not supported by 02.giashard

function make_batch_list() {
	local collection=$1
	local language=$2
	local batch_list=${COLLECTIONS[$collection]}-batches/02.${language}
	if [ ! -e $batch_list ]; then
		find ${COLLECTIONS[$collection]}-text/ -mindepth 2 -maxdepth 2 -type d -name $language > $batch_list
	fi
	echo $batch_list
}

collection=$1
shift

for language in $@; do
	batch_list=$(make_batch_list $collection $language)
	output_dir="${COLLECTIONS[$collection]}-shards/"
	job_list=$(TASKS_PER_BATCH=$BATCHES_PER_TASK make_job_list $batch_list)

	if ! $RETRY && [ -d "$output_dir/${language}" ]; then
		echo Skipping $language
		continue
	fi
	
	if [ ! -z "$job_list" ]; then
		prompt "Run $job_list giashard for ${collection}/${language}?\n"
		if confirm; then
			shard_job_id=$(schedule \
				-J shard-${language}-${collection} \
				-a $job_list \
				--time 24:00:00 \
				--cpus-per-task 1\
				-e ${SLURM_LOGS}/02.shard-${language}-%A_%a.err \
				-o ${SLURM_LOGS}/02.shard-${language}-%A_%a.out \
				${SCRIPTS}/02.giashard $batch_list $language $output_dir)
			echo $shard_job_id
			merge_job_id=$(schedule \
				-J merge-${language}-${collection} \
				--dependency afterok:$shard_job_id \
				-a 1-16 \
				--time 12:00:00 \
				--cpus-per-task 4 \
				-e ${SLURM_LOGS}/02.merge-${language}-%A_%a.err \
				-o ${SLURM_LOGS}/02.merge-${language}-%A_%a.out \
				${SCRIPTS}/02.giamerge $job_list $language $output_dir)
			echo $merge_job_id
			schedule \
				-J clean-${language}-${collection} \
				--dependency afterok:$merge_job_id \
				--time 12:00:00 \
				--cpus-per-task 1 \
				-e ${SLURM_LOGS}/02.clean-${language}-%A_%a.out \
				-o ${SLURM_LOGS}/02.clean-${language}-%A_%a.out \
				${SCRIPTS}/02.clean $job_list $language $output_dir
		fi
	fi
done
