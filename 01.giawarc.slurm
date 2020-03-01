#!/bin/sh
#SBATCH -J giawarc
#SBATCH -A t2-cs119-knl
#SBATCH -p knl
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --time 36:00:00
#SBATCH -e /home/cs-wait1/logs/01.giawarc-%A_%a.err
#SBATCH -o /home/cs-wait1/logs/01.giawarc-%A_%a.out

. ./config.csd3
DATA=${DATA}/../hieu
META=${DATA}/hieu-batches
INPUT=${DATA}/hieu-warcs
TXTOUT=${DATA}/hieu-text

module load parallel

BATCH="${META}/warcs.${SLURM_ARRAY_TASK_ID}"

for f in `cat ${BATCH}`; do
	base=`echo $f | sed 's/\.gz$//'`
	rm -rf ${TXTOUT}/$base
	mkdir -p ${TXTOUT}/$base
done

echo `date +%s` `date` "Processing $BATCH"
cat ${BATCH} | sed 's/\.gz$//' | parallel -j 64 $GIAWARC -f bilang -o ${TXTOUT}/'{}' ${INPUT}/'{}'.gz
echo `date +%s` `date` "Done $BATCH"
