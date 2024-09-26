if [[ $(hostname -A) =~ "uan"[0-9][0-9] ]]; then
	module purge
	module load LUMI/23.09
    #module load Boost/1.81.0-cpeCray-23.03 # This must be changed if boost version changes in env/setup.d/paracrawl
	#module purge && module load \
	#	PrgEnv-cray/8.3.3 \
	#	craype-x86-milan \
	#	cray-python/3.9.12.1 \
	#	perftools-base/22.12.0

	# Recommended options in lumi docs: https://docs.lumi-supercomputer.eu/development/compiling/prgenv/#wrapper-and-compiler-options
	# for cray compiler
	# gnu compiler in lumi throws a warning when loading it, saying it is not recommended
	# according to https://docs.lumi-supercomputer.eu/development/compiling/prgenv/#choosing-the-target-architecture
	# instead of specifying -march, craype-x86-milan module has to be loaded for LUMI-C partitions
	export CFLAGS="-O2 -funroll-loops -ffast-math"
	export CXXFLAGS="-O2 -funroll-loops -ffast-math"
	export IS_LUMI=true

	#export PATH="/pfs/lustrep1/projappl/project_462000252/zaragoza/test_env/conda_env/bin:$PATH"
	#export PATH="/pfs/lustrep1/projappl/project_462000252/zaragoza/bitextor-8.1/bin:$PATH"

	export SQUEUE_FORMAT="%.18i %.9P %.20j %.8u %.2t %.10M %.6D %R"
fi
