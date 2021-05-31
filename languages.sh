#!/bin/bash
if [ -z "${PREFIX:-}" ]; then
	SELF=$(realpath "${BASH_SOURCE[0]}")
	PREFIX=$(dirname "$SELF")/env
fi

declare -A COLLECTIONS

while read language; do
	COLLECTIONS[$language]=$language
done < $PREFIX/../languages

for collection in $@; do
	if [[ $collection =~ -.* ]]; then
		unset COLLECTIONS[${collection#-}]
	else
		echo "Unknown argument: $collection" >&2
		exit 1
	fi
done

printf '%s\n' "${!COLLECTIONS[@]}" | sort
