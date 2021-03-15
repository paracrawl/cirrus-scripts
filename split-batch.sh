#!/bin/bash
set -euo pipefail

basename() {
	sed 's,.*/\(.*\)$,\1,'
}

files=(
	plain_text
	sentences
	sentences_en
	sentences_es
	source
	url
)

find_offset() {
	max=
	for batch in $(find $1 -maxdepth 1 -type d -regex '.*/[0-9]*' | basename | tr -dc '0-9\n'); do
		if [ -z "$max" ] || [ "$batch" -gt "$max" ]; then
			max=$batch
		fi
	done
	echo $max
}

N=$1
shift

for batch in "$@"; do
	lines=$(pigz -cd $batch/source.gz | wc -l)
	lines_per_part=$(( $lines / $N + 1))

	offset=$(find_offset $batch/..)
	
	# For each known type of file (column) in our batch
	for file in ${files[@]}; do
		if [ -f $batch/${file}.gz ]; then
			# Split file into multiple parts
			pigz -cd $batch/${file}.gz \
			| split -d -l $lines_per_part - $batch/${file}.$$.part
	
			# Next batch is current offset + 1
			part_offset=$(($offset + 1))
			
			# Compress each part (note $part is a full path)
			for part in $(find $batch -name "${file}.$$.part*"); do
				echo $part_offset/$file 1>&2
				mkdir -p $batch/../$part_offset
				pigz -9c < $part > $batch/../$part_offset/${file}.gz
				rm $part
				part_offset=$(($part_offset + 1))
			done
		fi
	done

	mv $batch $batch~
done
