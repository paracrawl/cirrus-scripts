#!/bin/bash
set -euo pipefail
INPUT_DUMP=$BATCH/ca-es.$TMPSFX.gz
ERROR_DUMP=$BATCH/ca-es.$TMPSFX.log
echo "Dumping input to $INPUT_DUMP" >&2

tee >(gzip -c > $INPUT_DUMP) \
| $SCRIPTS/bisector.py 4 \
	$(dirname ${BASH_SOURCE[0]})/../translate-apertium.sh cat-spa "$@" \
	2> >(tee $ERROR_DUMP >&2)

