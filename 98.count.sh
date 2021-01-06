#!/bin/sh

## create and submit the batches on csd3 for text splitting

set -euo pipefail

. config.csd3
. functions.sh
export -f get_group_boundaries task

collection=$1
shift

for lang in $*; do
	# Load in translation model config so we know ARCH
	batch_list=$(make_batch_list 98 $collection $lang linecount.txt)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list \n"
		if confirm; then 
			schedule \
				-J count-${lang} \
				-a $job_list \
				 --time 4:00:00 \
				-e ${SLURM_LOGS}/98.count-%A_%a.err \
				-o ${SLURM_LOGS}/98.count-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/98.count
		fi
	fi
done
