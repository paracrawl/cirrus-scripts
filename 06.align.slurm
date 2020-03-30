#!/bin/sh
#SBATCH -J align
#SBATCH -A t2-cs119-sl4-knl
#SBATCH -p knl
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --time 1:00:00
#SBATCH -e /home/%u/logs/06.align-%A_%a.err
#SBATCH -o /home/%u/logs/06.align-%A_%a.out

## ARGUMENTS: lang batch

module load parallel

SLANG="${1}"
BATCHES="${2}"

BATCH=`head -${SLURM_ARRAY_TASK_ID} ${BATCHES} | tail -1`
echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
echo "Batch: ${BATCH}"

/bin/time -f "%E %M" ${SCRIPTS}/06.align ${SLANG} ${BATCH}

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
