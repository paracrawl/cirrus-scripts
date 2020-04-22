#!/bin/bash
set -euo pipefail

. config.csd3
. functions.sh

collection=$1
shift

declare -g LAST_JOB_ID

function batch_count {
	ls -1d $DATA/$collection-shards/$1/*/*/ | wc -l
}

function step {
	prompt "[$2] $1\t"

	if [ ! -x ./$1.check.sh ]; then
		prompt "No $1.check.sh file\n"
		return 1
	fi

	# Test if all the files are okay for this step
	local broken=$(./$1.check.sh $collection $2 2>/dev/null)
	if [ -z "$broken" ]; then
		prompt "OK\n"
		return 0
	else
		prompt "NOT OK\n"
	fi

	# Test whether we can resolve this
	if [ ! -x ./$1.sh ]; then
		prompt "No $1.sh file\n"
		return 2
	fi

	# Delete the broken files
	prompt "[$2] Deleting any existing broken files:\n"
	xargs ls -l <<< "$broken" 2> /dev/null || true # I don't care if this fails
	confirm || return 1

	while read file; do
		if [ -e $file ]; then
			mv $file $file~$(date +%Y%m%d-%H%M%S)~corrupt
		fi
	done <<< "$broken"

	# Schedule a new run
	prompt "[$2] Scheduling generation task\n" 2>&1
	if [ -n "$LAST_JOB_ID" ]; then
		local dependency="--aftercorr $LAST_JOB_ID"
	else
		local dependency=""
	fi

	if [ $(wc -l <<< "$broken") -eq $(batch_count $2) ]; then
		LAST_JOB_ID=$(./$1.sh $dependency $collection $2)
		return 1
	else
		LAST_JOB_ID=$(./$1.sh -r $dependency $collection $2)
		return 1
	fi

	return 2 #why would we end up here?
}

steps=(
	02.shard
	03.split-text
	04.translate
	05.tokenise
	#06.align
)

function pipeline {
	for step_name in ${steps[@]}; do
		# If the step wasn't already done & correct this will schedule it
		step $step_name $1
		if [ $? -ne 0 ]; then
			echo $LAST_JOB_ID
			prompt "Continue scheduling next step?"

			# Do we want to continue checking & scheduling?
			if confirm ; then
				continue
			else
				break
			fi
		fi
	done
}

for lang in "$@"; do
	LAST_JOB_ID="" # Reset LAST_JOB_ID so we don't inter-depend between languages
	pipeline $lang
done
