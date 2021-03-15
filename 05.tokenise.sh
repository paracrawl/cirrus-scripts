#!/bin/bash

## create and submit the batches on csd3 for translation
set -euo pipefail

. env/init.sh
. config.sh
. functions.sh

collection=$1
shift

for lang in $*; do
	output="tokenised_${TARGET_LANG}.gz"
	batch_list=$(make_batch_list 05 $collection $lang $output)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then 
			schedule \
				-J tokenise-${lang%~*}-${collection} \
				-a $job_list \
				--time 24:00:00 \
				-e ${SLURM_LOGS}/05.tokenise-%A_%a.err \
				-o ${SLURM_LOGS}/05.tokenise-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/05.tokenise ${lang%~*}
		fi
	fi
done
