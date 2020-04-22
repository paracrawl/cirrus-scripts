#!/bin/sh

## create and submit the batches on csd3 for translation
set -euo pipefail

. ./config.csd3
. ${SCRIPTS}/functions.sh

collection=$1
shift

for lang in $*; do
	if [ "$lang" = en ]; then
		output=tokenised.gz
	else
		output=tokenised_en.gz
	fi

	batch_list=$(make_batch_list 05 $collection $lang)
	job_list=$(make_job_list $batch_list $output)
	if [ ! -z $job_list ]; then
		echo Scheduling $job_list
		if confirm; then 
			sbatch --nice=500 -J tok-${lang} -a $job_list ${SCRIPTS}/05.tokenise.slurm $lang $batch_list
		fi
	fi
done
