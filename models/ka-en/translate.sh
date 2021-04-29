#!/bin/bash
set -euo pipefail

#Upgrade to CUDA 10.1 (the default is 8.0)
if [ ${#CUDA_INSTALL_PATH} != 0 ]; then
  module switch cuda/8.0 cuda/10.1
fi

#Upgrade to a newer cmake
module add cmake-3.14.0-gcc-5.4.0-2sblxi6
module add boost-1.66.0-gcc-5.4.0-slpq3un
module add intel/mkl/2019.1
module add gperf-3.0.4-gcc-5.4.0-noi4rwb
module add protobuf-3.4.0-gcc-5.4.0-zkpendv
module add python-3.6.2-gcc-5.4.0-me5fsee

#Set your compiler to optimize by default
export CFLAGS="-O3 -march=native -pipe"
export CXXFLAGS="-O3 -march=native -pipe"

#tcmalloc makes Marian faster
export INCLUDE=/rds/project/t2_vol3/rds-t2-cs107/heafield/perftools/include${INCLUDE:+:$INCLUDE}
export LIB=/rds/project/t2_vol3/rds-t2-cs107/heafield/perftools/lib${LIB:+:$LIB}
export CPATH=/rds/project/t2_vol3/rds-t2-cs107/heafield/perftools/include${CPATH+:$CPATH}
export LIBRARY_PATH=/rds/project/t2_vol3/rds-t2-cs107/heafield/perftools/lib${LIBRARY_PATH:+:$LIBRARY_PATH}
export LD_LIBRARY_PATH=/rds/project/t2_vol3/rds-t2-cs107/heafield/perftools/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
module add protobuf-3.4.0-gcc-5.4.0-zkpendv

source /rds/project/t2_vol3/rds-t2-cs107/sukanta/experiments/scripts/kaen/run01/translate.sh
translate_marian ka -d $CUDA_VISIBLE_DEVICES --quiet-translation
