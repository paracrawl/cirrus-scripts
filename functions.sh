function join_by {
	paste -sd "$1" -
}


function prompt {
	printf "$@" 1>&2
}


function confirm {
	if $ALWAYS_YES; then
		return
	fi

	if $TEST; then
		[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
	fi

	read -p "Are you sure? " -n 1 -r
	echo 1>&2
	if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
		[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	fi
}


function make_batch_list_all {
	local step="$1" collection="$2" lang="$3"
	local batch_list=${COLLECTIONS[$collection]}-batches/${step}.${lang}

	if [[ ! -d ${COLLECTIONS[$collection]}-batches ]]; then
		mkdir ${COLLECTIONS[$collection]}-batches
	fi

	if $FORCE_INDEX_BATCHES || [[ ! -f ${COLLECTIONS[$collection]}-batches/${lang} ]]; then
		find ${COLLECTIONS[$collection]}-shards/${lang} \
			-mindepth 2 \
			-maxdepth 2 \
			-type d \
			-regex '.*/[0-9]+/[0-9]+' \
			> ${COLLECTIONS[$collection]}-batches/${lang}
	fi

	rm -f ${batch_list}
	ln -s ${COLLECTIONS[$collection]}-batches/${lang} ${batch_list}

	echo ${batch_list}
}


function batch_file_is_outdated {
	local batch="$1" out_file="$2"
	shift 2

	for in_file in "$@"; do
		for match in $batch/$in_file; do
			if [[ "$match" -nt "$batch/$out_file" ]]; then
				echo "$match is newer than $batch/$out_file" > /dev/stderr
				return 0
			fi
		done
	done

	return 1
}


function make_batch_list_retry {
	local step="$1" collection="$2" lang="$3" output_file="$4" in_files="${@:5}"

	local batch_list_retry=${COLLECTIONS[$collection]}-batches/${step}.${lang}.$(date '+%Y%m%d%H%M%S')

	cat `make_batch_list_all "$@"` | while read BATCH; do
		output="${BATCH}/${output_file}"
		# Note: $in_files not quoted here because if it would be empty, that would result in an empty argument (but an argument nontheless)
		if [[ ! -e $output ]] || batch_file_is_outdated "$BATCH" "$output_file" $in_files; then
			echo "$output" 1>&2
			echo "$BATCH"
		fi
	done > $batch_list_retry

	echo ${batch_list_retry}
}


function make_batch_list {
	if $RETRY; then
		make_batch_list_retry "$@"
	else
		make_batch_list_all "$@"
	fi
}


function make_job_list {
	local n_batches=$(< "$1" wc -l)
	local n=$(( ${n_batches}%${TASKS_PER_BATCH} ? ${n_batches}/${TASKS_PER_BATCH} + 1 : ${n_batches}/${TASKS_PER_BATCH} ))
	if [ "$n" -gt 0 ]; then
		echo 1-${n}
	fi
}


function schedule {
	local options=(
		${SCHEDULE_OPTIONS[@]}
		--nodes 1
		--ntasks ${SLURM_TASKS_PER_NODE:-$TASKS_PER_BATCH}
		--verbose
		--export ALL
	)
	local job_id=$(${SBATCH:-sbatch} "${options[@]}" "$@")
	echo $(date +%Y%m%d%H%M%S) $job_id "${options[@]}" "$@" >> ./.schedule-log
	echo $job_id
}


declare -g TEST=false
declare -g RETRY=false
declare -g FORCE_INDEX_BATCHES=false
declare -g ALWAYS_YES=${ALWAYS_YES:-false}
declare -g SCHEDULE_OPTIONS=(--parsable)
declare -g STEPS=""

while (( "$#" )); do
	case "$1" in
		-f|--force)
			FORCE_INDEX_BATCHES=true
			shift
			;;
		-r|--retry)
			RETRY=true
			shift
			;;
		-t|--test)
			TEST=true
			shift
			;;
		-y|--yes)
			ALWAYS_YES=true
			shift
			;;
		-j|--threads)
			export THREADS=$2
			shift 2
			;;
		-i|--interactive)
			SBATCH=$SCRIPTS/fake-sbatch.sh
			shift
			;;
		-t|--time)
			SCHEDULE_OPTIONS=("${SCHEDULE_OPTIONS[@]}" --time "$2")
			shift 2
			;;
		--afterany)
			SCHEDULE_OPTIONS=("${SCHEDULE_OPTIONS[@]}" -d "afterany:$2")
			shift 2
			;;
		--afterok)
			SCHEDULE_OPTIONS=("${SCHEDULE_OPTIONS[@]}" -d "afterok:$2")
			shift 2
			;;
		--aftercorr)
			SCHEDULE_OPTIONS=("${SCHEDULE_OPTIONS[@]}" -d "aftercorr:$2")
			shift 2
			;;
		--mem-per-cpu)
			SCHEDULE_OPTIONS=("${SCHEDULE_OPTIONS[@]}" --mem-per-cpu $2)
			shift 2
			;;
		--exclusive)
			SCHEDULE_OPTIONS=("${SCHEDULE_OPTIONS[@]}" --exclusive)
			shift
			;;
		--steps)
			IFS='-' read -a seq_args <<< "$2"
			STEPS=$(seq ${seq_args[@]})
			shift 2
			;;
		--)
			shift
			break
			;;
		-h|--help)
			echo "Available options"
			echo "  -j | --threads n     Specify number of threads, mostly for interactive stuff."
			echo "  -t | --test          Just run all checks, don't schedule."
			echo "  -r | --retry         Retry batches for which no output was found."
			echo "  -f | --force         Force (re)scanning of shards/batches/files."
			echo "  -t | --time t	       Override walltime limit for individual jobs."
			echo "  -i | --interactive	 Run jobs here and now in this process."
			echo "  --after job-id       Run this job after prev job ended (however that happend)."
			echo "  --afterok job-id     Run this job after prev job has finished."
			echo "  --aftercorr job-id   Run each of the job array tasks after their counterpart."
			echo "                       has finished."
			if [[ $(type -t describe_cli_options) == "function" ]]; then
				describe_cli_options;
			fi
			exit 0
			;;
		-*|--*)
			# Allow each of the scheduling scripts to also define options by defining
			# a "parse_cli_option" function before including functions.sh
			if [[ $(type -t parse_cli_option) == "function" ]]; then
				parse_cli_option "$@"
			else
				echo "Uknown option $1" 1>&2
				exit 1
			fi
			;;
		*)
			break
			;;
	esac
done
