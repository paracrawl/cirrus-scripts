#!/bin/bash
set -eou pipefail

group_lines () {
	local prev_batch=;
	while read batch line url; do
		if [ ! "$prev_batch" = "$batch" ]; then
			if [ ! -z "$prev_batch" ]; then
				echo
			fi
			printf '%s ' "$batch"
		fi
		printf ' %d' $line
		prev_batch="$batch"
	done
	echo
	exit 1
}

nuke_lines () {
	while read -r line; do
		local batch="${line%% *}"
		local lines="${line#* }"
		(cd ${batch%/*} && ~/src/cirrus-scripts/nuke.sh $lines)
	done
}

export -f nuke_lines

cat "$@" \
| LC_ALL=C sort -S4G \
| group_lines \
| parallel --pipe -j4 nuke_lines
