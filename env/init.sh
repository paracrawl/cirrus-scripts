#!/bin/bash
export PREFIX=$(dirname $(realpath "${BASH_SOURCE[0]}"))

# Also explicitly puring these (except PATH) to get rid of
# any user defined environment.
#unset INCLUDE LIB CPATH LD_LIBRARY_PATH LIBRARY_PATH
unset LD_LIBRARY_PATH

# Next, load in the system specific modules
for initfile in $PREFIX/init.d/*.sh; do
	source $initfile
done

# Finally, add our environment to the front, so it has highest priority
export GOPATH="$PREFIX/go"
export PATH="$PREFIX/bin:$GOPATH/bin:$PATH"
export INCLUDE="$PREFIX/include${INCLUDE:+:$INCLUDE}"
export LIB="$PREFIX/lib${LIB:+:$LIB}"
export CPATH="$PREFIX/include${CPATH:+:$CPATH}"
export LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
export LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="$PREFIX/lib64/pkgconfig:$PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# Note: this will make using KNL nodes a no-go
export CFLAGS="-O3 -march=native -pipe"
export CXXFLAGS="-O3 -march=native -pipe"

