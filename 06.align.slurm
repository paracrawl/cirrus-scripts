#!/bin/sh
#SBATCH -J align
#SBATCH -A t2-cs119-sl4-knl
#SBATCH -p knl
#SBATCH -N 1
#SBATCH --time 2:00:00
#SBATCH -e /home/%u/logs/06.align-%A_%a.err
#SBATCH -o /home/%u/logs/06.align-%A_%a.out

## ARGUMENTS: lang batch

module load parallel
set -euo pipefail

# Clean up all children when we get terminated
trap "exit" INT TERM
trap "kill 0" EXIT

SLANG="${1}"
BATCHES="${2}"

task() {
  local BATCH_ID=$1

  # Note: BATCH will contain two paths separated by space. These are intended
  # as two arguments to 06.align.
  BATCH=`head -${BATCH_ID} ${BATCHES} | tail -1`

  echo `date` "Starting whole node job ${BATCH_ID} on ${HOSTNAME}"
  echo "Batch: ${BATCH}"
  /bin/time -f "%E %M" ${SCRIPTS}/06.align ${SLANG} ${BATCH}
  echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
}

for OFFSET in $(seq 0 $((${TASKS_PER_BATCH}-1))); do
  task $((${TASKS_PER_BATCH}*${SLURM_ARRAY_TASK_ID}+${OFFSET})) &
done

wait

  
