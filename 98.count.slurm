#!/bin/sh
#SBATCH -J split
#SBATCH -c 1
#SBATCH --time 8:00:00
#SBATCH -e /home/%u/logs/98.count-%A_%a.err
#SBATCH -o /home/%u/logs/98.count-%A_%a.out

set -eu

module load parallel
module load perl/5.20.0

linecount() {
	pigz -cd $2/sentences.gz | base64 -d | wc -l > $2/linecount.txt
}

export -f linecount

export SLANG="${1}"
export BATCHES="${2}"
export CMD="linecount"

IFS=, read GROUP_START GROUP_END <<< $(get_group_boundaries ${BATCHES} ${SLURM_ARRAY_TASK_ID})

parallel -j$SLURM_CPUS_ON_NODE task ::: $(seq $GROUP_START $GROUP_END)
