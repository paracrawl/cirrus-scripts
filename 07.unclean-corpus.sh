#!/bin/bash
set -euo pipefail

. env/init.sh
. config.sh
. functions.sh

collection=$1
shift

for lang in $*; do
	mkdir -p ${COLLECTIONS[$collection]}-corpora
	schedule \
		-J corpus-${lang%~*}-${collection} \
		--time 24:00:00 \
		-e ${SLURM_LOGS}/07.corpus-%A_%a.err \
		-o ${SLURM_LOGS}/07.corpus-%A_%a.out \
		${SCRIPTS}/07.unclean-corpus.slurm \
		${COLLECTIONS[$collection]}-corpora/$collection-unclean.${TARGET_LANG%~*}-${lang%~*}.gz \
		${COLLECTIONS[$collection]}-shards/${TARGET_LANG} \
		${COLLECTIONS[$collection]}-batches/${lang}
done

