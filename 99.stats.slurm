#!/bin/sh
#SBATCH -J stats
#SBATCH -p skylake
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --time 8:00:00
#SBATCH -e /home/%u/logs/99.stats-%j.err
#SBATCH -o /home/%u/logs/99.stats-%j.out
#SBATCH --mail-type=ALL

set -eu

COLLECTION="${1}"
LANG="${2}"

module load parallel

ulimit -n 2048

. ./config.csd3

batches () {
	ls -1d ${DATA}/${COLLECTION}-shards/${LANG}/*/*/ | shuf | while read batch; do
		if test ${batch} -nt ${batch}/stats.json.gz; then
			echo ${batch}
		fi
	done	
}

batches | parallel -j64 giastat -c -w '{}'

