#!/bin/bash

## create and submit the batches on csd3 for alignment
set -euo pipefail

. ./config.csd3
export TASKS_PER_BATCH=4 # Also used by 06.align.slurm, hence export

collection=$1
shift

for lang in $*; do
	if ! test -d ${DATA}/${collection}-batches/06.${lang}; then
		for shard in $(ls -d ${DATA}/${collection}-shards/${lang}/*); do
			join -j2 \
				<(ls -d $shard/*) \
				<(ls -d ${DATA}/${collection}-shards/en/$(basename $shard)/*)
		done > ${DATA}/${collection}-batches/06.${lang}
	fi
	n=$(( $(< ${DATA}/${collection}-batches/06.${lang} wc -l) / ${TASKS_PER_BATCH}))
	sbatch --nice=600 -J align-${lang} -a 1-${n} ${SCRIPTS}/06.align.slurm ${lang} ${DATA}/${collection}-batches/06.${lang}
done
