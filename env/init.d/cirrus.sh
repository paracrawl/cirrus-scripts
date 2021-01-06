#!/bin/bash

if [[ "$(hostname)" =~ "cirrus" ]]; then
	module load \
		cmake \
		gcc/8.2.0
fi
