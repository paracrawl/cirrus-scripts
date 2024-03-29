#!/bin/bash
set -euo pipefail
. ./env/init.sh
. ./config.sh
. ./functions.sh

function make_batch_list_all() {
	local collection=$1
	local batch_list=${COLLECTIONS[$collection]}-batches/01
	if [[ ! -d ${COLLECTIONS[$collection]}-batches ]]; then
		mkdir ${COLLECTIONS[$collection]}-batches
	fi

	if $FORCE_INDEX_BATCHES || [[ ! -e $batch_list ]]; then
		# This assumes all subdirectories are warc collections. Maybe a bit presumptuous.
		find -L ${COLLECTIONS[$collection]}-warcs/ -mindepth 1 -maxdepth 1 -type d \
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
	case $collection in
		hieu|philipp)
			export WARC2TEXT_OPTIONS=--encode-urls
			;;
		*)
			export WARC2TEXT_OPTIONS=
			;;
	esac
	
	batch_list=$(make_batch_list $collection)
	job_list=$(make_job_list $batch_list)
	output_dir="${COLLECTIONS[$collection]}-text/"
	if [ ! -z "$job_list" ]; then
		prompt "Run $job_list warc2text?"
		if confirm; then
			schedule \
				-J warc2text-${collection} \
				-a ${job_list}%32 \
				--time 24:00:00 \
				--cpus-per-task 1\
				-e ${SLURM_LOGS}/01.warc2text-%A_%a.err \
				-o ${SLURM_LOGS}/01.warc2text-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/01.warc2text $output_dir
		fi
	fi
done
