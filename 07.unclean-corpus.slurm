#!/bin/bash
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --time 8:00:00
#SBATCH -e /home/%u/logs/07.unclean-corpus-%A.err
#SBATCH -o /home/%u/logs/07.unclean-corpus-%A.out

set -euo pipefail

collection=$1
lang=$2

DEST=${DATA}/${collection}-corpora/${collection}-unclean.${TARGET_LANG}-${lang}.gz
cat ${DATA}/${collection}-batches/${lang} \
| while read batch; do
	for match in ${batch}/aligned-[0-9].gz; do
		echo $match 1>&2
		paste <(gzip -cd ${match} \
				| cut -f1-2 \
				| docjoin \
					-r ${DATA}/${collection}-shards/${TARGET_LANG}/$(basename $(dirname $batch))/$(echo $match | sed 's/.*-\([0-9]*\)\.gz/\1/')/url.gz \
					-l $(dirname ${match})/url.gz) \
			  <(gzip -cd $match | cut -f4) \
			  <(gzip -cd $match | cut -f3) \
			  <(gzip -cd $match | cut -f5-)
	done
done \
| gzip -c > $DEST.$$

mv $DEST.$$ $DEST
