PREFIX=$(dirname $(realpath "${BASH_SOURCE[0]}"))

module purge

# Also explicitly puring these (except PATH) to get rid of
# any user defined environment.
#unset INCLUDE LIB CPATH LD_LIBRARY_PATH LIBRARY_PATH
unset LD_LIBRARY_PATH

module load \
	python/3.8 \
	perl-5.26.2-gcc-7.2.0-2ys4uai \
	gcc/9 \
	cmake \
	intel/mkl/2020.2 \
	protobuf-3.4.0-gcc-5.4.0-zkpendv \
	openssl-1.0.2k-gcc-5.4.0-lonhprt \
	binutils-2.31.1-gcc-5.4.0-uyyspmn

export PATH="$PREFIX/bin:$PATH"
export INCLUDE="$PREFIX/include${INCLUDE:+:$INCLUDE}"
export LIB="$PREFIX/lib${LIB:+:$LIB}"
export CPATH="$PREFIX/include${CPATH:+:$CPATH}"
export LIBRARY_PATH="$PREFIX/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
