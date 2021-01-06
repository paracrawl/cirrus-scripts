#!/bin/bash

if [[ "$(hostname -A)" =~ "hpc.cam.ac.uk" ]]; then
	module purge && module load \
		python/3.8 \
		perl-5.26.2-gcc-7.2.0-2ys4uai \
		gcc/9 \
		cmake \
		intel/mkl/2020.2 \
		openssl-1.0.2k-gcc-5.4.0-lonhprt \
		binutils-2.31.1-gcc-5.4.0-uyyspmn
fi

