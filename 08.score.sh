#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./env/init.sh
. ./config.sh
. ./functions.sh

collection=$1
shift

if [ "$IS_LUMI" = true ]; then
	export SBATCH_PARTITION="small-g"
	export SLURM_TASKS_PER_NODE=1 # No parallelism in generic.slurm plz, they'll have to share the gpu otherwise.
	export SBATCH_GPUS_PER_TASK=1
	unset SBATCH_MEM_PER_CPU # If we are setting this for small partition, we don't need it for gpu jobs
else
	export SBATCH_ACCOUNT=t2-cs119-gpu
	export SBATCH_PARTITION=pascal
	export SLURM_TASKS_PER_NODE=1 # No parallelism in generic.slurm plz, they'll have to share the gpu otherwise.
	export SBATCH_GRES=gpu:1
fi

for lang in $*; do
	bicleaner_ai_model $lang
	batch_list=`make_batch_list 08 $collection $lang scored.gz fixed.gz hardruled.gz`
	job_list=`make_job_list $batch_list`
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				-J score-${lang%~*}-${collection} \
				-a $job_list \
				--time 24:00:00 \
				-e ${SLURM_LOGS}/08.score-%A_%a.err \
				-o ${SLURM_LOGS}/08.score-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/08.score ${collection} ${lang%~*} \
				${COLLECTIONS[$collection]}-shards/${TARGET_LANG}
		fi
	fi
done
