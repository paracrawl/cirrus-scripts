function join_by {
	local IFS="$1";
	shift;
	echo "$*";
}

function confirm {
	read -p "Are you sure? " -n 1 -r
	echo 2>&1
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
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

RETRY=false

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
		--)
			shift
			break
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
