function join_by {
	local IFS="$1";
	shift;
	echo "$*";
}


function prompt {
	printf "$@" 1>&2 
}


function confirm {
	read -p "Are you sure? " -n 1 -r
	echo 1>&2
	if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	fi
}


function make_batch_list {
	local step="$1" collection="$2" lang="$3"

	if ! test -d ${DATA}/${collection}-batches/${lang}; then
		ls -d ${DATA}/${collection}-shards/${lang}/*/* > ${DATA}/${collection}-batches/${lang}
	fi

	rm -f ${DATA}/${collection}-batches/${step}.${lang}
	ln -s ${DATA}/${collection}-batches/${lang} ${DATA}/${collection}-batches/${step}.${lang}

	echo ${DATA}/${collection}-batches/${step}.${lang}
}


function make_job_list_all {
	n=`< $1 wc -l`
    echo 1-${n}
}


function make_job_list_retry {
	local batch_list="$1" file="$2"
	local -a indices=()
	local line=0
	while read batch; do
		line=$(($line + 1))
		if [ ! -e ${batch}/${file} ]; then
			echo ${batch}/${file} 1>&2
			indices+=($line)
		fi
	done < ${batch_list}
	if [ ${#indices[@]} -gt 0 ]; then
		join_by , ${indices[@]}
	fi
}


function make_job_list {
	if $RETRY; then
		make_job_list_retry "$@"
	else
		make_job_list_all "$@"
	fi
}


function schedule {
	local job_id=$(sbatch "${SCHEDULE_OPTIONS[@]}" "$@")
	echo $(date +%Y%m%d%H%M%S) $job_id "${SCHEDULE_OPTIONS[@]}" "$@" >> ./.schedule-log
	echo $job_id
}


function is_marked_valid {
	local marker=".validated-$1"
	local batch="$2"
	shift 2

	local latest_file=$(cd "$batch"; ls -1t "$@" | head -n1)
	if [ -z "$latest_file" ] || [ $batch/$latest_file -nt $batch/$marker ]; then
		return 1
	else
		return 0
	fi
}


function mark_valid {
	local marker=".validated-$1"
	local batch="$2"
	touch "$batch/$marker"
}


declare -g RETRY=false
declare -g SCHEDULE_OPTIONS=(--parsable)

while (( "$#" )); do
	case "$1" in
		-r|--retry)
			RETRY=true
			shift
			;;
		-j|--threads)
			THREADS=$2
			shift 2
			;;
		-t|--time)
			SCHEDULE_OPTIONS=("${SCHEDULE_OPTIONS[@]}" --time "$2")
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
		--)
			shift
			break
			;;
		-h|--help)
			echo "Available options"
			echo "  -j | --threads n     Specify number of threads, mostly for interactive stuff."
			echo "  -r | --retry         Retry batches for which no output was found."
			echo "  -t | --time t	     Override walltime limit for individual jobs."
			echo "  --afterok job-id     Run this job after prev job has finished."
			echo "  --aftercorr job-id   Run each of the job array tasks after their counterpart."
			echo "                       has finished."
			exit 0
			;;
		-*|--*)
			echo "Uknown option $1" 1>&2
			exit 1
			;;
		*)
			break
			;;
	esac
done
