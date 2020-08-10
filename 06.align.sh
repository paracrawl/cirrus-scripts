#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./config.csd3
. ${SCRIPTS}/functions.sh
export -f get_group_boundaries task

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

collection=$1
shift

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
