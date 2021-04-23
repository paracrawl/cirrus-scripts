#!/bin/bash
if [ -z "${PREFIX:-}" ]; then
	SELF=$(realpath "${BASH_SOURCE[0]}")
	PREFIX=$(dirname "$SELF")/env
fi

. $PREFIX/init.sh
. $PREFIX/../config.sh

for collection in $@; do
	if [[ $collection =~ -.* ]]; then
		unset COLLECTIONS[${collection#-}]
	else
		echo "Unknown argument: $collection" >&2
		exit 1
	fi
done

printf '%s\n' "${!COLLECTIONS[@]}" | sort
