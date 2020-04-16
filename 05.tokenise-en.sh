#!/bin/sh

## create and submit the batches on csd3 for translation
set -euo pipefail

. ./config.csd3
. ${SCRIPTS}/functions.sh

collection=$1
shift

lang=en
batch_list=$(make_batch_list 05 $collection $lang)
job_list=$(make_job_list $batch_list tokenised.gz)
echo $job_list
confirm
sbatch --nice=500 -J tok-${lang} -a $job_list 05.tokenise-en.slurm $batch_list
