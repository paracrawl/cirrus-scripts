#!/bin/bash
set -euo pipefail

# Disabled for now while I fix compilation issues. Fall back
# to my locally installed versions which I know work well.
#source $(dirname $(realpath $0))/env/init.sh

cd /rds/project/t2_vol4/rds-t2-cs119/cwang/nmt/home/bhaddow/experiments/paracrawl/chinese/mt

# Give Jieba it's own tempdir to avoid race conditions when it's dumping its model.
JIEBA_TMP=$(mktemp -d)
trap "rm -fr $JIEBA_TMP" exit

#| $PREFIX/src/marian-dev/build/marian-decoder \
#| $PREFIX/src/marian-fbgemm/build/marian-decoder \

TMPDIR=$JIEBA_TMP python3 -m jieba -d ' ' \
| subword-nmt apply-bpe \
	-c prepare01/bpe.model.zh \
| marian-decoder-cpu \
	-m /home/cs-vand1/src/cirrus-scripts/model.zhen.fbgemm.bin \
	-v run02/vocab.{zh,en}.yml \
	-w 3000 \
	--normalize 1 \
	--word-penalty 0 \
	--beam-size 4 \
	--mini-batch-words 300 \
	--maxi-batch 2000 \
	--maxi-batch-sort src \
	--shortlist /home/cs-vand1/src/cirrus-scripts/lex.zhen.gz \
	"$@" \
| perl -pe 's/@@ //g' \
|  $MOSES/scripts/recaser/detruecase.perl \
|  $MOSES/scripts/tokenizer/detokenizer.perl -q -l en

rm -fr $JIEBA_TMP

