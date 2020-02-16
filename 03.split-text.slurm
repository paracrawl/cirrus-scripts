#!/bin/sh
#SBATCH -J split
#SBATCH -A t2-cs119-sl4-knl
#SBATCH -p knl
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --time 12:00:00
#SBATCH -e /home/cs-wait1/logs/03.split-%A_%a.err
#SBATCH -o /home/cs-wait1/logs/03.split-%A_%a.out

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

. /home/cs-wait1/src/cirrus-scripts/config.csd3

module load parallel
module load perl/5.20.0

SLANG="${1}"
BATCHES="${2}"
SPLIT=${SCRIPTS}/03.split-text
COLLECTIONS=${BATCHES}.${SLURM_ARRAY_TASK_ID}

echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
echo "Collections: ${COLLECTIONS}"

< ${COLLECTIONS} /bin/time -f "%E %M" parallel ${SPLIT} ${SLANG} '{}' 2>&1

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"

