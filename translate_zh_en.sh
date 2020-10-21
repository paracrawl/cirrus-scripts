#!/bin/bash
set -euo pipefail


cd /rds/project/t2_vol4/rds-t2-cs119/cwang/nmt/home/bhaddow/experiments/paracrawl/chinese/mt

# Give Jieba it's own tempdir to avoid race conditions when it's dumping its model.
JIEBA_TMP=$(mktemp -d)

TMPDIR=$JIEBA_TMP $JIEBA -d ' ' \
| python3 $BPE/apply_bpe.py \
	-c prepare01/bpe.model.zh \
| $MARIAN/marian-decoder \
	-m run02/model.npz.best-translation.npz \
	-v run02/vocab.{zh,en}.yml \
	-w 3200 \
	--optimize \
	--normalize 1 \
	--word-penalty 0 \
	--beam-size 4 \
	--mini-batch-words 3000 \
	--maxi-batch 4000 \
	--maxi-batch-sort src \
	--shortlist /home/cs-vand1/src/cirrus-scripts/lex.zhen \
	"$@" \
| perl -pe 's/@@ //g' \
|  $MOSES/scripts/recaser/detruecase.perl \
|  $MOSES/scripts/tokenizer/detokenizer.perl -q -l en

rm -fr $JIEBA_TMP

