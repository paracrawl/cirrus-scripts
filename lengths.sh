#!/bin/bash

line_lengths() {
	gzip -cd $1 \
	| awk \
		-v filename="$1" \
		'{print filename, NR, length}'
}

if [ $# -eq 0 ]; then
	echo "Usage: $0 files"
	echo "Print the filename, line number and length of the (base64-encoded) line"
	echo "sorted by line length, longest lines first."
	exit 0
fi

export -f line_lengths
parallel -j50% line_lengths ::: "$@" | sort --parallel 4 -S4G -nrk3
