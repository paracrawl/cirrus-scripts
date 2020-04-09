#!/bin/sh
#SBATCH -J translate
#SBATCH -A t2-cs119-knl
#SBATCH -p knl
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --time 24:00:00
#SBATCH -e /home/%u/logs/04.translate-%A_%a.err
#SBATCH -o /home/%u/logs/04.translate-%A_%a.out

## ARGUMENTS: lang batch

. /home/$USER/src/cirrus-scripts/config.csd3

module load parallel
module load perl/5.20.0

SLANG="${1}"
BATCHES="${2}"
TRANSLATE=${SCRIPTS}/04.translate

BATCH=`head -${SLURM_ARRAY_TASK_ID} ${BATCHES} | tail -1`
echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
echo "Batch: ${BATCH}"

/bin/time -f "%E %M" ${TRANSLATE} ${SLANG} ${BATCH}

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
