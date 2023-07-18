#!/bin/bash
set -euo pipefail

MARIAN=/projappl/project_462000252/software/marian-bergamot
MODEL=$(dirname $(realpath -es ${BASH_SOURCE[0]}))/model

foldfilter -s -w 500 \
$MARIAN/marian-decoder \
	-c $MODEL/config.intgemm8bit.alphas.yml \
	--cpu-threads $THREADS \
	--quiet-translation
