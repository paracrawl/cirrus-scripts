#!/usr/bin/bash
set -euo pipefail

source init.sh

# Note: this will not make anything that works with KNL though
export CFLAGS="-O3 -march=native -pipe"
export CXXFLAGS="-O3 -march=native -pipe"

USE_GO=false
BUILD_PYTHON="test ! -x $PREFIX/bin/python"
BUILD_SUBWORD="test ! -x $PREFIX/bin/subword-nmt"
BUILD_JIEBA="test ! -d $PREFIX/lib/python3.8/site-packages/jieba"
BUILD_MARIAN_CPU="test ! -x $PREFIX/bin/marian-decoder-cpu";
BUILD_PROTOBUF="command_not_exists protoc"
BUILD_PERFTOOLS="test ! -d $PREFIX/include/gperftools"
BUILD_BOOST="test ! -d $PREFIX/include/boost"
BUILD_BLEUALIGN="test ! -x $PREFIX/bin/bleualign_cpp"
BUILD_DOCALIGN="test ! -x $PREFIX/bin/docalign"
BUILD_PREPROCESS="test ! -x $PREFIX/bin/b64filter"

command_not_exists() {
	if command -v "$@" &>/dev/null; then
		return 1
	else
		return 0
	fi
}

for name in python subword jieba marian_cpu protobuf perftools boost bleualign docalign preprocess; do
	printf "Building $name: "
	varname="BUILD_${name^^}"
	if ${!varname}; then
		echo yes
	else
		echo no
	fi
done

mkdir -p $PREFIX/{bin,lib,include,share}

 # Here for legacy reasons
if $USE_GO; then
	export GOPATH=$PREFIX/go
	go get github.com/paracrawl/giawarc/cmd/giawarc
	go get github.com/paracrawl/giashard/cmd/giashard
fi

if $BUILD_PYTHON; then
	python3 -m venv $PREFIX
fi

if $BUILD_SUBWORD; then
	pip3 install subword-nmt
fi

if $BUILD_JIEBA; then
	pip3 install jieba
fi

pushd src

# Google Protobuf (this will take forever for some reason)

if $BUILD_PROTOBUF; then
	test -d protobuf-3.13.0 || curl -L https://github.com/protocolbuffers/protobuf/releases/download/v3.13.0/protobuf-cpp-3.13.0.tar.gz | tar -zx

	pushd protobuf-3.13.0

	./configure --prefix $PREFIX
	make -j8
	make install

	popd
fi

# Google Perftools (for tcmalloc I guess)
if $BUILD_PERFTOOLS; then
	test -d gperftools-2.8 || curl -L https://github.com/gperftools/gperftools/releases/download/gperftools-2.8/gperftools-2.8.tar.gz | tar -zx

	pushd gperftools-2.8

	./configure --prefix $PREFIX
	cat Makefile | sed 's,\bcp -p\b,cp,g' > Makefile.patched
	make -f Makefile.patched -j8
	make -f Makefile.patched install

	popd
fi

if $BUILD_BOOST; then
	test -d boost_1_74_0 || curl -L https://dl.bintray.com/boostorg/release/1.74.0/source/boost_1_74_0.tar.gz | tar -zx

	pushd boost_1_74_0

	./bootstrap.sh --prefix=$PREFIX
	./b2 install

	popd
fi

# Marian optimised for CPU
if $BUILD_MARIAN_CPU; then
	pushd marian-fbgemm/

	git submodule update --init --recursive

	mkdir -p build && cd build

	cmake ..\
		-DCMAKE_INSTALL_PREFIX=$PREFIX \
		-DUSE_FBGEMM=ON \
		-DUSE_SENTENCEPIECE=ON \
		-DCOMPILE_CUDA=OFF \
		-DUSE_STATIC_LIBS=ON

	make -j8
	make install
	
	# Note that make install did not install marian's executables in bin. That's
	# okay, since we'll be needing different versions of marian anyway.
	cp marian-decoder $PREFIX/bin/marian-decoder-cpu
	cp marian-conv $PREFIX/bin/marian-conv

	# spm_train is broken due to USE_STATIC_LIBS so let's move it to prevent
	# shooting ourselves in the foot.
	rm -f $PREFIX/bin/spm_train

	popd # leave marian
fi

if $BUILD_BLEUALIGN; then
	pushd bitextor/bleualign-cpp

	mkdir -p build && cd build

	cmake .. \
		-DCMAKE_INSTALL_PREFIX=$PREFIX
	make -j8 bleualign_cpp
	cp libbleualign_cpp_lib.so $PREFIX/lib/
	cp bleualign_cpp $PREFIX/bin/
	chrpath -d $PREFIX/bin/bleualign_cpp

	popd
fi

if $BUILD_DOCALIGN; then
	pushd bitextor/document-aligner

	mkdir -p build && cd build

	cmake .. \
		-DCMAKE_INSTALL_PREFIX=$PREFIX \
		-DBUILD_TESTING=OFF
	make -j8 docalign docjoin
	cp bin/* $PREFIX/bin/

	popd
fi

# Using preprocess stand-alone, not the one shipped with bitextor
# since it's lagging behind a bit at the moment.
if $BUILD_PREPROCESS; then
	pushd preprocess

	mkdir -p build && cd build

	cmake .. \
		-DCMAKE_INSTALL_PREFIX=$PREFIX
	make -j8
	cp bin/* $PREFIX/bin/
	
	popd
fi

popd # move out of src
