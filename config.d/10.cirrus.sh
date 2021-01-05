if [[ "$(hostname)" =~ "cirrus" ]]; then
	function bicleaner_model {
		echo "bicleaner models not set up" 1>&2
		exit 1
	}

	# Note: may need to split this for warcs and processed data, I don't
	# want to fill commoncrawl folders with processing data.
	declare -A COLLECTIONS=(
		["wide00015"]="/beegfs/paracrawl/data/ia/wide00015"
	)

	export SLURM_LOGS="$HOME/logs"

	# Where jobs should be executed. Values used in functions.sh/schedule.
	export SBATCH_ACCOUNT=dc007
	export SBATCH_PARTITION=paracrawl
	export SBATCH_QOS=paracrawl
fi

