#!/bin/bash
PS1="(paracrawl) [\u@\h \W]\$ " bash --init-file $(dirname ${BASH_SOURCE[0]})/init.sh "$@"
