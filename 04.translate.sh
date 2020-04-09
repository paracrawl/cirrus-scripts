#!/bin/bash

## create and submit the batches on csd3 for translation
set -euo pipefail

. ./config.csd3
. ${SCRIPTS}/functions

collection=$1
shift

for lang in $*; do
	batch_list=$(make_batch_list 04 $collection $lang)
	job_list=$(make_job_list $batch_list sentences_en.gz)
	if [ ! -z $job_list ]; then
		echo Scheduling $job_list
		confirm
		sbatch --nice=400 -J translate-${lang} -a $job_list 04.translate.slurm $lang $batch_list
	fi
done
