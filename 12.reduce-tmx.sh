#!/bin/bash
set -euo pipefail

. ./config.sh
. ./functions.sh

lang=$1
shift

collections=$@
collection_hash=$(printf "%s\n" $collections | sort | join_by -)

# Load the bicleaner model as we need to know the BICLEANER_THESHOLD
bicleaner_model $lang

if confirm; then
	schedule \
		-J reduce-tmx-${lang} \
		--time 36:00:00 \
		--exclusive \
		-e ${SLURM_LOGS}/12.reduce-tmx-%A.err \
		-o ${SLURM_LOGS}/12.reduce-tmx-%A.out \
		12.reduce-tmx ${lang} \
			"${DATA_CLEANING}/cleaning/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.${collection_hash}.tmx.gz" \
			"${DATA_CLEANING}/cleaning/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.${collection_hash}.txt.gz" \
			"${DATA_CLEANING}/cleaning/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.${collection_hash}.filtered${BICLEANER_THRESHOLD/./}.gz"

	schedule \
		-J reduce-tmx-deferred-${lang} \
		--time 36:00:00 \
		--exclusive \
		-e ${SLURM_LOGS}/12.reduce-tmx-%A.err \
		-o ${SLURM_LOGS}/12.reduce-tmx-%A.out \
		12.reduce-tmx-deferred ${lang} \
			"${DATA_CLEANING}/cleaning/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.${collection_hash}.deferred.tmx.gz" \
			"${DATA_CLEANING}/cleaning/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.${collection_hash}.filtered${BICLEANER_THRESHOLD/./}.gz"
fi
