#!/bin/bash
set -euo pipefail
INPUT_DUMP=$BATCH/gl-es.$TMPSFX.gz
ERROR_DUMP=$BATCH/gl-es.$TMPSFX.log
echo "Dumping input to $INPUT_DUMP" >&2

tee >(gzip -c > $INPUT_DUMP) \
| $SCRIPTS/bisector.py --ignore 1 \
	timeout -m 4096000 \
	$(dirname ${BASH_SOURCE[0]})/../translate-apertium.sh gl-es "$@" \
	2> >(tee $ERROR_DUMP >&2)

