#!/bin/bash
. ./functions.sh
. ./config.csd3

COLLECTION=$1
shift

for lang in $*; do
	schedule -J check-${lang} $SCRIPTS/99.check.slurm $COLLECTION $lang
done
