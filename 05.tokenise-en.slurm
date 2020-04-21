#!/bin/sh
#SBATCH -J tok
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --time 2:00:00
#SBATCH -e /home/%u/logs/05.tokenise-en-%A_%a.err
#SBATCH -o /home/%u/logs/05.tokenise-en-%A_%a.out

## ARGUMENTS: lang batch

#. /home/$USER/src/cirrus-scripts/config.csd3

module load parallel
module load perl/5.20.0

BATCHES="${1}"
TOKENISE=${SCRIPTS}/05.tokenise-en
BATCH=`head -${SLURM_ARRAY_TASK_ID} ${BATCHES} | tail -1`

TMPDIR=${SCRATCH}/tokenise.$$
mkdir -p ${TMPDIR} || exit 255
export TMPDIR

echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"

/bin/time -f "%E %M" ${TOKENISE} "${BATCH}"

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
