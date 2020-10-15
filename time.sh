#!/bin/bash
set -euo pipefail

timings() {
	grep -E '(Starting|Done) whole node job|^Sentences:' \
	| sed -r 's/^(\w+) ([0-9]+) (\w+) ([0-9]+:[0-9]+:[0-9]+) (\w+) ([0-9]+) (Starting|Done) whole node job ([0-9]+)( \([0-9]+\))? on (\w+)/\7\t\2 \3 \6 \4 \5\t\8\t\10/' \
	| sed -r 's/^Sentences: ([0-9]+)$/Sentences\t0\t\1\tna/' \
	| while IFS=$'\t' read WHAT DATE JOB NODE; do
		SEC=$(date --date "$DATE" '+%s')
		case $WHAT in
			Sentences)
				SENT_CNT=$JOB
				;;
			Starting)
				START=$SEC
				SJOB=$JOB
				;;
			Done)
				if [ "$JOB" = "$SJOB" ]; then
					echo $(($SEC - $START)) $SENT_CNT $JOB
				fi
				;;
		esac
	done
}

sentences() {
	sed -nr 's,^Sentences: ([0-9]+)$,\1,p'
}

format_time() {
	local TIME=$(cat)
	printf "% 4d:%02d:%02d\n" \
		$(( $TIME / 3600 )) \
		$(( $(( $TIME % 3600 )) / 60 )) \
		$(( $TIME % 60 ))
}

sum() {
	paste -sd+ | bc
}

summary() {
	# prints min, max, med
	local TIMINGS=$(cat "$@" | sort -n)
	local COUNT=$(wc -l <<< "$TIMINGS")
	sed -n 1p <<< "$TIMINGS"
	sed -n ${COUNT}p <<< "$TIMINGS"
	echo $(( $(sum <<< "$TIMINGS") / $COUNT ))
	sed -n $(( $COUNT / 2 ))p <<< "$TIMINGS"
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

JOBS=$(cat $@ | timings)

if [ $MODE = "list" ]; then
	echo "$JOBS"
elif [ $MODE = "summary" ]; then
	TIMINGS=$(cut -d' ' -f1 <<< "$JOBS" | sort -n)
	COUNT=$(wc -l <<< "$TIMINGS")
	echo "Count:  " $COUNT tasks
	echo "Sum:    " $(sum <<< "$TIMINGS" | format_time)

	STATS=( $(summary <<< "$TIMINGS") )

	echo "Min:    " $(echo ${STATS[0]} | format_time)
	echo "Max:    " $(echo ${STATS[1]} | format_time)
	echo "Mean:   " $(echo ${STATS[2]} | format_time)
	echo "Median: " $(echo ${STATS[3]} | format_time)
fi

WORDS_PER_SECOND=$(\
	cat <<< "$JOBS" \
	| cut -d' ' -f1-2 \
	| while read JOB SENTENCE_COUNT; do
		echo $(( $SENTENCE_COUNT / $JOB ))
	done \
)

STATS=( $(summary <<< "$WORDS_PER_SECOND") )
echo
printf "\
Count:   % 9d lines
Min:     % 9d lines/second
Max:     % 9d lines/second
Mean:    % 9d lines/second
Median:  % 9d lines/second
" \
	$(cut -d' ' -f2 <<< "$JOBS" | sum) \
	${STATS[@]}

