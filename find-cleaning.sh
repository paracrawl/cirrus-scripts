#!/bin/bash
l=$1
shift
for collection in $(./collections.sh --paths); do
	find $collection-shards/$l \( \
		-name scored.gz -or \
		-name fixed.gz -or \
		-name hardruled.gz \
		-or -name 'filtered??.gz' \
		-or -name classified.gz \
	\) $@
done
