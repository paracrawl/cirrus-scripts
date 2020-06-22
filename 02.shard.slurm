#!/bin/sh
#SBATCH -J shard
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
#SBATCH -N 1
#sbatch -n 2
#SBATCH --time 16:00:00
#SBATCH -e /home/%u/logs/02.shard-%j.err
#SBATCH -o /home/%u/logs/02.shard-%j.out

# Single-threaded version of giashard. Only useful for
# pretty small languages. Use the more complicated
# set + merge for larger languages.

COLLECTION="${1}"
SLANG="${2}"
shift; shift

ulimit -n 16384

OUTPUT=${DATA}/${COLLECTION}-shards/${SLANG}

$GIASHARD -n 8 -b 1024 \
	-o ${OUTPUT}.$$ \
	${DATA}/${COLLECTION}-text/*/${SLANG}

mv $OUTPUT.$$ $OUTPUT
