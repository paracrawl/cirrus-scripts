#!/bin/bash
export PREFIX # So it's also available in job scripts

export PYTHON=$PREFIX/bin/python
export PERL=perl
export KPU=$PREFIX/src/preprocess
export GIASHARD=$PREFIX/go/bin/giashard
export DOCALIGN=$PREFIX/bin/docalign
export DOCJOIN=$PREFIX/bin/docjoin
export CACHE=$PREFIX/bin/cache
export B64FILTER=$PREFIX/bin/b64filter
export FOLDFILTER=$PREFIX/bin/foldfilter
export TOKENISER="$PERL $KPU/moses/tokenizer/tokenizer.perl" # We're doing British English in this repo apparently.
export BLEUALIGN=$PREFIX/bin/bleualign_cpp
export SCRIPTS=$(dirname $PREFIX) # strip off the "env" part.
export BITEXTOR="$PREFIX/src/bitextor"
export MODEL_DIR="$PREFIX/../models"
export TARGET_LANG=${TARGET_LANG:-en~dedup}

export SLURM_LOGS="/home/%u/logs"
#export SBATCH_ACCOUNT=
#export SBATCH_PARTITION=

# How many tasks should be run per subjob? See also SLRUM_TASKS_PER_NODE (or TPN)
# which works in tandem with TPB. E.g. TPN says each subjob runs 10 items from
# the batch list, and TPN says allocate enough resources to rnu 2 in parallel
# inside each subjob. (If SLURM feels like it there might be multiple subjobs on
# the same compute node though.)
# Or simpler: TPB exists to keep the length of job arrays down, but also keep each
# sub job within a time limit. TPN exists to make optimal use of exclusive nodes,
# but can also be used to add parallel execution into a subjob. But if TPN is 1,
# SLURM will take care of the parallelism.
export TASKS_PER_BATCH=${TPB:-1}

# How many resources should be allocated per slurm job. Defaults
# to as many as necessary to process all tasks in parallel. Individual
# .slurm job definitions define how many cpus should be allocated per
# task.
export SLURM_TASKS_PER_NODE=${TPN:-}

