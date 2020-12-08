#!/bin/bash
set -euo pipefail

# GROUP_SIZE is specified by submission script
GROUP_END=$(($GROUP_SIZE * $SLURM_ARRAY_TASK_ID)) # Slurm starts counting at 1
GROUP_START=$(($GROUP_END - $GROUP_SIZE))

GNU_PARALLEL=/lustre/sw/gnu-parallel/20170322/bin/parallel

trap "exit" INT TERM
trap "kill 0" EXIT

task () {
    set -euo pipefail
    local batch=$1
    local output=/beegfs/paracrawl/data/ia/wide00015-text/$(basename $(dirname $batch))/$(basename $batch .warc.gz)
    mkdir -p $output.$$
    $HOME/bin/giawarc -o $output.$$ $batch
    mv $output.$$ $output
}

#mpstat 30 > $HOME/logs/01.giawarc-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.stat &
#stat_pid=$!

export -f task

awk "NR>${GROUP_START}&&NR<=${GROUP_END}" "$BATCH_LIST" \
| $GNU_PARALLEL -j${SLURM_CPUS_ON_NODE} task '{}'

#kill $stat_pid

