#!/bin/bash
set -euo pipefail

. ./env/init.sh
. ./config.sh
. ./functions.sh

function make_batch_list_all() {
	local collection=$1
	local batch_list=${COLLECTIONS[$collection]}-batches/01
	if [ ! -e $batch_list ]; then
		# This assumes all subdirectories are warc collections. Maybe a bit presumptuous.
		find ${COLLECTIONS[$collection]}-warcs/ -mindepth 1 -maxdepth 1 -type d \
			> $batch_list
	fi
	
	echo $batch_list
}

function make_batch_list_retry() {
	local collection=$1
	local batch_list=${COLLECTIONS[$collection]}-batches/01.$(date '+%Y%m%d%H%M%S')
	cat $(make_batch_list_all $collection) | while read warc_collection; do
		if [ ! -d ${COLLECTIONS[$1]}-text/$(basename $warc_collection) ]; then
			echo $warc_collection;
		fi
	done > $batch_list
	echo $batch_list
}

for collection in $@; do
	batch_list=$(make_batch_list $collection)
	job_list=$(make_job_list $batch_list)
	output_dir="${COLLECTIONS[$collection]}-text/"
	if [ ! -z "$job_list" ]; then
		schedule \
			-J warc2text-${collection} \
			-a $job_list \
			--time 24:00:00 \
			--cpus-per-task 1\
			-e ${SLURM_LOGS}/01.warc2text-%A_%a.err \
			-o ${SLURM_LOGS}/01.warc2text-%A_%a.out \
			${SCRIPTS}/generic.slurm $batch_list \
			${SCRIPTS}/01.warc2text $output_dir
	fi
done
