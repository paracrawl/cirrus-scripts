#!/bin/sh
#SBATCH -J split
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
#SBATCH -N 1
#sbatch -n 4
#SBATCH --time 1:00:00
#SBATCH -e /home/%u/logs/03.split-%A_%a.err
#SBATCH -o /home/%u/logs/03.split-%A_%a.out

set -eu

### To use this:
###
### 1. create a list of batches to have their sentences split. For Icelandic,
###
###    ls -d $DATA/wide00006-shards/is/*/* > batches.is
###
### 2. split the batch list into chunks of, say, 64 each
###
###    python split-cirrus.py 64 batches.is
###
### 3. submit an array job according to the number of chunks
###
###    sbatch -a 1-4 03.split.slurm is batches.is
###

# Commented out because I assume sbatch will pass them on
#. /home/$USER/src/cirrus-scripts/config.csd3

module load parallel
module load perl/5.20.0

THREADS=8
SLANG="${1}"
BATCHES="${2}"
SPLIT=${SCRIPTS}/03.split-text
BATCH=`head -${SLURM_ARRAY_TASK_ID} ${BATCHES} | tail -1`

echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
echo "Batch: ${BATCH}"

export TMPDIR=${SCRATCH}/split.$$
mkdir -p ${TMPDIR}
/bin/time -f "%E %M" ${SPLIT} ${SLANG} ${BATCH}
rm -rf ${TMPDIR}

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"

