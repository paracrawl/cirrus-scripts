#!/bin/sh
#SBATCH -J translate
#SBATCH --time 16:00:00
#SBATCH --cpus-per-task=16
#SBATCH -e /home/%u/logs/04.translate-%A_%a.err
#SBATCH -o /home/%u/logs/04.translate-%A_%a.out

## ARGUMENTS: lang batch

#export NMOSI=1 # For Skylake n=16
#export NMOSI=16 # For Knights Landing
export NMOSI=${SLURM_NTASKS:-1}
export MOSES_ARGS="--threads ${SLURM_CPUS_PER_TASK:-16}"

module load parallel
module load perl/5.20.0

export SLANG="${1}"
export BATCHES="${2}"
export CMD=${SCRIPTS}/04.translate.cpu
echo "Running $NMOSI threads per task, ${TASKS_PER_BATCH} tasks"

IFS=, read GROUP_START GROUP_END <<< $(get_group_boundaries ${BATCHES} ${SLURM_ARRAY_TASK_ID})

parallel task ::: $(seq $GROUP_START $GROUP_END)
