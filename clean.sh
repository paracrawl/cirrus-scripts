#!/bin/bash
#SBATCH --account t2-cs119-cpu
#SBATCH --partition cclake,skylake
#SBATCH --nodes 1
#SBATCH --verbose
#SBATCH --exclusive
#SBATCH --time 12:00:00

set -euxo pipefail

. $HOME/src/cirrus-scripts/env/init.sh
. $HOME/src/cirrus-scripts/config.csd3

module load parallel

###

THREADS=$SLURM_CPUS_ON_NODE
lang=ko
TARGET_LANG=en

###

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

BIFIXER=bifixer

BIFIXER_PARAMS="\
	--aggressive_dedup \
	--ignore_characters \
	--ignore_long \
	--ignore_orthography \
	--ignore_segmentation"

BICLEANER="python ${HOME}/rds/rds-t2-cs119-48gU72OtDNY/cwang/bicleaner/codes/bicleaner/bicleaner/bicleaner_classifier_full.py"

BICLEANER_PARAMS="--score_only"

if [[ $lang == 'ko' ]]; then
	BICLEANER_MODEL="/rds/project/rds-48gU72OtDNY/cwang/bicleaner/model/korean/${TARGET_LANG}-${lang}.yaml"
elif [[ $lang == 'zh' ]]; then
	BICLEANER_MODEL="/rds/project/rds-48gU72OtDNY/cwang/bicleaner/model/chinese/${TARGET_LANG}-${lang}.yaml"
else
	BICLEANER_MODEL="/rds/project/rds-48gU72OtDNY/cleaning/bicleaner-models/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.yaml"
	BICLEANER_PARAMS="--aggressive_dedup"
	BICLEANER=bicleaner-classify
fi

BICLEANER_THRESHOLD=0.4

# part of https://github.com/kpu/preprocess
PREPROCESS_CACHE=cache

# https://github.com/sortiz/tmxt/tree/master
# pip install -r tmxt/requirements.txt
TMXT=tmxt

NAME=${TARGET_LANG}-${lang}

FIXED=/local/${NAME}.fixed.txt.$$
trap "rm -f $FIXED" EXIT

CLASSIFIED=${NAME}.classified.gz
FILTERED=${NAME}.filtered${BICLEANER_THRESHOLD/./}.gz

# Extract unclean corpus and put it through bifixer
pigz -cd $@ \
| cut -f 1-4 \
| $BIFIXER - - $TARGET_LANG $lang $BIFIXER_PARAMS \
> $FIXED

# Take bifixed corpus, run it through bicleaner
cat $FIXED \
| $PREPROCESS_CACHE -k 3,4 $BICLEANER $BICLEANER_PARAMS - - $BICLEANER_MODEL \
| paste $FIXED - \
| tee >(pigz -c > $CLASSIFIED.$$ && mv $CLASSIFIED.$$ $CLASSIFIED) \
| awk -F"\t" "\$7 >= ${BICLEANER_THRESHOLD}" \
| LC_ALL=C sort -t$'\t' -k5,5 -k6,6nr -T $TMPDIR --parallel=$THREADS -S 80% \
| python $BITEXTOR/bitextor-elrc-filtering.py -c "url1,url2,seg1,seg2,bifixerhash,bifixerscore,bicleaner" -s \
| tee >(pigz -c > $FILTERED.$$ && mv $FILTERED.$$ $FILTERED) \
| PYTHONPATH=$BITEXTOR python ${SCRIPTS}/bitextor-buildTMX.py \
	--lang1 ${TARGET_LANG} --lang2 ${lang} \
	-c "url1,url2,seg1,seg2,bifixerhash,bifixerscore,bicleaner,lengthratio,numTokensSL,numTokensTL" \
	--dedup "bifixerhash" \
| tee >(pigz > ${NAME}.tmx.gz.$$ && mv ${NAME}.tmx.gz.$$ ${NAME}.tmx.gz) \
| $TMXT --codelist=${TARGET_LANG},${lang} \
| pigz > ${NAME}.txt.gz.$$ && mv ${NAME}.txt.gz.$$ ${NAME}.txt.gz
