#!/bin/bash

# Takes as input a language code (2-letter) and a file with a list of sentences 
# detects the sentence language (using fasttext's large model) and keeps only lines (sentences) of the input language code
# The output is saved in file 00_input_file
# ARGS:
#   1   language_code [default: "bg"]
#   2   sentences_filename [default: "test_input.txt"]
# Usage:
#   . 00.detect_lang.sh bg senteces.txt
#
# Variables that need to be declared elsewhere
# alias ftext=/home/cs-sifa1/fastText/fasttext
# export WIDE_15=/rds/project/t2_vol4/rds-t2-cs119/internet_archive/wide00015-shards
# export LargeDetectionModel=/home/cs-sifa1/fastText/lang_detection/lib.176.bin
# export SmallDetectionModel=/home/cs-sifa1/fastText/lang_detection/lib.176.ftz

DOCLANG=${1:-"bg"}
FILE_IN=${2:-"test_input.txt"}
echo $DOCLANG , $FILE_IN
paste "$FILE_IN" <(/home/cs-sifa1/fastText/fasttext predict /home/cs-sifa1/fastText/lang_detection/lid.176.bin "$FILE_IN")\
            | sed -r "s/__label__//" \
                        | gawk -F$"\t" -v DLANG="$DOCLANG" '{if ($2==DLANG) {print $1}}' 

