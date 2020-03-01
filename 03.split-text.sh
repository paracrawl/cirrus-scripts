#!/bin/sh

## create and submit the batches on csd3 for text splitting

. ./config.csd3

collection=$1
shift

for lang in $*; do
	ls -d ${DATA}/${collection}-shards/${lang}/*/* > ${DATA}/${collection}-batches/${lang}
	ln -sf ${DATA}/${collection}-batches/${lang} ${DATA}/${collection}-batches/03.${lang}
	python split-cirrus.py 64 ${DATA}/${collection}-batches/03.${lang}
	n=`ls ${DATA}/${collection}-batches/03.${lang}.* | wc -l`
	sbatch -a 1-${n} 03.split-text.slurm ${lang} ${DATA}/${collection}-batches/03.${lang}
done
