#!/bin/sh

## create and submit the batches on csd3 for text splitting

set -euo pipefail

. config.sh
. functions.sh

collection=$1
shift

for lang in $*; do
	# Load in translation model config so we know ARCH
	batch_list=$(make_batch_list 98 $collection $lang doccount.txt)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list \n"
		if confirm; then 
			schedule \
				-J doccount-${lang} \
				-a $job_list \
				 --time 4:00:00 \
				-e ${SLURM_LOGS}/97.doccount-%A_%a.err \
				-o ${SLURM_LOGS}/97.doccount-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/97.doccount
		fi
	fi
done
