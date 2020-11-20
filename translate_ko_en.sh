#!/bin/bash
set -euo pipefail

cd /rds/project/t2_vol4/rds-t2-cs119/cwang/nmt/home/bhaddow/experiments/paracrawl/korean/mt

python3 $BPE/apply_bpe.py \
    -c prepare06/bpe.model.ko \
| $MARIAN/marian-decoder \
    -m run12/model.npz.best-translation.npz \
    -v run12/vocab.{ko,en}.yml \
    -w 3000 \
    --optimize \
    --normalize 1 \
    --word-penalty 0 \
    --beam-size 4 \
    --mini-batch-words 3000 \
    --maxi-batch 4000 \
    --maxi-batch-sort src \
    --shortlist /home/cs-vand1/src/cirrus-scripts/lex.koen.gz \
    "$@" \
| perl -pe 's/@@ //g' \
|  $MOSES/scripts/recaser/detruecase.perl \
|  $MOSES/scripts/tokenizer/detokenizer.perl -q -l en
