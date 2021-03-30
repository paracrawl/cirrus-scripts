#!/bin/bash
set -euo pipefail

export MODEL=$1
shift

translate-apertium() {
	sed "s/\xc2\xad/ /g" \
	| sed "s/\x00//g" \
	| sed 's/&#10;//g' \
	| sed -r 's/\^.?\$//g' \
	| sed -r 's/^([-\.]?[0-9]+){25,}$//g' \
	| sed -r 's/^(CONTAMINACIÓNVISUAL){25,}//g' \
	| sed -r 's/^Ñ{250,}$//g' \
	| sed -r 's/^[ÍI]{50,}$//g' \
	| sed 's/^/<p>/g' \
	| sed 's/$/<\/p>/g' \
	| apertium -f html -u $MODEL \
	| sed -r 's/<\/?p>//g' \
	| recode html
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

