#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./config.csd3
. ./functions.sh

function make_batch_list_all {
	local collection="$1" lang="$2"
	local batch_list="${COLLECTIONS[$collection]}-batches/09.${lang}-${TARGET_LANG}"
	
	if ! test -e $batch_list; then
		find ${COLLECTIONS[$collection]}-cleaning/${TARGET_LANG}-${lang}/ \
			-mindepth 1 \
			-maxdepth 1 \
			-type f \
			-regex ".*/[0-9]+\.raw$" \
			> $batch_list.$$ \
			&& mv $batch_list.$$ $batch_list
	fi

	echo $batch_list
}

function make_batch_list_retry {
	local collection="$1" lang="$2"
	local batch_list="${COLLECTIONS[$collection]}-batches/09.${lang}-${TARGET_LANG}".$(date '+%Y%m%d%H%M%S')

	cat `make_batch_list_all "$@"` | while read batch; do
		batch_num=$(basename $batch | sed -n 's/^\([0-9]\{1,\}\)\..*$/\1/p')
		
		if [[ ! -e $(dirname $batch)/${batch_num}.classified.gz ]] || [[ ! -e $(dirname $batch)/${batch_num}.filtered${BICLEANER_THRESHOLD/./}.gz ]]; then
			echo $batch >&2
			echo $batch
		fi
	done | shuf > $batch_list

	echo $batch_list
}

collection=$1
shift

for lang in $*; do
	# Load some language-spefic bicleaner & bifixer configurations (because they normally don't
	# deal with zh or ko correctly. Read: time for the duct tape!
	bicleaner_model $lang

	batch_list=`make_batch_list $collection $lang`
	job_list=`make_job_list $batch_list`
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				-J clean-${lang} \
				-a $job_list \
				--time 24:00:00 \
				--cpus-per-task 2 \
				-e ${SLURM_LOGS}/09.clean-%A_%a.err \
				-o ${SLURM_LOGS}/09.clean-%A_%a.out \
				generic.slurm $batch_list 09.clean ${collection} ${lang}
		fi
	fi
done
