#!/bin/bash
set -euo pipefail

export MODEL=$1
shift

# Apertium messes up lines when encountering utf-8 nbsp. It
# also has trouble with "^$", introducing a full stop and
# skipping the line break altogether.
# Note: eu has some oddity where it break on @ sometimes.
# Adding `| tr '@' '.'` helps with that.

translate-apertium() {
	sed "s/\xc2\xad/ /g" \
		| sed "s/\x00//g" \
		| sed 's/\\^\\$//g' \
		| apertium-destxt -i \
		| apertium -f none -u $MODEL \
		| apertium-retxt
}

ceil () {
	test "$2" == "/" || return 1
	echo $(( ( $1 + $3 - 1 ) / $3 ))
}


if [ ! -z "${SIZE_HINT:-}" ]; then
	RECSIZE=$(ceil $(ceil $SIZE_HINT / 32) / $THREADS)
else
	RECSIZE=4096
fi

export -f translate-apertium

# No foldfilter? No, don't know who sensitive apertium is to that kind of force
parallel --halt 2 -j $THREADS --pipe -k -l $RECSIZE translate-apertium "$@"

