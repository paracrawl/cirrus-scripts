#!/bin/bash
set -euo pipefail

export SLURM_TASKS_PER_NODE=1
export SLURM_CPUS_ON_NODE=1
export SLURM_ARRAY_TASK_ID=1

while [[ "$1" = -* ]]; do
	if [[ "$1" == "--cpus-per-task" ]]; then
		export SLURM_CPUS_PER_TASK=$2
		export SLURM_CPUS_ON_NODE=$2
	elif [[ "$1" == "--ntasks" ]]; then
		export SLURM_TASKS_PER_NODE=$2
	fi

	shift 2
done

exec "$@"
