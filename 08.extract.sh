#!/bin/bash
set -euo pipefail

. config.csd3
. functions.sh

collection=$1
shift

for lang in $*; do
	schedule \
		-J extract-$lang \
		--cpus-per-task 1 \
		--time 4:00:00 \
		-e ${SLURM_LOGS}/08.extract-%A.err \
		-o ${SLURM_LOGS}/08.extract-%A.out \
		$SCRIPTS/08.extract $collection $lang \
		$DATA/${collection}-corpora/${collection}-unclean.${TARGET_LANG}-${lang}.gz
done
