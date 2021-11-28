if [[ "$(hostname -A)" =~ "hpc.cam.ac.uk" ]]; then
        module add bzip2-1.0.6-gcc-5.4.0-xsgsccp

	# Use faster perl
	export PERL=/home/cs-vand1/perl5/perlbrew/perls/perl-5.32.0/bin/perl

	export DATA_CLEANING=/rds/project/rds-48gU72OtDNY/paracrawl/clean

        # https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.189.bin
	export FASTTEXT_LANGID=/rds/project/rds-48gU72OtDNY/heafield/lid.189.bin
	
	# Should be /local but this is broken in CSD3 icelake
	export SCRATCH=/ramdisks

	function bicleaner_model {
		local lang=$1

		export BIFIXER_PARAMS="--aggressive_dedup -q"
		export BICLEANER=$PREFIX/bin/bicleaner-classify-lite
		export BICLEANER_THRESHOLD="0.5"
		export BICLEANER_PARAMS="-q" # --score_only is always supplied

		# Default path: here instead of in config.csd3 because path depends on $lang and the exceptions
		# above don't follow this pattern very well, which is why it's not in the 09.clean code itself.
		export BICLEANER_MODEL=/rds/project/rds-48gU72OtDNY/cleaning/bicleaner-models/${TARGET_LANG%~*}-${lang%~*}/${TARGET_LANG%~*}-${lang%~*}.yaml
	}


	function bicleaner_ai_model {
		local lang=$1

		export BIFIXER_PARAMS="--aggressive_dedup -q"
		export BICLEANER=$PREFIX/bin/bicleaner-ai-classify
		export BICLEANER_THRESHOLD="0.5"
		export BICLEANER_PARAMS="-q"
		export BICLEANER_MODEL=/rds/project/rds-48gU72OtDNY/jelmervdl/bicleaner-models/full/${TARGET_LANG%~*}-${lang%~*}/metadata.yaml
	}

	COLLECTION_ROOT="/rds/project/rds-48gU72OtDNY"
	declare -A COLLECTIONS=(
		["wide00016"]="$COLLECTION_ROOT/paracrawl/data/ia/wide00016"
		["wide00015"]="$COLLECTION_ROOT/paracrawl/data/ia/wide00015"
		["wide00006"]="$COLLECTION_ROOT/paracrawl/data/ia/wide00006"
		["hieu"]="$COLLECTION_ROOT/paracrawl/data/hieu/hieu"
		["gwb"]="$COLLECTION_ROOT/paracrawl/data/ia/GWB-20191109192916"
		["philipp"]="$COLLECTION_ROOT/paracrawl/data/philipp/philipp"
		["cc-2016-30"]="$COLLECTION_ROOT/paracrawl/data/common_crawl/CC-MAIN-2016-30"
		["cc-2017-30"]="$COLLECTION_ROOT/paracrawl/data/common_crawl/CC-MAIN-2017-30"
		["cc-2018-30"]="$COLLECTION_ROOT/paracrawl/data/common_crawl/CC-MAIN-2018-30"
		["cc-2019-18"]="$COLLECTION_ROOT/paracrawl/data/common_crawl/CC-MAIN-2019-18"
		["cc-2019-35"]="$COLLECTION_ROOT/paracrawl/data/common_crawl/CC-MAIN-2019-35"
		#["merged"]="$COLLECTION_ROOT/paracrawl/data/merged/merged"
		["marta"]="$COLLECTION_ROOT/paracrawl/data/marta/marta"
		["pdf"]="$COLLECTION_ROOT/paracrawl/data/pdf/pdf"
	)

	# Where jobs should be executed. Values used in functions.sh/schedule.
	export SBATCH_ACCOUNT=t2-cs119-cpu
	export SBATCH_PARTITION=icelake
	export TASKS_PER_BATCH=${TPB:-1}

	# How many resources should be allocated per slurm job. Defaults
	# to as many as necessary to process all tasks in parallel. Individual
	# .slurm job definitions define how many cpus should be allocated per
	# task.
	export SLURM_TASKS_PER_NODE=${TPN:-1}
fi

