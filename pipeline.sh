#!/bin/bash
set -euo pipefail

. config.csd3

collection=$1
shift

function batch_count {
	ls -1d $DATA/$collection-shards/$1/*/*/ | wc -l
}

function step {
	echo -n "[$2] $1 "

	if [ ! -x ./$1.check.sh ]; then
		echo "No $1.check.sh file" 1>&2
		return 1
	fi

	# Test if all the files are okay for this step
	local broken=$(./$1.check.sh $collection $2 2>/dev/null)
	if [ -z "$broken" ]; then
		echo "OK"
		return 0
	else
		echo "NOT OK"
	fi

	# Test whether we can resolve this
	if [ ! -x ./$1.sh ]; then
		echo "No $1.sh file" 1>&2
		return 2
	fi

	# Delete the broken files
	echo -n "[$2] Deleting any existing broken files "
	while read file; do
		if [ -e $file ]; then
			mv $file $file~$(date +%Y%m%d-%H%M%S)~corrupt
		fi
	done <<< "$broken"
	echo "DONE"

	# Schedule a new run
	echo "[$2] Scheduling generation task"
	if [ $(wc -l <<< "$broken") -eq $(batch_count $2) ]; then
		./$1.sh $collection $2
		return 1
	else
		./$1.sh -r $collection $2
		return 1
	fi

	return 2 #why would we end up here?
}

function pipeline {
	step 02.shard $1 \
	&& step 03.split-text $1 \
	&& step 04.translate $1 \
	&& step 05.tokenise $1\
	&& step 06.align $1
}

for lang in "$@"; do
	pipeline $lang
done