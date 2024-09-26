#!/bin/bash
set -euo pipefail

MARIAN=/opt/marian-bergamot/build
MODEL=$(dirname $(realpath -es ${BASH_SOURCE[0]}))/model

foldfilter -s -w 500 \
$MARIAN/marian-decoder \
	-c $MODEL/config.yml \
	--cpu-threads $THREADS \
	--quiet-translation \
	--max-length-crop
