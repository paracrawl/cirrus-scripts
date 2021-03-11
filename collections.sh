#!/bin/bash
. env/init.sh
. config.sh

for collection in $@; do
	if [[ $collection =~ -.* ]]; then
		unset COLLECTIONS[${collection#-}]
	else
		echo "Unknown argument: $collection" >&2
		exit 1
	fi
done

printf '%s\n' "${!COLLECTIONS[@]}" | sort
