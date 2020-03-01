#!/bin/sh

## create and submit the batches on csd3 for text splitting

. ./config.csd3

collection=$1
shift

for lang in $*; do
	if test $ -f ${DATA}/${collection}-batches/${lang}; then
		ls -d ${DATA}/${collection}-shards/${lang}/*/* > ${DATA}/${collection}-batches/${lang}
	fi
	ln -sf ${DATA}/${collection}-batches/${lang} ${DATA}/${collection}-batches/03.${lang}
	n=`< ${DATA}/${collection}-batches/${lang} wc -l`
	sbatch -a 1-${n} 03.split-text.slurm ${lang} ${DATA}/${collection}-batches/03.${lang}
done
