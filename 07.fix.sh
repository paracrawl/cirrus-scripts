#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail
shopt -s extglob

. ./env/init.sh
. ./config.sh
. ./functions.sh

collection=$1
shift

for lang in $*; do
	# Load some language-spefic bicleaner & bifixer configurations (because they normally don't
	# deal with zh or ko correctly. Read: time for the duct tape!
	bicleaner_ai_model $lang
	batch_list=`make_batch_list 07 $collection $lang fixed.gz "aligned-+([0-9]*).gz"`
	job_list=`make_job_list $batch_list`
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				-J fix-${lang%~*}-${collection} \
				--time 12:00:00 \
				--cpus-per-task 72 `#because more memory` \
				-a $job_list \
				-e ${SLURM_LOGS}/07.fix-%A_%a.err \
				-o ${SLURM_LOGS}/07.fix-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/07.fix ${collection} ${lang%~*} \
				${COLLECTIONS[$collection]}-shards/${TARGET_LANG}
		fi
	fi
done
