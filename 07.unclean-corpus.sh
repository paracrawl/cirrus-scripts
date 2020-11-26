#!/bin/bash
set -euo pipefail

. config.csd3
. functions.sh

collection=$1
shift

for lang in $*; do
	schedule -J corpus-$lang $SCRIPTS/07.unclean-corpus.slurm $collection $lang
	# bash 07.unclean-corpus.slurm $collection $lang
done

