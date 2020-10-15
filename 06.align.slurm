#!/bin/sh
#SBATCH -J align
#SBATCH --time 12:00:00
#SBATCH --cpus-per-task=4
##SBATCH --mem-per-cpu=8192
#SBATCH -e /home/%u/logs/06.align-%A_%a.err
#SBATCH -o /home/%u/logs/06.align-%A_%a.out

## ARGUMENTS: lang batch

module load parallel
set -euo pipefail

export SLANG="${1}"
export BATCHES="${2}"
export TMPDIR=${SCRATCH}
export CMD=${SCRIPTS}/06.align

IFS=, read GROUP_START GROUP_END <<< $(get_group_boundaries ${BATCHES} ${SLURM_ARRAY_TASK_ID})

# If there are fewer tasks than we planned for, account for using CPUS for all of em
if [ $GROUP_END -lt $(( $GROUP_START + $TASKS_PER_BATCH )) ]; then
	TASKS_PER_BATCH=$(( $GROUP_END - $GROUP_START + 1 ))
fi

#export THREADS=$((${SLURM_CPUS_ON_NODE} / ${TASKS_PER_BATCH}))
#export THREADS=$(( $THREADS > 0 ? $THREADS : 1 ))
export THREADS=${SLURM_CPUS_PER_TASK}
echo "Running $THREADS threads per task, ${TASKS_PER_BATCH} tasks (${SLURM_TASKS_PER_NODE} at a time)"

# While this script is running, also write CPU stats
#mpstat 30 > $HOME/logs/06.align-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.stat &
#stat_pid=$!

#trap "exit" INT TERM
#trap "kill $stat_pid" EXIT

parallel -j${SLURM_TASKS_PER_NODE} --line-buffer task ::: $(seq $GROUP_START $GROUP_END)

#kill ${stat_pid}
