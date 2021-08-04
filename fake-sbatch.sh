#!/bin/bash
#set -euo pipefail

export SLURM_TASKS_PER_NODE=1
export SLURM_CPUS_ON_NODE=1

ARRAY_INDEXES="1-1"

echo "$@" >&2
while [[ $1 = -* ]]; do
	if [[ $1 == "--cpus-per-task" ]]; then
		export SLURM_CPUS_PER_TASK=$2
		export SLURM_CPUS_ON_NODE=$2
		shift 2
	elif [[ $1 == "--ntasks" ]]; then
		export SLURM_TASKS_PER_NODE=$2
		shift 2
	elif [[ $1 =~ --(parsable|verbose|exclusive) ]]; then
		shift 1
	elif [[ $1 == "--array" ]] || [[ $1 == "-a" ]]; then
		ARRAY_INDEXES="$2"
		shift 2
	else
		shift 2
	fi
done

parse-array-sequence() {
	if [[ $# == 2 ]]; then
		seq $1 ${2%\%*} # remove any %32 that may have been specified
	else
		echo $1
	fi
}

parse-array-indexes() {
	while IFS=, read -a sequences; do
		for sequence in ${sequences[@]}; do
			parse-array-sequence $(tr '-' ' ' <<< $sequence)
		done
	done <<< $@
}

export SLURM_ARRAY_JOB_ID=1

# The JOB_ID that sbatch would normally print to stdout
echo "${SLURM_ARRAY_JOB_ID}"

for TASK_ID in $(parse-array-indexes $ARRAY_INDEXES); do
	export SLURM_ARRAY_TASK_ID=$TASK_ID
	"$@"
done

