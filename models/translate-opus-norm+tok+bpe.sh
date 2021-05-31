#!/bin/bash
set -euo pipefail

MODEL=$(dirname $(realpath -es ${BASH_SOURCE[0]}))
SLANG=$(basename $MODEL | cut -d- -f1)
TOKENIZER=$PREFIX/src/mosesdecoder/scripts/tokenizer

${TOKENIZER}/replace-unicode-punctuation.perl |
${TOKENIZER}/remove-non-printing-char.perl |
${TOKENIZER}/normalize-punctuation.perl -l $SLANG |
${TOKENIZER}/tokenizer.perl -a -threads $THREADS -l $SLANG |
sed 's/  */ /g;s/^ *//g;s/ *$$//g' |
subword-nmt apply-bpe -c $MODEL/source.bpe |
foldfilter -s -w 500 marian-decoder \
	-c $MODEL/decoder.yml \
	--cpu-threads $THREADS \
	--quiet-translation \
	"$@" |
sed 's/\@\@ //g;s/ \@\@//g;s/ \@\-\@ /-/g' |
${TOKENIZER}/detokenizer.perl -l $SLANG

