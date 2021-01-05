if [[ "$(hostname -A)" =~ "hpc.cam.ac.uk" ]]; then
	# For translating to Spanish
	export APERTIUM=/rds/project/rds-48gU72OtDNY/jelmervdl/apertium

	# For Pashto (not paracrawl)
	export MARIAN=/rds/project/rds-48gU72OtDNY/romang/marian-dev/build-static
	export BPE=/rds/project/rds-48gU72OtDNY/romang/subword-nmt/subword_nmt
	export JIEBA="/rds/project/rds-48gU72OtDNY/jelmervdl/jieba/bin/python -m jieba"

	export LD_LIBRARY_PATH=$APERTIUM/lib:/home/cs-wait1/sw/lib:$LD_LIBRARY_PATH
	export PERL=/home/cs-vand1/perl5/perlbrew/perls/perl-5.32.0/bin/perl
	export MODELS=/rds/project/rds-48gU72OtDNY/models
	
	# Use wwaites moses2 since I haven't been able to compile it succesfully yet.
	export MOSES=$PREFIX/src/mosesdecoder
	export MOSES_BIN=/home/cs-wait1/src/mosesdecoder/bin/moses2

	export DATA_CLEANING=/rds/project/rds-48gU72OtDNY/internet_archive/cleaning
	
	# Works better this way.
	export SCRATCH=/local

	function bicleaner_model {
		local lang=$1

		export BIFIXER_PARAMS="--aggressive_dedup -q"
		export BICLEANER=$PREFIX/bin/bicleaner-classify-lite
		export BICLEANER_THRESHOLD="0.7"
		export BICLEANER_PARAMS="--score_only -q"

		if [[ $lang == 'ko' ]] || [[ $lang == 'zh' ]]; then
			export BIFIXER_PARAMS="\
				$BIFIXER_PARAMS \
				--ignore_characters \
				--ignore_long \
				--ignore_orthography \
				--ignore_segmentation"
			export BICLEANER="python ${HOME}/rds/rds-t2-cs119-48gU72OtDNY/cwang/bicleaner/codes/bicleaner/bicleaner/bicleaner_classifier_full.py"
			export BICLEANER_PARAMS="\
				$BICLEANER_PARAMS \
				--processes 2 \
			" \
			export BICLEANER_THRESHOLD=0.4
		fi

		if [[ $lang == 'ko' ]]; then
			export BICLEANER_MODEL="${HOME}/rds/rds-t2-cs119-48gU72OtDNY/cwang/bicleaner/model/korean/${TARGET_LANG}-${lang}.yaml"
		elif [[ $lang == 'zh' ]]; then
			export BICLEANER_MODEL="${HOME}/rds/rds-t2-cs119-48gU72OtDNY/cwang/bicleaner/model/chinese/${TARGET_LANG}-${lang}.yaml"
		else
			# Default path: here instead of in config.csd3 because path depends on $lang and the exceptions
			# above don't follow this pattern very well, which is why it's not in the 09.clean code itself.
			export BICLEANER_MODEL=/rds/project/rds-48gU72OtDNY/cleaning/bicleaner-models/${TARGET_LANG}-${lang}/${TARGET_LANG}-${lang}.yaml
		fi
	}

	COLLECTION_ROOT="/rds/project/rds-48gU72OtDNY"
	declare -A COLLECTIONS=(
		["wide00006"]="$COLLECTION_ROOT/internet_archive/wide00006"
		["wide00015"]="$COLLECTION_ROOT/internet_archive/wide00015"
		["hieu"]="$COLLECTION_ROOT/hieu/hieu"
	)

	# Where jobs should be executed. Values used in functions.sh/schedule.
	export SBATCH_ACCOUNT=t2-cs119-knl
	export SBATCH_PARTITION=knl

	export SBATCH_ACCOUNT=t2-cs119-cpu
	export SBATCH_PARTITION=cclake,skylake
	export TASKS_PER_BATCH=${TPB:-1}

	# How many resources should be allocated per slurm job. Defaults
	# to as many as necessary to process all tasks in parallel. Individual
	# .slurm job definitions define how many cpus should be allocated per
	# task.
	export SLURM_TASKS_PER_NODE=${TPN:-}
fi

