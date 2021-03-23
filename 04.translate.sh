#!/bin/bash

## create and submit the batches on csd3 for translation
set -euo pipefail

. env/init.sh
. config.sh
. functions.sh

collection=$1
shift

for lang in $*; do
	# Load in translation model config so we know MODEL_ARCH
	test -x $MODEL_DIR/${lang%~*}-${TARGET_LANG%~*}/translate.sh || (echo "No model: $MODEL_DIR/${lang%~*}-${TARGET_LANG%~*}/translate.sh" 1>&2 ; exit 255)
	batch_list=$(make_batch_list 04 $collection $lang sentences_${TARGET_LANG%~*}.gz)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			# Note that you can control --cpus-per-task from here. However, it's a bit
			# tricky to get the right value. Too many and the intgemm marian will cry
			# about running out of memory (even though you're only asking for 128mb per
			# process)
			schedule \
				-J translate-${lang%~*}-${collection} \
				-a $job_list \
				--time 24:00:00 \
				--cpus-per-task 16 \
				-e $SLURM_LOGS/04.translate-${lang%~*}-%A_%a.err \
				-o $SLURM_LOGS/04.translate-${lang%~*}-%A_%a.out \
				$SCRIPTS/generic.slurm $batch_list \
				$SCRIPTS/04.translate ${lang%~*}
		fi
	fi
done
