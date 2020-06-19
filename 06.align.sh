#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./config.csd3
. ${SCRIPTS}/functions.sh

TASKS_PER_BATCH=8 # KNL
#TASKS_PER_BATCH=1 # Skylake

function make_batch_list {
	local collection="$1" lang="$2"
	if ! test -e ${DATA}/${collection}-batches/06.${lang}-${TARGET_LANG}; then
		for shard in $(ls -d ${DATA}/${collection}-shards/${lang}/*); do
			join -j2 \
				<(ls -d $shard/*) \
				<(ls -d ${DATA}/${collection}-shards/${TARGET_LANG}/$(basename $shard)/*)
		done > ${DATA}/${collection}-batches/06.${lang}-${TARGET_LANG}
	fi
	echo ${DATA}/${collection}-batches/06.${lang}-${TARGET_LANG}
}

function make_job_list_all {
	local n=$(( $(< "$1" wc -l) / ${TASKS_PER_BATCH} + 1))
	echo 1-${n}
}

function make_job_list_retry {
	local index=0
 	local -a indices=()
	while read SRC_BATCH REF_BATCH; do 
		index=$(($index + 1))
		alignments=$SRC_BATCH/aligned-$(basename $REF_BATCH).gz
		if [[ ! -e $alignments ]]; then
			echo $alignments 1>&2
			indices+=($index)
		fi
	done < $1
	if [ ${#indices[@]} -gt 0 ]; then
		join_by , ${indices[@]}
	fi
}

collection=$1
shift

if $RETRY; then
	TASKS_PER_BATCH=1
fi

export TASKS_PER_BATCH # Used by 06.align.slurm

for lang in $*; do
	batch_list=`make_batch_list $collection $lang`
	job_list=`make_job_list $batch_list`
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				--nice=600 \
				-J align-${lang} \
				-a $job_list \
				${SCRIPTS}/06.align.slurm ${lang} $batch_list
		fi
	fi
done
