#!/bin/sh
#SBATCH -J translate
#SBATCH -A t2-cs119-sl4-knl
#SBATCH -p knl
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --time 12:00:00
#SBATCH -e /home/cs-wait1/logs/04.translate-%A_%a.err
#SBATCH -o /home/cs-wait1/logs/04.translate-%A_%a.out

## ARGUMENTS: lang batch

. /home/cs-wait1/src/cirrus-scripts/config.csd3

module load parallel
module load perl/5.20.0

SLANG="${1}"
BATCHES="${2}"
TRANSLATE=${SCRIPTS}/04.translate
COLLECTIONS=${BATCHES}.${SLURM_ARRAY_TASK_ID}

echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
echo "Collections: ${COLLECTIONS}"

< ${COLLECTIONS} /bin/time -f "%E %M" parallel -j 8 ${TRANSLATE} ${SLANG} '{}'

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
