#!/bin/sh
#SBATCH -J align
#SBATCH -N 1
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
#SBATCH --time 8:00:00
#SBATCH -e /home/%u/logs/06.align-%A_%a.err
#SBATCH -o /home/%u/logs/06.align-%A_%a.out

## SBATCH -A t2-cs119-sl4-knl
## SBATCH -p knl

## ARGUMENTS: lang batch

module load parallel
set -euo pipefail

# Clean up all children when we get terminated
trap "exit" INT TERM
trap "kill 0" EXIT

SLANG="${1}"
BATCHES="${2}"

CPUS=256 # KNL
CPUS=64 # SKYLAKE

export THREADS=$(($CPUS / ${TASKS_PER_BATCH}))

task() {
  local BATCH_ID=$1

  # Note: BATCH will contain two paths separated by space. These are intended
  # as two arguments to 06.align.
  BATCH=`head -${BATCH_ID} ${BATCHES} | tail -1`

  echo `date` "Starting whole node job ${BATCH_ID} (${SLURM_ARRAY_TASK_ID}) on ${HOSTNAME}"
  echo "Batch: ${BATCH}"
  /bin/time -f "%E %M" ${SCRIPTS}/06.align ${SLANG} ${BATCH}
  echo `date` "Done whole node job ${BATCH_ID} on ${HOSTNAME}"
}

task_pid=()

for OFFSET in $(seq 0 $(( ${TASKS_PER_BATCH} - 1 ))); do
  task $(( ${TASKS_PER_BATCH} * ${SLURM_ARRAY_TASK_ID} + ${OFFSET} )) &
  task_pid+=($!)
done

# While this script is running, also write CPU stats
mpstat 10 > $HOME/logs/06.align-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.stat &
stat_pid=$!

wait ${task_pid[@]}
kill ${stat_pid}

  
