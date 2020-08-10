#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./config.csd3
. ${SCRIPTS}/functions.sh

TASKS_PER_BATCH=32 # KNL
#TASKS_PER_BATCH=1 # Skylake

function make_batch_list_all {
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

function make_batch_list_retry {
	batch_list=${DATA}/${collection}-batches/06.${lang}-${TARGET_LANG}.$(date '+%Y%m%d%H%M%S')

	cat `make_batch_list_all "$@"` | while read SRC_BATCH REF_BATCH; do
		alignments=$SRC_BATCH/aligned-$(basename $REF_BATCH).gz
		if [[ ! -e $alignments ]]; then
			echo $SRC_BATCH $REF_BATCH
		fi
	done > $batch_list

	echo $batch_list
}

function make_batch_list {
	if $RETRY; then
		make_batch_list_retry $@
	else
		make_batch_list_all $@
	fi
}

function make_job_list_all {
	local n=$(( $(< "$1" wc -l) / ${TASKS_PER_BATCH} + 1))
	echo 1-${n}
}

function make_job_list_retry {
	# The batch list will already be filtered to just do the retry ones so
	# no need to also make an array selection. Just do all of the lines.
	cat $1 1>&2
	make_job_list_all $@
}

collection=$1
shift

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
