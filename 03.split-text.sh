#!/bin/sh

## create and submit the batches on csd3 for text splitting

set -euo pipefail

. config.sh
. functions.sh

collection=$1
shift

for lang in $*; do
	# Load in translation model config so we know ARCH
	batch_list=$(make_batch_list 03 $collection $lang sentences.gz)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list \n"
		if confirm; then 
			schedule \
				-J split-${lang} \
				-a $job_list \
				--time 4:00:00 \
				-e ${SLURM_LOGS}/03.split-%A_%a.err \
				-o ${SLURM_LOGS}/03.split-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/03.split-text $lang
		fi
	fi
done
