#!/bin/bash
set -eou pipefail

. config.csd3
. functions.sh
. translate.sh
export -f get_group_boundaries task

job_id=$1

# Find the job we originally scheduled so we can figure out which batch list it references
log_line=$(cat .schedule-log | fgrep " ${job_id} ")

batch_list=${log_line##* }

line_without_batch_list=${log_line% *}
lang=${line_without_batch_list##* }

# Find failed array indices, group them, and merge them in something sbatch eats
job_ids=$(sacct --parsable -j $job_id | fgrep '|FAILED|' | fgrep -v '.batch|' | cut -d'|' -f1)

while read job_id; do
	echo === $job_id ===
	log_file=$HOME/logs/04.translate-$job_id.err
	if [[ -f "$log_file" ]]; then
		tail "$log_file"
	else
		echo '  no log file exists'
	fi
done <<< "$job_ids"

job_list=$(<<< "$job_ids" cut -d_ -f2 | group_ranges | join_by ,)

# Load in translation model config so we know MODEL_ARCH
eval model_${lang}_${TARGET_LANG} || (echo "No model for ${lang} -> ${TARGET_LANG}" 1>&2 ; exit 255)

if [ ! -z $job_list ]; then
    prompt "Scheduling $job_list on $MODEL_ARCH\n"
    if confirm; then
            schedule -J translate-${lang} -a $job_list 04.translate.${MODEL_ARCH}.slurm $lang $batch_list
    fi
fi
