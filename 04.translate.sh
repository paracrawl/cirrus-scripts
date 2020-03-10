#!/bin/sh

## create and submit the batches on csd3 for translation
set -euo pipefail

. ./config.csd3
collection=$1
shift

for lang in $*; do
	if ! test -d ${DATA}/${collection}-batches/${lang}; then
		ls -d ${DATA}/${collection}-shards/${lang}/*/* > ${DATA}/${collection}-batches/${lang}
	fi
	rm -f ${DATA}/${collection}-batches/04.${lang}
	ln -s   ${DATA}/${collection}-batches/${lang} ${DATA}/${collection}-batches/04.${lang}
	python split-cirrus.py 16 ${DATA}/${collection}-batches/04.${lang}
	n=`< ${DATA}/${collection}-batches/04.${lang} wc -l`
	sbatch -J translate-${lang} -a 1-${n} 04.translate.slurm ${lang} ${DATA}/${collection}-batches/04.${lang}
done
