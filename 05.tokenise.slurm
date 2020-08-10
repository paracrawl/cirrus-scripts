#!/bin/sh
#SBATCH -J tok
#SBATCH -A t2-cs119-knl
#SBATCH -p knl
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --time 4:00:00
#SBATCH -e /home/%u/logs/05.tokenise-%A_%a.err
#SBATCH -o /home/%u/logs/05.tokenise-%A_%a.out

## ARGUMENTS: lang batch

# Inherited from submission
# . /home/$USER/src/cirrus-scripts/config.csd3

module load parallel
module load perl/5.20.0

export SLANG="${1}"
export BATCHES="${2}"
export CMD=${SCRIPTS}/05.tokenise
export THREADS=$((${SLURM_CPUS_ON_NODE} / ${TASKS_PER_BATCH}))
echo "Running $THREADS threads per task, ${TASKS_PER_BATCH} tasks"

TMPDIR=${SCRATCH}/tokenise.$$
mkdir -p ${TMPDIR} || exit 255
export TMPDIR

cleanup () {
	echo "Cleaning up scratch directory"
	rm -rf $TMPDIR
}
trap cleanup EXIT

IFS=, read GROUP_START GROUP_END <<< $(get_group_boundaries ${BATCHES} ${SLURM_ARRAY_TASK_ID})

parallel task ::: $(seq $GROUP_START $GROUP_END)
