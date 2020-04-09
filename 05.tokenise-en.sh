#!/bin/sh

## create and submit the batches on csd3 for translation
set -euo pipefail

. ./config.csd3

function join_by {
	local IFS="$1";
	shift;
	echo "$*";
}

collection=$1
shift

RETRY=false

if [[ $1 == "-r" ]]; then
	RETRY=true
	shift
fi

lang=en
if ! test -d ${DATA}/${collection}-batches/${lang}; then
	ls -d ${DATA}/${collection}-shards/${lang}/*/* > ${DATA}/${collection}-batches/${lang}
fi
rm -f ${DATA}/${collection}-batches/05.${lang}
ln -s ${DATA}/${collection}-batches/${lang} ${DATA}/${collection}-batches/05.${lang}

if [ RETRY ]; then
	indices=()
	line=0
	while read batch; do
		line=$(($line + 1))
		if [ ! -e ${batch}/tokenised.gz ]; then
			indices+=($line)
		fi
	done < ${DATA}/${collection}-batches/05.${lang}   
	joblist=$(join_by , ${indices[@]})
else
	n=`< ${DATA}/${collection}-batches/05.${lang} wc -l`
    joblist=1-${n}
fi
	
sbatch -a $joblist 05.tokenise-en.slurm ${DATA}/${collection}-batches/05.${lang}
