#!/bin/bash
#
# Usage: sbatch generic.slurm BATCH_LIST COMMAND [ ARGS ]
#
# Executes COMMAND for TASKS_PER_BATCH lines from BATCH_LIST. Will
# run up to SLURM_TASKS_PER_NODE (i.e. --ntasks) task in parallel
# to support local parallelism (and not overload slurm with more
# jobs to schedule.) Itwill also try to determine how many cpu
# cores can be used by COMMAND based on how many cores are available
# and how many tasks we're executing in parallel. Never less than
# what was passed in as --cpus-per-task (default: 1) (i.e. it might
# overprovision this node if SLURM_TASKS_PER_NODE * SLURM_CPUS_PER_TASK
# is larger than $SLURM_CPUS_ON_NODE, but if Slurm behaves correctly
# this will never be the case.
#
# Assumes the following environment variables:
# - TASKS_PER_BATCH
# - SLURM_TASKS_PER_NODE
# - SLURM_CPUS_ON_NODE
# - SLURM_CPUS_PER_TASK
# - SLURM_ARRAY_TASK_I
#
# Provides to COMMAND:
# - THREADS
# - TMPDIR (on $SCRATCH)
# - line from BATCH_LIST as last argument to COMMAND
#

set -euo pipefail

BATCHES=$1
shift

# Try to make/take the most of this node.
AVAILABLE_THREADS=$(( $SLURM_CPUS_ON_NODE / $SLURM_TASKS_PER_NODE ))
THREADS=${SLURM_CPUS_PER_TASK:-$AVAILABLE_THREADS}
export THREADS=$(( $THREADS > 1 ? $THREADS : 1 ))

# $SCRATCH is not set on Cirrus. $TMPDIR on Cirrus is shared-memory.
if [ ! -z "${SCRATCH:-}" ]; then
	SCRATCH_BASED_TMPDIR=${SCRATCH}/$(basename "$1").$$
	mkdir -p ${SCRATCH_BASED_TMPDIR} || exit 255
	export TMPDIR=$SCRATCH_BASED_TMPDIR

	chown :rds-48gU72OtDNY-users $SCRATCH_BASED_TMPDIR
	chmod g+s $SCRATCH_BASED_TMPDIR

	cleanup () {
		echo "Cleaning up scratch director $SCRATCH_BASED_TMPDIR"
		rm -rf $SCRATCH_BASED_TMPDIR
	}
	trap cleanup EXIT
fi

GROUP_END=$(( $TASKS_PER_BATCH * $SLURM_ARRAY_TASK_ID ))
GROUP_START=$(( $GROUP_END - $TASKS_PER_BATCH ))

awk "NR > $GROUP_START && NR <= $GROUP_END" $BATCHES \
| parallel -j${SLURM_TASKS_PER_NODE} --line-buffer --colsep " " "$@" "{}"
