#!/bin/bash
pushd /rds/project/rds-48gU72OtDNY/paracrawl/clean/en~dedup-fr~dedup

gzip -cd en-fr.cc-2016-30-cc-2017-30-cc-2018-30-cc-2019-18-cc-2019-35-gwb-hieu-marta-philipp-wide00006-wide00015.filtered05.gz |
gawk -F $'\t' -f $HOME/src/cirrus-scripts/split-by-checksum.awk

