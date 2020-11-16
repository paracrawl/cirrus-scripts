#!/bin/bash
file1=${1:-ref_text.txt}
file2=${2:-hyp_text.txt}
USE_SPLIT=${3:-0}
ref_basename=$(basename --suffix=.txt $file1)
hyp_basename=$(basename --suffix=.txt $file2)
export DOCENC=/home/cs-sifa1/sw/bitextor-jelmer/document-aligner/build/bin/docenc
export BLEUALIGN=/home/cs-sifa1/sw/bleualign-cpp/build/bleualign_cpp
export KPU=/home/cs-sifa1/sw/preprocess
​
# split sentences
if [ $USE_SPLIT -eq "0" ]; then
    # remove newline characters, encode to base64 and compress
    cat $file1 | tr '\n' ' ' | $DOCENC | gzip -c > $ref_basename.b64.gz
    cat $file2 | tr '\n' ' ' | $DOCENC | gzip -c > $hyp_basename.b64.gz
    . 03.split-text_manual en $ref_basename.b64.gz
    . 03.split-text_manual en $hyp_basename.b64.gz
else
    # text is already split into sentences, just encode and zip
    cat $file1 | $DOCENC | gzip -c > sentences.$ref_basename.b64.gz
    cat $file2 | $DOCENC | gzip -c > sentences.$hyp_basename.b64.gz
fi
​
#    $ref_basename \
#    $hyp_basename \
# prepare for bleualing
echo $hyp_basename$'\t'$ref_basename | \
    paste -d$'\t' \
        - \
        <(gzip -cd sentences.$hyp_basename.b64.gz)  \
        <(gzip -cd sentences.$ref_basename.b64.gz) \
        <(gzip -cd sentences.$hyp_basename.b64.gz) \
    > for_alignment.tab  
# bluealign
​
$BLEUALIGN --bleu-threshold 0.2 < for_alignment.tab > aligned.tab
# connect documents
​
# calculate WER score
python3 calc_wer_metric.py \
       --reference <($DOCENC -d sentences.$ref_basename.b64.gz) \
       --ocr_text <($DOCENC -d sentences.$hyp_basename.b64.gz) \
    #    --debug