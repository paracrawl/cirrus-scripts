#!/bin/bash
set -euo pipefail

source $(dirname ${BASH_SOURCE[0]})/init.sh "$@"
export PREFIX

red="\e[0;91m"
blue="\e[0;94m"
expand_bg="\e[K"
blue_bg="\e[0;104m${expand_bg}"
red_bg="\e[0;101m${expand_bg}"
green_bg="\e[0;102m${expand_bg}"
green="\e[0;92m"
white="\e[0;97m"
bold="\e[1m"
uline="\e[4m"
reset="\e[0m"

command-exists() {
	# Tests if a command/program is callable (i.e it exists in $PATH)
	command -v "$@" &>/dev/null
}

function-exists() {
	# Tests if a function is defined in this bash session
	declare -f -F $1 > /dev/null
	return $?
}

python-package-exists() {
	# Tests if the default python has a package installed (without loading it)
	test -x $PREFIX/bin/python \
	&& $PREFIX/bin/python -c "import sys,pkgutil; sys.exit(0 if pkgutil.find_loader('$1') else 1)"
}

contains() {
	local needle=$1
	shift
	for hay in "$@"; do
		if [[ $needle = $hay ]]; then
			return 0
		fi
	done
	return 1
}

module-path() {
	if [[ "$1" =~ '/' ]]; then
		echo $1
	else
		echo $PREFIX/setup.d/$1
	fi
}

run-module() {
	set -euo pipefail

	local module=$1
	shift

	unset -f depends is-installed install
	source $(module-path $module)

	if ! function-exists install; then
		echo "No install function in script for $module." >&2
		exit 1
	fi

	if ! function-exists depends; then
		depends() {
			true
		}
	fi

	if ! function-exists is-installed; then
		is-installed() {
			false
		}
	fi

	case "$1" in
		install)
			(set -euo pipefail; cd $PREFIX/src && install "${@:2}")
			;;
		*)
			eval "$@"
			;;
	esac
}

list-modules() {
	find $PREFIX/setup.d/ -mindepth 1 -maxdepth 1 -type f -iregex '.*/[a-z0-9][a-z0-9\-]*$' -printf '%f\n'
}

list-dependencies() {
	# Prints all "X depends on Y" pairs that the modules declare. Does so
	# recursively (but with loop detection).
	set -euo pipefail

	local module=$1
	local visited=($@)
	shift

	# At least we depend on ourself being installed.
	echo $module $module
	
	for dependency in $(run-module $module depends); do
		if ! contains $dependency ${visited[@]}; then
			echo $module $dependency
			visited=(${visited[@]} $dependency)
			list-dependencies $dependency ${visited[@]}
		fi
	done
}

list-dependency-graph() {
	# Generates a list of dependencies sorted in leaf-first order
	set -euo pipefail

	for module in $@; do
		list-dependencies $module
	done \
	| tsort \
	| tac
}

list-status() {
	list-modules \
	| while read module; do
		if run-module $module is-installed; then
			status="installed"
		else
			status="not installed"
		fi
		printf "%s: %s\n" $module "$status"
	done \
	| sort \
	| cut -f1-
}

install-modules() {
	set -euo pipefail

	local force=false
	local dryrun=false

	while getopts "df" opt; do
		case "$opt" in
			f)
				force=true
				;;
			d)
				dryrun=true
				;;
			\?)
				echo "Usage: $0 install [ -h ] [ -f ] <package>"
				echo " -h     print this message"
				echo " -d     dry run, don't actually do anything"
				echo " -f     do not check if already installed"
				exit 0
				;;
			:)
				echo "Invalid option -${opt}" 1>&2
				exit 1
				;;
		esac
	done

	shift $((OPTIND - 1))

	list-dependency-graph $@ \
	| while read module; do
		if ! run-module $module is-installed || ($force && [[ " $@ " =~ " $module " ]] ); then
			if ! $dryrun ; then
				printf "${green}%s${reset} is installing...\n" $module >&2
				run-module $module install
			else
				printf "${green}%s${reset} will be installed\n" $module >&2
			fi
		else
			printf "${green}%s${reset} is already installed\n" $module >&2
		fi
	done
}

install-all() {
	install-modules $@ $(list-modules)
}

shell() {
	echo -n "> "
	while read -a commands; do
		eval ${commands[@]}
		echo
		echo -n "> "
	done
}

case "$1" in
	install)
		install-modules ${@:2}
		;;
	install-all)
		install-all
		;;
	list)
		list-modules
		;;
	status)
		list-status
		;;
	*)
		echo "Usage: $0 list|install|install-all" >&2
		exit 1
		;;
esac

