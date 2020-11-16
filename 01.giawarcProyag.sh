#!/bin/bash
set -euo pipefail

. config.csd3
. functions.sh

# export because exported to jobs themselves
export COLLECTION=$1
export GROUP_SIZE=36 # How many warcs per job?

#function make_batch_list {
#	local batch_list=$DATA/$COLLECTION-batches/01
#
#	# Get all downloaded warcs as warc-name :space: path.
#	if [ -e $batch_list ]; then
#		find $DATA/$COLLECTION-warcs/ -name '*.warc.gz' \
#			| awk '
#				function basename(file) {
#					sub(".*/", "", file)
#					sub(".warc.gz", "", file)
#					return file
#				}
#		    	{ print basename($1), $1 }' \
#			| sort > $batch_list
#	fi
#
#	if $RETRY ; do
#		# List all already processed warcs
#		processed=$(ls -1 $DATA/$COLLECTION-text/ | sort)
#
#		# Get me the names of everything that is downloaded but not processed
#		warcs_todo=$(comm -23 <(cut -d' ' -f1 < $batch_list) <(cat <<< "$processed"))
#
#		# Get all rows from downloaded that are in todo, and extract the paths
#		join <(cat <<< "$warcs_todo") $batch_list \
#			| cut -d' ' -f2 \
#			> $DATA/$COLLECTION-batches/$step.$$
#		
#		# Set the batch-list to the pruned one
#		batch_list=$DATA/$COLLECTION-batches/$step.$$
#	fi
#
#	echo $batch_list
#}

function make_batch_list {
	local batch_list_prefix=${DATA}/${COLLECTION}-batches/warcs

	if [ ! -e ${batch_list_prefix}.00001 ]; then
		pushd ${DATA}/${COLLECTION}-warcs
		find . -name '*.warc.gz' \
		| split --numeric-suffixes=1 -a5 -l${GROUP_SIZE} - ${batch_list_prefix}.
		popd
	fi

	echo ${batch_list_prefix}
}

function make_job_list {
	#local line_count=$(wc -l $1 | cut -d' ' -f1)
	#local group_count=$(( $line_count / $GROUP_SIZE + 1)) # plus 1 to round up
	#echo 1-$group_count
	echo 1-$(find ${DATA}/${COLLECTION}-batches -name 'warcs.?????' | wc -l)
}

export BATCH_LIST=$(make_batch_list)
job_list=$(make_job_list $BATCH_LIST)

if [ ! -z $job_list ]; then
	prompt "Scheduling $job_list \n"
	if confirm; then
		sbatch -J giawarc-wide00006-pdf --array=${job_list} ./01.giawarc.slurm
		#qsub -J $job_list -v "COLLECTION,GROUP_SIZE,BATCH_LIST" ./01.giawarc.pbs
	fi
fi
