#!/bin/bash
export PREFIX=$(dirname $(realpath "${BASH_SOURCE[0]}"))

# Also explicitly puring these (except PATH) to get rid of
# any user defined environment.
#unset INCLUDE LIB CPATH LD_LIBRARY_PATH LIBRARY_PATH
#unset LD_LIBRARY_PATH

# Next, load in the system specific modules
for initfile in $PREFIX/init.d/*.sh; do
	source $initfile
done

module rm bzip2-1.0.6-gcc-5.4.0-xsgsccp
module rm rhel7/global
module rm rhel7/default-gpu
module rm cmake/latest
module rm cmake-3.19.7-gcc-5.4-5gbsejo
module rm gcc-5.4.0-gcc-4.8.5-fis24gg
module add gcc
module add parallel

# Finally, add our environment to the front, so it has highest priority
export GOPATH="$PREFIX/go"
export PATH="$PREFIX/bin:$GOPATH/bin:$PATH"
export INCLUDE="$PREFIX/include${INCLUDE:+:$INCLUDE}"
export LIB="$PREFIX/lib${LIB:+:$LIB}"
export CPATH="$PREFIX/include${CPATH:+:$CPATH}"
export LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
export LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="$PREFIX/lib64/pkgconfig:$PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

#module add libiconv/1.16/gcc/4miyzf3w
module add libiconv/1.16
module add bzip2

export PATH=$PATH:$HOME/.local/bin
