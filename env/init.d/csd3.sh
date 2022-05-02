#!/bin/bash

#if [[ "$(hostname -A)" =~ "hpc.cam.ac.uk" ]]; then
#	# Removed because Ugh!
#	# python/3.8 `# this thing comes with a whole load of libs & headers...` \
#	module purge && module load \
#		rhel7/global \
#		slurm \
#		perl-5.26.2-gcc-7.2.0-2ys4uai \
#		cmake \
#		gcc/8 `# CUDA10.2 can't deal with gcc > 8` \
#		binutils-2.31.1-gcc-5.4.0-uyyspmn `# Nick: newer binutils is better` \
#		intel/mkl/2020.2 \
#		cuda/10.1 `# TF 2.3.2 needs cuda 10.1` \
#		cudnn/7.6_cuda-10.1 `# Needed for TF` \
#		openssl-1.0.2k-gcc-5.4.0-lonhprt
#
#	# Target lowest common denominator on CSD3: the GPU nodes
#	export CFLAGS="-O2 -ftree-vectorize -funroll-loops -ffast-math -march=broadwell"
#	export CXXFLAGS="-O2 -ftree-vectorize -funroll-loops -ffast-math -march=broadwell"
#fi
#
