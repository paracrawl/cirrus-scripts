#!/bin/bash

if [[ "$(hostname -A)" =~ "hpc.cam.ac.uk" ]]; then
	# Removed because Ugh!
	# python/3.8 `# this thing comes with a whole load of libs & headers...` \
	module purge && module load \
		rhel7/global \
		slurm \
		parallel \
		perl-5.26.2-gcc-7.2.0-2ys4uai \
		cmake \
		gcc/8 `# CUDA10.2 can't deal with gcc > 8` \
		binutils-2.31.1-gcc-5.4.0-uyyspmn `# Nick: newer binutils is better` \
		intel/mkl/2020.2 \
		cuda/10.2 `# Marian doesn't support 11 properly yet` \
		xz-5.2.4-gcc-7.2.0-v7gjh3h `# liblzma` \
		openssl-1.0.2k-gcc-5.4.0-lonhprt
fi

