#!/bin/sh
#SBATCH -J split
#SBATCH -c 1
#SBATCH --time 8:00:00
#SBATCH -e /home/%u/logs/03.split-%A_%a.err
#SBATCH -o /home/%u/logs/03.split-%A_%a.out

set -eu

module load parallel
module load perl/5.20.0

export SLANG="${1}"
export BATCHES="${2}"
export CMD=${SCRIPTS}/03.split-text
export TMPDIR=$(mktemp -d --tmpdir=$SCRATCH)

chown :t2-cs119 $TMPDIR
chmod g+s $TMPDIR

IFS=, read GROUP_START GROUP_END <<< $(get_group_boundaries ${BATCHES} ${SLURM_ARRAY_TASK_ID})

parallel -j$SLURM_CPUS_ON_NODE task ::: $(seq $GROUP_START $GROUP_END)
