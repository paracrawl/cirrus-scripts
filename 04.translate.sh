#!/bin/bash

## create and submit the batches on csd3 for translation
set -euo pipefail

. config.csd3
. functions.sh
. translate.sh

collection=$1
shift

for lang in $*; do
	# Load in translation model config so we know ARCH
	eval model_${lang} || (echo No model for ${lang} 1>&2 ; exit 255)
	batch_list=$(make_batch_list 04 $collection $lang)
	job_list=$(make_job_list $batch_list sentences_en.gz)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list on $ARCH\n"
		if confirm; then
			schedule --nice=400 -J translate-${lang} -a $job_list 04.translate.${ARCH}.slurm $lang $batch_list
		fi
	fi
done
