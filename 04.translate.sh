#!/bin/bash

## create and submit the batches on csd3 for translation
set -euo pipefail

. env/init.sh
. config.sh
. functions.sh

collection=$1
shift

for lang in $*; do
	# Make sure we know how to translate this language pair
	test -x $MODEL_DIR/${lang%~*}-${TARGET_LANG%~*}/translate.sh || (echo "No model: $MODEL_DIR/${lang%~*}-${TARGET_LANG%~*}/translate.sh" 1>&2 ; exit 255)

	# Optionally load any env overrides for this model (mostly SBATCH_CPUS_PER_TASK, but also difference between cpu/gpu models)
	if [[ -f $MODEL_DIR/${lang%~*}-${TARGET_LANG%~*}/env.sh ]]; then
		source $MODEL_DIR/${lang%~*}-${TARGET_LANG%~*}/env.sh
	fi

	batch_list=$(make_batch_list 04 $collection $lang sentences_${TARGET_LANG%~*}.gz)
	job_list=$(make_job_list $batch_list)
	if [ ! -z $job_list ]; then
		prompt "Scheduling $job_list\n"
		if confirm; then
			schedule \
				-J translate-${lang%~*}-${collection} \
				-a $job_list \
				--cpus-per-task=${SBATCH_CPUS_PER_TASK:-16} \
				--time 24:00:00 \
				-e $SLURM_LOGS/04.translate-${lang%~*}-%A_%a.err \
				-o $SLURM_LOGS/04.translate-${lang%~*}-%A_%a.out \
				$SCRIPTS/generic.slurm $batch_list \
				$SCRIPTS/04.translate ${lang%~*}
		fi
	fi
done
