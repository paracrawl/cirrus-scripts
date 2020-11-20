#!/bin/bash
set -euo pipefail
PREFIX=$(dirname ${BASH_SOURCE[0]})
test -d "$PREFIX"
rm -rf \
	$PREFIX/{bin,go,include,lib,lib64,share,pyvenv.cfg} \
	$PREFIX/src/*/build \
	$PREFIX/src/boost_* \
	$PREFIX/src/gperftools-* \
	$PREFIX/src/xmlrpc-c-*

