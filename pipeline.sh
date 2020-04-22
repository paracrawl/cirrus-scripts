#!/bin/bash
set -euo pipefail

. config.csd3
. functions.sh

collection=$1
shift

declare -g LAST_JOB_ID LAST_JOB_IS_PARTIAL

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
	local dependency_opt=""

	if [ -n "$LAST_JOB_ID" ]; then
		if [ "$LAST_JOB_IS_PARTIAL" -eq 0 ]; then
			# If the last job was full array, we can do pipelining on individual jobs
			dependency_opt="--aftercorr $LAST_JOB_ID"
		else
			# Otherwise, just wait for the full job to finish to be sure
			dependency_opt="--afterok $LAST_JOB_ID"
		fi
	fi

	if [ $(wc -l <<< "$broken") -eq $(batch_count $2) ]; then
		LAST_JOB_IS_PARTIAL=0
		LAST_JOB_ID=$(./$1.sh $dependency_opt $collection $2)
		return 0
	else
		LAST_JOB_IS_PARTIAL=1
		LAST_JOB_ID=$(./$1.sh -r $dependency_opt $collection $2)
		return 0
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
		if step $step_name $1; then
			echo $LAST_JOB_ID
			prompt "Continue scheduling next step?\n"

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
