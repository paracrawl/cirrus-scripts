#!/bin/bash

## create and submit the batches on csd3 for translation
set -euo pipefail

. config.sh
. functions.sh
. translate.sh
export -f get_group_boundaries task

collection=$1
shift

for lang in $*; do
	# Load in translation model config so we know MODEL_ARCH
	eval model_${lang}_${TARGET_LANG} || (echo "No model for ${lang} -> ${TARGET_LANG}" 1>&2 ; exit 255)
	batch_list=$(make_batch_list 04 $collection $lang sentences_${TARGET_LANG}.gz)
	# ${EDITOR:-vim} $batch_list
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list on $MODEL_ARCH\n"
		if confirm; then
			schedule -J translate-${lang} -a $job_list 04.translate.${MODEL_ARCH}.slurm $lang $batch_list
		fi
	fi
done
