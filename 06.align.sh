#!/bin/sh

## create and submit the batches on csd3 for alignment

. ./config.csd3
export TASKS_PER_BATCH=4

collection=$1
shift

for lang in $*; do
	if ! test -d ${DATA}/${collection}-batches/${lang}; then
		ls -d ${DATA}/${collection}-shards/${lang}/*/* > ${DATA}/${collection}-batches/${lang}
	fi
	rm -f ${DATA}/${collection}-batches/06.${lang}
	ln -s   ${DATA}/${collection}-batches/${lang} ${DATA}/${collection}-batches/06.${lang}
	n=$((`< ${DATA}/${collection}-batches/06.${lang} wc -l`/${TASKS_PER_BATCH}))
	sbatch --nice=600 -J align-${lang} -a 1-${n} ${SCRIPTS}/06.align.slurm ${lang} ${DATA}/${collection}-batches/06.${lang}
done
