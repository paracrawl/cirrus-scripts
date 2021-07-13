#!/bin/bash
if [ -z "${PREFIX:-}" ]; then
	SELF=$(realpath "${BASH_SOURCE[0]}")
	PREFIX=$(dirname "$SELF")/env
fi

. $PREFIX/init.sh
. $PREFIX/../config.sh

PRINT_PATHS=false

if [[ $1 == --paths ]]; then
	PRINT_PATHS=true
	shift
fi

for collection in $@; do
	if [[ $collection =~ -.* ]]; then
		unset COLLECTIONS[${collection#-}]
	else
		echo "Unknown argument: $collection" >&2
		exit 1
	fi
done

if $PRINT_PATHS; then
	printf '%s\n' "${COLLECTIONS[@]}"
else
	printf '%s\n' "${!COLLECTIONS[@]}"
fi | sort
