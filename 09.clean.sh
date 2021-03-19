#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./env/init.sh
. ./config.sh
. ./functions.sh

collection=$1
shift

for lang in $*; do
	# Load some language-spefic bicleaner & bifixer configurations (because they normally don't
	# deal with zh or ko correctly. Read: time for the duct tape!
	bicleaner_model $lang
	output="filtered${BICLEANER_THRESHOLD/./}.gz"
	batch_list=`make_batch_list 09 $collection $lang $output`
	job_list=`make_job_list $batch_list`
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				-J clean-${lang%~*}-${collection} \
				-a $job_list \
				--time 24:00:00 \
				--cpus-per-task 4 `#because more memory` \
				-e ${SLURM_LOGS}/09.clean-%A_%a.err \
				-o ${SLURM_LOGS}/09.clean-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/09.clean ${collection} ${lang%~*} \
				${COLLECTIONS[$collection]}-shards/${TARGET_LANG}
		fi
	fi
done
