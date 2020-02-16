#!/bin/sh
#SBATCH -J shard
#SBATCH -c 2
#SBATCH -n 1
#SBATCH -w dagr
#SBATCH -e /home/shared/wwaites/logs/03.batch-%j.err
#SBATCH -o /home/shared/wwaites/logs/03.batch-%j.out

## this job purposely runs on dagr to avoid unnecessary I/O

## Arguments: lang collection batches

SLANG="${1}"
COLL="${2}"
shift; shift

. /home/shared/wwaites/cirrus-scripts/config.valhalla

for batch in $*; do
	items=`< $batch sed -e 's@^@'${DATA}/${COLLECTION}-text@ -e 's@$@'${SLANG}@`
	giashard -n 8 -b 1024 -o ${DATA}/${COLLECTION}-shards/${SLANG} $items
done
