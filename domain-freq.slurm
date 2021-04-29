#!/bin/bash
set -euo pipefail

zcat $1/*/url.gz \
| sed -r 's/^(https?:)?(\/\/)?([^\/]+)(\/.*)?$/\3/' \
| sort \
| uniq -c \
| sort -nr \
| gzip -c > $1/domains.gz
