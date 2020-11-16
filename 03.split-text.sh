#!/bin/sh

## create and submit the batches on csd3 for text splitting

set -euo pipefail

. config.csd3
. functions.sh
export -f get_group_boundaries task
LOGS=/home/cs-sifa1/split_logs.log
collection=$1
shift

for lang in $*; do
	echo "Processing language: $lang"
	# Load in translation model config so we know ARCH
	batch_list=$(make_batch_list 03 $collection $lang sentences.gz)
	job_list=$(make_job_list $batch_list)
	echo "Batch List:" >> $LOGS
	echo $batch_list >> $LOGS
	echo "Job List:" >> $LOGS
	echo $job_list >> $LOGS
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list \n"
		if confirm; then 
			schedule --nice=300 -J split-${lang} -a $job_list 03.split-text.slurm $lang $batch_list
		fi
	fi
done
