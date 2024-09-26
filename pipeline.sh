#!/bin/bash
set -euo pipefail

STEPS=(
	"04.translate.sh"
	"05.tokenise.sh"
	"06.align.sh"
	"07.fix.sh"
	"08.score.sh"
	"09.clean.sh"
)

CURRENT_QUEUE=$(squeue -u$USER -h -o '%j %F' | LC_ALL=C sort | uniq)

log() {
	local format="%s\n"

	if [[ $# > 0 ]] && [[ $1 == "-n" ]]; then
		format="%s"
		shift
	fi

	printf "$format" "$@" 1>&2
}

prefix() {
	local prefix_value=$1
	shift

	for el in $@; do
		echo $prefix_value $el
	done
}

format-dependency() {
	if [[ $# > 1 ]]; then
		printf -- "%s %d" $1 $2
		shift 2
		for job_id in $@; do
			printf ":%d" $job_id
		done
		printf "\n"
	fi
}

find_job_id() {
	set -euo pipefail
	local name=$(echo $1 | cut -d. -f2)
	<<< "$CURRENT_QUEUE" fgrep "${name}-${2}" | cut -d' ' -f2
}

schedule() {
	echo "> " "$@" >&2
	ALWAYS_YES=true "./$1" "${@:2}"
}

schedule_batch_jobs() {
	set -euo pipefail

	local collection=$1
	local language=$2

	local last_job_id=""
	for step in ${STEPS[@]}; do
		log "Step $step for $collection/$language"
		last_job_id=$(find_job_id $step ${language}-${collection} || schedule $step --retry $(format-dependency --afterok $last_job_id) $collection $language)
		log ": $last_job_id"
	done

	echo $last_job_id
}

main() {
	set -euo pipefail

	local lang=$1
	shift

	local collections=($(./collections.sh -gwb))

	#case $lang in
	#	ca|eu|gl|oc)
	#		export TARGET_LANG=es
	#		;;
	#	en|ga|hr|is|nn|no|nb)
	#		collections=(${collections[@]} gwb)
	#		;;
	#esac

	for collection in ${collections[@]}; do
		job_id=$(schedule_batch_jobs $collection $lang)
		batch_jobs=(${batch_jobs[@]:-} $job_id)
	done

	for step in 10.reduce-classified.sh 11.reduce-filtered.sh; do
		log "Step $step for $lang:"
		job_id=$(find_job_id $step $lang || schedule $step $(format-dependency --afterok ${batch_jobs[@]:-}) $lang ${collections[@]})
		log ": $job_id"
		lang_jobs=(${lang_jobs[@]:-} $job_id)
	done

	for step in 12.reduce-tmx.sh; do
		log "Step $step for $lang:"
		find_job_id $step $lang || schedule $step $(format-dependency --afterok ${lang_jobs[@]:-}) $lang ${collections[@]}
	done
}

main $@
