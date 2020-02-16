#!/bin/sh

## create and submit the batches on csd3 for text splitting

. ./config.csd3

collection=$1
shift

for lang in $*; do
	ls -d ${DATA}/${collection}-shards/${lang}/*/* > ${DATA}/${collection}-batches/${lang}
	python split-cirrus.py 64 ${DATA}/${collection}-batches/${lang}
	n=`ls ${DATA}/${collection}-batches/${lang}.* | wc -l`
	sbatch -a 1-${n} 03.split-text.slurm ${lang} ${DATA}/${collection}-batches/${lang}
done
