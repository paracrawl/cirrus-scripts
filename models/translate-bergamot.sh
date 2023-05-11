#!/bin/bash
set -euo pipefail

MARIAN=/projappl/project_462000252/software/marian-bergamot
MODEL=$(dirname $(realpath -es ${BASH_SOURCE[0]}))/model

$MARIAN/marian-decoder \
	-c $MODEL/config.yml \
	--cpu-threads $THREADS \
	--quiet-translation
