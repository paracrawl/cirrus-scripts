#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./config.csd3
. ./functions.sh

function make_batch_list_all {
	local collection="$1" lang="$2"
	local batch_list="${DATA}/${collection}-batches/09.${lang}-${TARGET_LANG}"
	
	if ! test -e $batch_list; then
		find ${DATA}/cleaning/${TARGET_LANG}-${lang}/ \
			-mindepth 1 -maxdepth 1 -type f -regex ".*/raw-${collection}\.${TARGET_LANG}-${lang}\.[0-9]+$" \
			> $batch_list
	fi

	echo $batch_list
}

function make_batch_list_retry {
	local collection="$1" lang="$2"
	local batch_list="${DATA}/${collection}-batches/09.${lang}-${TARGET_LANG}".$(date '+%Y%m%d%H%M%S')

	cat `make_batch_list_all "$@"` | while read batch; do
		batch_num=$(echo $batch | sed -n 's/.*\([0-9]\{1,\}\)$/\1/p')
		output_prefix=$(dirname $batch)/${TARGET_LANG}-${lang}.${collection}.${batch_num}

		if [[ ! -e ${output_prefix}.classified.gz ]] || [[ ! -e ${output_prefix}/filtered${BICLEAER_THRESHOLD/./}.gz ]]; then
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
	if [[ $lang == 'ko' ]] || [[ $lang == 'zh' ]]; then
		export BIFIXER_PARAMS="\
			$BIFIXER_PARAMS \
			--ignore_characters \
			--ignore_long \
			--ignore_orthography \
			--ignore_segmentation"
		export BICLEANER="python ${HOME}/rds/rds-t2-cs119/cwang/bicleaner/codes/bicleaner/bicleaner/bicleaner_classifier_full.py"
		export BICLEANER_THRESHOLD=0.4
	fi

	if [[ $lang == 'ko' ]]; then
		export BICLEANER_MODEL="${HOME}/rds/rds-t2-cs119/cwang/bicleaner/model/korean/${TARGET_LANG}-${lang}.yaml"
	elif [[ $lang == 'zh' ]]; then
		export BICLEANER_MODEL="${HOME}/rds/rds-t2-cs119/cwang/bicleaner/model/chinese/${TARGET_LANG}-${lang}.yaml"
	else
		# Default path: here instead of in config.csd3 because path depends on $lang and the exceptions
		# above don't follow this pattern very well, which is why it's not in the 09.clean code itself.
		export BICLEANER_MODEL=${BICLEANER_MODELS}/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.yaml
	fi

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
