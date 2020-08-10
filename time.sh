#!/bin/bash
set -euo pipefail

timings() {
	grep -E '(Starting|Done) whole node job' \
	| sed -r 's/^(\w+) ([0-9]+) (\w+) ([0-9]+:[0-9]+:[0-9]+) (\w+) ([0-9]+) (Starting|Done) whole node job ([0-9]+)( \([0-9]+\))? on (\w+)/\7\t\2 \3 \6 \4 \5\t\8\t\10/' \
	| while IFS=$'\t' read WHAT DATE JOB NODE; do
		SEC=$(date --date "$DATE" '+%s')
		case $WHAT in
			Starting)
				START=$SEC
				SJOB=$JOB
				;;
			Done)
				if [ "$JOB" = "$SJOB" ]; then
					echo $(($SEC - $START)) $JOB
				fi
				;;
		esac
	done
}

format_time() {
	date -d@$(cat) -u '+%H:%M:%S'
}

MODE=summary

while true; do
	case "$1" in
		-l)
			MODE=list
			shift
			;;
		*)
			break
	esac
done

JOBS=$(cat $@ | timings | sort -n)

if [ $MODE = "list" ]; then
	echo "$JOBS"
elif [ $MODE = "summary" ]; then
	TIMINGS=$(cut -d' ' -f1 <<< "$JOBS")
	COUNT=$(wc -l <<< "$TIMINGS")
	echo "Count:  " $COUNT tasks
	echo "Sum:    " $(paste -sd+ <<< "$TIMINGS" | bc | format_time)

	echo "Min:    " $(sed -n 1p <<< "$TIMINGS" | format_time)
	echo "Max:    " $(sed -n ${COUNT}p <<< "$TIMINGS" | format_time)
	echo "Median: " $(sed -n $(( $COUNT / 2 ))p <<< "$TIMINGS" | format_time)
fi
