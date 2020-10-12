#!/bin/bash
set -eou pipefail

files=(
	plain_text.gz
	sentences.gz
	tokenised.gz
	sentences_en.gz
	sentences_es.gz
	tokenised_en.gz
	tokenised_es.gz
)

exists() {
	for file in $*; do
		if [ -f $file ]; then
			echo $file
		fi
	done
}

remove_lines() {
	awk "{ if ( NR ~ /^($(echo "$*" | tr ' ' '|'))$/) print \"\"; else print }"
}

for file in $(exists ${files[@]}); do
	gzip -cd $file \
	| remove_lines $* \
	| gzip > $file.$$

	if [ ! -e $file~ ]; then
		mv $file $file~
	fi

	mv $file.$$ $file
done
