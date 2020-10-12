#!/bin/sh
#SBATCH -J translate
#SBATCH --time 36:00:00
##SBATCH --cpus-per-task=8
#SBATCH --exclusive
#SBATCH -e /home/%u/logs/04.translate-%A_%a.err
#SBATCH -o /home/%u/logs/04.translate-%A_%a.out

## ARGUMENTS: lang batch

module load parallel
module load perl/5.20.0

source $SCRIPTS/04.translate.cpu
export -f translate_task

export SLANG="${1}"
export BATCHES="${2}"
export CMD=translate_task

IFS=, read GROUP_START GROUP_END <<< $(get_group_boundaries ${BATCHES} ${SLURM_ARRAY_TASK_ID})
echo "GROUP: $GROUP_START-$GROUP_END"

if [ "$GROUP_END" -lt $(( $GROUP_START + $TASKS_PER_BATCH )) ]; then
	TASKS_PER_BATCH=$(( $GROUP_END - $GROUP_START + 1 ))
fi

export THREADS=${SLURM_CPUS_PER_TASK:-$(($SLURM_CPUS_ON_NODE / $SLURM_TASKS_PER_NODE))}
export MOSES_ARGS="--threads $THREADS"
export NMOSI=$(( $SLURM_CPUS_ON_NODE / $SLURM_TASKS_PER_NODE / $THREADS ))

echo "Running $NMOSI processes, each with $THREADS threads, for ${TASKS_PER_BATCH} tasks (of which $SLURM_TASKS_PER_NODE in parallel)"

translate_setup $SLANG

parallel -j$SLURM_TASKS_PER_NODE --line-buffer task ::: $(seq $GROUP_START $GROUP_END)
