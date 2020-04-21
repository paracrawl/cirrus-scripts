#!/bin/sh

## create and submit the batches on csd3 for text splitting

set -euo pipefail

. ./config.csd3
. ${SCRIPTS}/functions.sh

collection=$1
shift

for lang in $*; do
	# Load in translation model config so we know ARCH
	batch_list=$(make_batch_list 03 $collection $lang)
	job_list=$(make_job_list $batch_list sentences.gz)
	if [ ! -z $job_list ]; then
		echo Scheduling $job_list
		if confirm; then 
			sbatch --nice=300 -J split-${lang} -a $job_list 03.split-text.slurm $lang $batch_list
		fi
	fi
done
