#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./env/init.sh
. ./config.sh
. ./functions.sh

collection=$1
shift

export SBATCH_ACCOUNT=t2-cs119-gpu
export SBATCH_PARTITION=pascal
export SLURM_TASKS_PER_NODE=1 # No parallelism in generic.slurm plz, they'll have to share the gpu otherwise.
export SBATCH_GRES=gpu:1

for lang in $*; do
	bicleaner_model $lang
	batch_list=`make_batch_list 08 $score $lang scored.gz`
	job_list=`make_job_list $batch_list`
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				-J fix-${lang%~*}-${collection} \
				-a $job_list \
				--time 06:00:00 \
				-e ${SLURM_LOGS}/08.score-%A_%a.err \
				-o ${SLURM_LOGS}/08.score-%A_%a.out \
				${SCRIPTS}/generic.slurm $batch_list \
				${SCRIPTS}/08.score ${collection} ${lang%~*} \
				${COLLECTIONS[$collection]}-shards/${TARGET_LANG}
		fi
	fi
done
