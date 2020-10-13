#!/bin/bash
set -euo pipefail
export MARIAN=/home/cs-vand1/rds/rds-t2-cs119/romang/marian-dev/build-static
export BPE=/home/cs-vand1/rds/rds-t2-cs119/romang/subword-nmt/subword_nmt
export MOSES=/home/cs-wait1/src/mosesdecoder

cd /rds/project/t2_vol4/rds-t2-cs119/cwang/nmt/home/bhaddow/experiments/paracrawl/korean/mt

python3 $BPE/apply_bpe.py \
    -c prepare06/bpe.model.ko \
| $MARIAN/marian-decoder \
    -m run12/model.npz.best-translation.npz \
    -v run12/vocab.{ko,en}.yml \
    -w 3200 \
    --optimize \
    --normalize 1 \
    --word-penalty 0 \
    --beam-size 4 \
    --mini-batch-words 300 \
    --maxi-batch 2000 \
    --maxi-batch-sort src \
    "$@" \
| perl -pe 's/@@ //g' \
|  $MOSES/scripts/recaser/detruecase.perl \
|  $MOSES/scripts/tokenizer/detokenizer.perl -q -l en