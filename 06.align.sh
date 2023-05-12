#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./env/init.sh
. ./config.sh
. ./functions.sh

function list_numeric_dirs {
	find "$@" -mindepth 1 -maxdepth 1 -type d -regex '.*/[0-9]*'
}

function make_batch_list_all {
	local collection="$1" lang="$2"
	if $FORCE_INDEX_BATCHES || ! test -e ${COLLECTIONS[$collection]}-batches/06.${lang}-${TARGET_LANG}; then
		for shard in $(list_numeric_dirs ${COLLECTIONS[$collection]}-shards/${lang}/); do
			join -t$'\t' -j2 -o 1.1,2.1 \
				<(list_numeric_dirs $shard) \
				<(list_numeric_dirs ${COLLECTIONS[$collection]}-shards/${TARGET_LANG}/$(basename $shard))
		done > ${COLLECTIONS[$collection]}-batches/06.${lang}-${TARGET_LANG}
	fi
	echo ${COLLECTIONS[$collection]}-batches/06.${lang}-${TARGET_LANG}
}

function make_batch_list_retry {
	batch_list=${COLLECTIONS[$collection]}-batches/06.${lang}-${TARGET_LANG}.$(date '+%Y%m%d%H%M%S')

	cat `make_batch_list_all "$@"` | while read SRC_BATCH REF_BATCH; do
		alignments=$SRC_BATCH/aligned-$(basename $REF_BATCH).gz
		# either if the alignments doesn't exist, or the tokenised_en.gz file is newer than aligned-n.gz
		if [[ ! -e $alignments ]] || [[ $SRC_BATCH/tokenised_${TARGET_LANG%~*}.gz -nt $alignments ]]; then
			echo $alignments 1>&2
			printf '%s\t%s\n' "$SRC_BATCH" "$REF_BATCH"
		fi
	done | shuf > $batch_list

	echo $batch_list
}

declare -a OPTIONS=(
	--time 12:00:00
	--cpus-per-task 4
	-e ${SLURM_LOGS}/06.align-%A_%a.err
	-o ${SLURM_LOGS}/06.align-%A_%a.out
)

collection=$1
shift

for lang in $*; do
	batch_list=`make_batch_list $collection $lang`
	job_list=`make_job_list $batch_list`
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				-J align-${lang%~*}-${collection} \
				-a $job_list \
				${OPTIONS[@]} \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/06.align ${lang%~*}
		fi
	fi
done
