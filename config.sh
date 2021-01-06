if [ -z "${PREFIX:-}" ]; then
	SELF=$(realpath "${BASH_SOURCE[0]}")
	PREFIX=$(dirname "$SELF")/env
fi

for config_file in $(dirname $(realpath "${BASH_SOURCE[0]}"))/config.d/*.sh; do
	source $config_file
done
