#!/bin/sh
#SBATCH -J check
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --time 8:00:00
#SBATCH -e /home/%u/logs/99.check-%j.err
#SBATCH -o /home/%u/logs/99.check-%j.out

set -eu

COLLECTION="${1}"
LANG="${2}"

module load parallel

ulimit -n 2048
export LC_ALL=C # For perl and the likes

./pipeline.sh -j 64 -t $COLLECTION $LANG

