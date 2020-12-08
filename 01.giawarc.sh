#!/bin/bash
set -euo pipefail
line_count=$(wc -l $1 | cut -d' ' -f1)
group_size=144
group_count=$(( $line_count / $group_size + 1)) # plus 1 to round up

# Export these so they end up in the slurm script env
export GROUP_SIZE=$group_size
export BATCH_LIST="$1"

sbatch \
	--verbose \
	--account dc007 \
	--partition paracrawl \
	--qos paracrawl \
	--job-name giawarc \
	--time 4:00:00 \
	--exclusive \
	--array 1-$group_count \
	--export GROUP_SIZE,BATCH_LIST \
	./01.giawarc.slurm
