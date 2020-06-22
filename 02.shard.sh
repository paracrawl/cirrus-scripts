#!/bin/bash
. ./functions.sh
. ./config.csd3

COLLECTION=$1
shift

for lang in $*; do
	schedule -J shard-${lang} $SCRIPTS/02.shard.slurm $COLLECTION $lang
done
