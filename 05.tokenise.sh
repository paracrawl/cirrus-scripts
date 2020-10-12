#!/bin/sh

## create and submit the batches on csd3 for translation
set -euo pipefail

. config.csd3
. functions.sh
export -f get_group_boundaries task

collection=$1
shift

for lang in $*; do
	if [ "$lang" = "$TARGET_LANG" ]; then
		output="tokenised.gz"
	else
		output="tokenised_${TARGET_LANG}.gz"
	fi

	batch_list=$(make_batch_list 05 $collection $lang $output)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then 
			schedule -J tok-${lang} -a $job_list ${SCRIPTS}/05.tokenise.slurm $lang $batch_list
		fi
	fi
done
