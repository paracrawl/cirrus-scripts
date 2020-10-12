#!/bin/bash
set -eof pipefail

export LD_LIBRARY_PATH=/rds/project/t2_vol3/rds-t2-cs107/sukanta/tools/sentencepiece/build/src:$LD_LIBRARY_PATH
MODEL=/rds/project/t2_vol3/rds-t2-cs107/sukanta/experiments/scripts/faen/separate_vocab/base.spm16k
SPM=/rds/project/t2_vol3/rds-t2-cs107/sukanta/tools/sentencepiece/build/src
CHARS=$(python2 -c 'print (u"\u200C".encode("utf8"))')
MARIAN=/rds/project/t2_vol3/rds-t2-cs107/sukanta/tools/marian-dev/build

SLANG="$1"
shift

sed 's/['"$CHARS"']//g' \
	| perl $MOSES/scripts/tokenizer/tokenizer.perl -l $SLANG -q \
	| $SPM/spm_encode --model=$MODEL/data/fa.spm.16000.model --output_format=piece \
	| $MARIAN/marian-decoder \
		-c $MODEL/config.yml \
		--mini-batch-words 4000 \
		--mini-batch 64 \
		--workspace 14000 \
		"$@" \
	| perl -pe 's/ *//g' | perl -pe 's/▁/ /g' \
	| perl $MOSES/scripts/tokenizer/detokenizer.perl -l $SLANG -q

