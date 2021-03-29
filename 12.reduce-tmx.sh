#!/bin/bash
set -euo pipefail

. ./env/init.sh
. ./config.sh
. ./functions.sh

lang=$1
shift

collections=$@
collection_hash=$(printf "%s\n" $collections | sort | join_by -)

# Load the bicleaner model as we need to know the BICLEANER_THESHOLD
bicleaner_model ${lang%~*}

output_base="${DATA_CLEANING}/${TARGET_LANG}-${lang}/${TARGET_LANG%~*}-${lang%~*}.${collection_hash}"

# Lots of work to determine which files need to be (re)generated while only
# calling `confirm` once.
needs_tmx=false
needs_deferred=false

if ! $RETRY || [ ! -f "${output_base}.tmx.gz" ]; then
	echo "${output_base}.tmx.gz" >&2
	needs_tmx=true
fi
if ! $RETRY || [ ! -f "${output_base}.deferred.tmx.gz" ]; then
	echo "${output_base}.deferred.tmx.gz" >&2
	needs_deferred=true
fi

if ( $needs_tmx || $needs_deferred ) && confirm; then
	if $needs_tmx; then
		schedule \
			-J reduce-tmx-${lang%~*} \
			--time 36:00:00 \
			--exclusive \
			-e ${SLURM_LOGS}/12.reduce-tmx-%A.err \
			-o ${SLURM_LOGS}/12.reduce-tmx-%A.out \
			${SCRIPTS}/12.reduce-tmx ${lang%~*} \
				"${output_base}.tmx.gz" \
				"${output_base}.txt.gz" \
				"${output_base}.filtered${BICLEANER_THRESHOLD/./}.gz"
	fi

	if $needs_deferred; then
		schedule \
			-J reduce-tmx-deferred-${lang%~*} \
			--time 36:00:00 \
			--exclusive \
			-e ${SLURM_LOGS}/12.reduce-tmx-%A.err \
			-o ${SLURM_LOGS}/12.reduce-tmx-%A.out \
			${SCRIPTS}/12.reduce-tmx-deferred ${lang%~*} \
				"${output_base}.deferred.tmx.gz" \
				"${output_base}.filtered${BICLEANER_THRESHOLD/./}.gz"
	fi
fi
