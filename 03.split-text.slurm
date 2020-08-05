#!/bin/sh
#SBATCH -J split
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time 8:00:00
#SBATCH -e /home/%u/logs/03.split-%A_%a.err
#SBATCH -o /home/%u/logs/03.split-%A_%a.out

set -eu

module load parallel
module load perl/5.20.0

SLANG="${1}"
BATCHES="${2}"
SPLIT=${SCRIPTS}/03.split-text
BATCH=`head -${SLURM_ARRAY_TASK_ID} ${BATCHES} | tail -1`

echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
echo "Batch: ${BATCH}"

export TMPDIR=$(mktemp -d --tmpdir=$SCRATCH)
/bin/time -f "%E %M" ${SPLIT} ${SLANG} ${BATCH}
rm -r $TMPDIR

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"

