#!/bin/bash

## create and submit the batches on csd3 for translation
set -euo pipefail

. env/init.sh
. config.sh
. functions.sh

collection=$1
shift

for lang in $*; do
	batch_list=$(make_batch_list 05 $collection $lang "tokenised_${TARGET_LANG}.gz" "sentences_${TARGET_LANG}.gz")
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then 
			schedule \
				-J tokenise-${lang%~*}-${collection} \
				-a $job_list \
				--time 12:00:00 \
				-e ${SLURM_LOGS}/05.tokenise-%A_%a.err \
				-o ${SLURM_LOGS}/05.tokenise-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/05.tokenise ${lang%~*}
		fi
	fi
done
