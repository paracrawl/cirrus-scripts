#!/bin/bash
set -euo pipefail

. ./config.csd3

collection=$1
shift

for lang in $*; do
	cat ${DATA}/${collection}-batches/${lang} \
	| while read batch; do
		for match in ${batch}/aligned-*.gz; do
			echo $match 1>&2
			paste <(gzip -cd ${match} \
					| cut -f1-2 \
					| docjoin \
						-l $(dirname ${match})/url.gz \
						-r ${DATA}/${collection}-shards/en/$(basename $(dirname $batch))/$(echo $match | sed 's/.*-\([0-9]*\)\.gz/\1/')/url.gz) \
				  <(gzip -cd $match | cut -f3-)
		done
	done \
	| gzip -c > ${DATA}/${collection}-corpora/${collection}-unclean.${lang}-en.gz 
done

