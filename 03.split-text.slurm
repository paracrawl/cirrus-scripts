#!/bin/sh
#SBATCH -J split
#SBATCH -c 1
#SBATCH --time 8:00:00
#SBATCH -e /home/%u/logs/03.split-%A_%a.err
#SBATCH -o /home/%u/logs/03.split-%A_%a.out

set -eu

module load parallel
module load perl/5.20.0

export SLANG="${1}"
export BATCHES="${2}"
export CMD=${SCRIPTS}/03.split-text
export THREADS=$((${SLURM_CPUS_ON_NODE} / ${TASKS_PER_BATCH}))
echo "Running $THREADS threads per task, ${TASKS_PER_BATCH} tasks"

export TMPDIR=$(mktemp -d --tmpdir=$SCRATCH)

IFS=, read GROUP_START GROUP_END <<< $(get_group_boundaries ${BATCHES} ${SLURM_ARRAY_TASK_ID})

parallel task ::: $(seq $GROUP_START $GROUP_END)
