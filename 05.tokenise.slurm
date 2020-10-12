#!/bin/sh
#SBATCH -J tok
#SBATCH -c 1
#SBATCH --time 4:00:00
#SBATCH -e /home/%u/logs/05.tokenise-%A_%a.err
#SBATCH -o /home/%u/logs/05.tokenise-%A_%a.out

## ARGUMENTS: lang batch

# Inherited from submission
# . /home/$USER/src/cirrus-scripts/config.csd3

module load parallel

export SLANG="${1}"
export BATCHES="${2}"
export CMD=${SCRIPTS}/05.tokenise
export PERL=/home/cs-vand1/perl5/perlbrew/perls/perl-5.32.0/bin/perl
echo "Running $SLURM_CPU_ON_NODE threads, ${TASKS_PER_BATCH} tasks"

TMPDIR=${SCRATCH}/tokenise.$$
mkdir -p ${TMPDIR} || exit 255
export TMPDIR

chown :t2-cs119 $TMPDIR
chmod g+s $TMPDIR

cleanup () {
	echo "Cleaning up scratch directory"
	rm -rf $TMPDIR
}
trap cleanup EXIT

IFS=, read GROUP_START GROUP_END <<< $(get_group_boundaries ${BATCHES} ${SLURM_ARRAY_TASK_ID})

parallel -j$SLURM_CPUS_ON_NODE task ::: $(seq $GROUP_START $GROUP_END)
