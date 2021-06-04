#!/bin/bash
set -euo pipefail

ceil () {
	test "$2" == "/" || return 1
	echo $(( ( $1 + $3 - 1 ) / $3 ))
}

export MODEL=$(dirname $(realpath -es ${BASH_SOURCE[0]}))
export SLANG=$(basename $MODEL | cut -d- -f1)
export TRUECASE_MODEL=truecase-model.$SLANG
export NMOSI=$(ceil $THREADS / 16)
export THREADS=$((THREADS / $NMOSI))

if [ ! -z "${SIZE_HINT:-}" ]; then
	RECSIZE=$(ceil $(ceil $SIZE_HINT / 32) / $NMOSI)
else
	RECSIZE=4096
fi

echo "Running $NMOSI x $THREADS moses2 threads for $SLANG-en in steps of $RECSIZE" >&2
echo "model=${MODEL}" >&2

translate-moses () {
	set -euo pipefail
	cd $MODEL
	$MOSES/scripts/tokenizer/tokenizer.perl -a -q -l $SLANG \
	| $MOSES/scripts/recaser/truecase.perl --model $TRUECASE_MODEL \
	| $MOSES_BIN -v 0 --threads $THREADS -f ${MOSES_INI:-moses2.ini} \
	| $MOSES/scripts/recaser/detruecase.perl \
	| $MOSES/scripts/tokenizer/detokenizer.perl -q
}

export -f translate-moses

foldfilter -s -w 500 \
parallel --halt 2 -j ${NMOSI} --pipe -k -l $RECSIZE \
translate-moses "$@"

