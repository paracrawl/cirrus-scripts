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
	batch_list=$(make_batch_list 03 $collection $lang sentences.gz)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list \n"
		if confirm; then 
			schedule -J split-${lang} -a $job_list 03.split-text.slurm $lang $batch_list
		fi
	fi
done
