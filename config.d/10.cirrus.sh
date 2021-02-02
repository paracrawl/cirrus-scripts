if [[ "$(hostname)" =~ "cirrus" ]]; then
	function bicleaner_model {
		echo "bicleaner models not set up" 1>&2
		exit 1
	}

	# Note: may need to split this for warcs and processed data, I don't
	# want to fill commoncrawl folders with processing data.
	declare -A COLLECTIONS=(
		["wide00015"]="/beegfs/paracrawl/data/ia/wide00015"
		["cc-2016-30"]="/beegfs/paracrawl/data/common_crawl/CC-MAIN-2016-30"
		["cc-2017-30"]="/beegfs/paracrawl/data/common_crawl/CC-MAIN-2017-30"
		["cc-2018-30"]="/beegfs/paracrawl/data/common_crawl/CC-MAIN-2018-30"
		["cc-2019-18"]="/beegfs/paracrawl/data/common_crawl/CC-MAIN-2019-18"
		["cc-2019-35"]="/beegfs/paracrawl/data/common_crawl/CC-MAIN-2019-35"
	)

	export SLURM_LOGS="$HOME/logs"

	# Where jobs should be executed. Values used in functions.sh/schedule.
	export SBATCH_ACCOUNT=ec166-guest
	export SBATCH_PARTITION=standard
	export SBATCH_QOS=standard
fi

