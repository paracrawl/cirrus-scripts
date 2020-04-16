#!/bin/sh
#SBATCH -J translate
#SBATCH -A t2-cs119-gpu
#SBATCH -p pascal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --no-requeue
#SBATCH --time 4:00:00
#SBATCH -e /home/%u/logs/04.translate-%A_%a.err
#SBATCH -o /home/%u/logs/04.translate-%A_%a.out

## ARGUMENTS: lang batch

set -euo pipefail

. /etc/profile.d/modules.sh
module purge
module load parallel
module load perl/5.20.0
module load \
    cuda/10.1 \
    boost-1.66.0-gcc-5.4.0-slpq3un \
    boost-1.66.0-gcc-5.4.0-slpq3un \
    intel/mkl/2019.1 \
    gperf-3.0.4-gcc-5.4.0-noi4rwb \
    protobuf-3.4.0-gcc-5.4.0-zkpendv

SLANG="${1}"
BATCHES="${2}"

BATCH=`head -${SLURM_ARRAY_TASK_ID} ${BATCHES} | tail -1`
echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
echo "Batch: ${BATCH}"

/bin/time -f "%E %M" bash ${SCRIPTS}/04.translate.gpu ${SLANG} ${BATCH}

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
