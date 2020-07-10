#!/bin/sh
#SBATCH -J align
#SBATCH -N 1
#SBATCH --time 12:00:00
#SBATCH -e /home/%u/logs/06.align-%A_%a.err
#SBATCH -o /home/%u/logs/06.align-%A_%a.out
##SBATCH -A t2-cs119-cpu
##SBATCH -p skylake
##SBATCH --ntasks 1
##SBATCH --cpus-per-task 8
#SBATCH -A t2-cs119-sl4-knl
#SBATCH -p knl

## ARGUMENTS: lang batch

module load parallel
set -euo pipefail

# Clean up all children when we get terminated
trap "exit" INT TERM
trap "kill 0" EXIT

export SLANG="${1}"
export BATCHES="${2}"
export THREADS=$((${SLURM_CPUS_ON_NODE} / ${TASKS_PER_BATCH}))
echo "Running $THREADS per task, ${TASKS_PER_BATCH} tasks"

task() {
  set -euo pipefail
  local BATCH_ID=$1

  # Note: BATCH will contain two paths separated by space. These are intended
  # as two arguments to 06.align.
  BATCH=`head -${BATCH_ID} ${BATCHES} | tail -1`

  echo `date` "Starting whole node job ${BATCH_ID} (${SLURM_ARRAY_TASK_ID}) on ${HOSTNAME}"
  echo "Batch: ${BATCH}"
  /bin/time -f "%E %M" ${SCRIPTS}/06.align ${SLANG} ${BATCH}
  echo `date` "Done whole node job ${BATCH_ID} on ${HOSTNAME}"
}

# While this script is running, also write CPU stats
mpstat 30 > $HOME/logs/06.align-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.stat &
stat_pid=$!

GROUP_END=$(( $TASKS_PER_BATCH * $SLURM_ARRAY_TASK_ID ))
GROUP_START=$(( 1 + $GROUP_END - $TASKS_PER_BATCH))

export -f task
parallel task ::: $(seq $GROUP_START $GROUP_END)

kill ${stat_pid}


