#!/bin/sh
#SBATCH -J giawarc
#SBATCH -A t2-cs119-cpu
#SBATCH -p skylake
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --time 1:00:00
#SBATCH -e /home/cs-pal1/logs/01.giawarc-%A_%a.err
#SBATCH -o /home/cs-pal1/logs/01.giawarc-%A_%a.out

. ./config.csd3
#DATA=${DATA}/../hieu
META=${DATA}/${COLLECTION}-batches
INPUT=${DATA}/${COLLECTION}-warcs
TXTOUT=${DATA}/${COLLECTION}-text

module load parallel

BATCH="${META}/warcs.$(printf %05d ${SLURM_ARRAY_TASK_ID})"

for f in `cat ${BATCH}`; do
	base=`echo $f | sed 's/\.gz$//'`
	rm -rf ${TXTOUT}/$base
	mkdir -p ${TXTOUT}/$base
done

echo `date +%s` `date` "Processing $BATCH"
cat ${BATCH} | sed 's/\.gz$//' | parallel -j 64 $GIAWARC -f bilang -o ${TXTOUT}/'{}' ${INPUT}/'{}'.gz
echo `date +%s` `date` "Done $BATCH"
