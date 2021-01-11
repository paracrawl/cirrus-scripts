#!/bin/bash

if [[ "$(hostname -A)" =~ "hpc.cam.ac.uk" ]]; then
	module purge && module load \
		python/3.8 \
		perl-5.26.2-gcc-7.2.0-2ys4uai \
		cmake \
		gcc/9 \
		binutils-2.31.1-gcc-5.4.0-uyyspmn \
		intel/mkl/2020.2 \
		xz-5.2.4-gcc-7.2.0-v7gjh3h \
		openssl-1.0.2k-gcc-5.4.0-lonhprt
fi

