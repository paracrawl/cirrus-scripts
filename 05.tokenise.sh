#!/bin/sh

## create and submit the batches on csd3 for translation

. ./config.csd3

collection=$1
shift

for lang in $*; do
	if ! test -d ${DATA}/${collection}-batches/${lang}; then
		ls -d ${DATA}/${collection}-shards/${lang}/*/* > ${DATA}/${collection}-batches/${lang}
	fi
	rm -f ${DATA}/${collection}-batches/05.${lang}
	ln -s   ${DATA}/${collection}-batches/${lang} ${DATA}/${collection}-batches/05.${lang}
	n=`< ${DATA}/${collection}-batches/05.${lang} wc -l`
	sbatch -a 1-${n} 05.tokenise.slurm ${lang} ${DATA}/${collection}-batches/05.${lang}
done
