#!/bin/sh
#SBATCH -J translate
#SBATCH -N 1
##SBATCH -A t2-cs119-cpu
##SBATCH -p skylake
##SBATCH --time 16:00:00
##SBATCH -n 16
#SBATCH -A t2-cs119-sl4-knl
#SBATCH -p knl
#SBATCH --time 4:00:00
#SBATCH --exclusive
#SBATCH -e /home/%u/logs/04.translate-%A_%a.err
#SBATCH -o /home/%u/logs/04.translate-%A_%a.out

## ARGUMENTS: lang batch

#export NMOSI=1 # For Skylake n=16
export NMOSI=16 # For Knights Landing

module load parallel
module load perl/5.20.0

SLANG="${1}"
BATCHES="${2}"

BATCH=`head -${SLURM_ARRAY_TASK_ID} ${BATCHES} | tail -1`
echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
echo "Batch: ${BATCH}"

/bin/time -f "%E %M" bash ${SCRIPTS}/04.translate.cpu ${SLANG} ${BATCH}

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
