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
	if $RETRY; then
		prompt "[$2] These files are broken or not found:\n"
		echo "$broken"
		confirm || return 1

		while read file; do
			if [ -e $file ]; then
				mv $file $file~$(date +%Y%m%d-%H%M%S)~corrupt
			fi
		done <<< "$broken"
	fi

	# Schedule a new run
	prompt "[$2] Scheduling task\n"
	local dependency_opt=""

	if [ -n "$LAST_JOB_ID" ]; then
		if [ "$LAST_JOB_IS_PARTIAL" -eq 0 ] && [ "$2" != "06" ]; then
			# If the last job was full array, we can do pipelining on individual jobs
			dependency_opt="--aftercorr $LAST_JOB_ID"
		else
			# Otherwise, just wait for the full job to finish to be sure
			dependency_opt="--afterok $LAST_JOB_ID"
		fi
	fi

	if $RETRY  && [ $(wc -l <<< "$broken") -ne $(batch_count $2) ]; then
		LAST_JOB_IS_PARTIAL=1
		LAST_JOB_ID=$(./$1.sh -r $dependency_opt $collection $2)
	else
		LAST_JOB_IS_PARTIAL=0
		LAST_JOB_ID=$(./$1.sh $dependency_opt $collection $2)
	fi

	echo $LAST_JOB_ID
	return 0
}

steps=(
	02.shard
	03.split-text
	04.translate
	05.tokenise
	06.align
)

function pipeline {
	for step_name in ${steps[@]}; do
		if [ -n "$LAST_JOB_ID" ]; then
			prompt "Continue scheduling next step $step_name?\n"
			if ! confirm ; then
				break
			fi
		fi

		if ! step $step_name $1; then
			break
		fi
	done
}

for lang in "$@"; do
	LAST_JOB_ID="" # Reset LAST_JOB_ID so we don't inter-depend between languages
	pipeline $lang
done
