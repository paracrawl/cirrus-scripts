#!/bin/bash
set -euo pipefail
. ./env/init.sh
. ./config.sh
. ./functions.sh

name=$(basename $1 .sh)
batch_list=$(mktemp --tmpdir=$HOME .batch-listXXXXXX)
cat > $batch_list
job_list=$(make_job_list $batch_list)
if [ ! -z "$job_list" ]; then
	schedule \
		-J $name \
		-a $job_list \
		--time ${TIME:-12:00:00} \
		--cpus-per-task ${CPUS:-1} \
		-e ${SLURM_LOGS}/$name-%A_%a.err \
		-o ${SLURM_LOGS}/$name-%A_%a.out \
		${SCRIPTS}/generic.slurm $batch_list \
		$@
fi
