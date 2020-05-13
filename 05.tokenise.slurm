#!/bin/sh
#SBATCH -J tok
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
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

SLANG="${1}"
BATCHES="${2}"
TOKENISE=${SCRIPTS}/05.tokenise
BATCH=`head -${SLURM_ARRAY_TASK_ID} ${BATCHES} | tail -1`

TMPDIR=${SCRATCH}/tokenise.$$
mkdir -p ${TMPDIR} || exit 255
export TMPDIR

cleanup () {
	echo "Cleaning up scratch directory"
	rm -rf $TMPDIR
}
trap cleanup EXIT

echo `date` "Starting whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"

/bin/time -f "%E %M" ${TOKENISE} ${SLANG} "${BATCH}"

echo `date` "Done whole node job ${SLURM_ARRAY_TASK_ID} on ${HOSTNAME}"
