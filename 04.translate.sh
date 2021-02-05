#!/bin/bash

## create and submit the batches on csd3 for translation
set -euo pipefail

. env/init.sh
. config.sh
. functions.sh
. translate.sh

collection=$1
shift

for lang in $*; do
	# Load in translation model config so we know MODEL_ARCH
	eval model_${lang}_${TARGET_LANG} || (echo "No model for ${lang} -> ${TARGET_LANG}" 1>&2 ; exit 255)
	batch_list=$(make_batch_list 04 $collection $lang sentences_${TARGET_LANG}.gz)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				-J translate-${lang} \
				-a $job_list \
				--time 24:00:00 \
				--cpus-per-task 4 \
				-e $SLURM_LOGS/04.translate-${lang}-%A_%a.err \
				-o $SLURM_LOGS/04.translate-${lang}-%A_%a.out \
				$SCRIPTS/generic.slurm $batch_list \
				$SCRIPTS/04.translate $lang
		fi
	fi
done
