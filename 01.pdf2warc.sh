#!/bin/bash
set -euo pipefail
. ./env/init.sh
. ./config.sh
. ./functions.sh

function make_batch_list_all() {
	local collection=$1
	local batch_list=${COLLECTIONS[$collection]}-batches/01.pdf2warc
	if [[ ! -d ${COLLECTIONS[$collection]}-batches ]]; then
		mkdir ${COLLECTIONS[$collection]}-batches
	fi

	if $FORCE_INDEX_BATCHES || [[ ! -e $batch_list ]]; then
		# This assumes all subdirectories are warc collections. Maybe a bit presumptuous.
		find -L ${COLLECTIONS[$collection]}-text/ -mindepth 2 -maxdepth 2 -name pdf.warc.gz \
			> $batch_list
	fi
	
	echo $batch_list
}

function make_batch_list_retry() {
	local collection=$1
	local batch_list=${COLLECTIONS[$collection]}-batches/01.pdf2warc.$(date '+%Y%m%d%H%M%S')
	cat $(make_batch_list_all $collection) | while read warc; do
		if [ ! -f ${warc%/*}/pdf-text.warc.gz ]; then
			echo $warc
		fi
	done > $batch_list
	echo $batch_list
}

for collection in $@; do
	batch_list=$(make_batch_list $collection)
	job_list=$(make_job_list $batch_list)
	if [ ! -z "$job_list" ]; then
		prompt "Run $job_list pdf2warc2warc?"
		if confirm; then
			schedule \
				-J pdf2warc-${collection} \
				-a ${job_list}%16 \
				--time 24:00:00 \
				--cpus-per-task 8\
				-e ${SLURM_LOGS}/01.pdf2warc-%A_%a.err \
				-o ${SLURM_LOGS}/01.pdf2warc-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/01.pdf2warc
		fi
	fi
done
