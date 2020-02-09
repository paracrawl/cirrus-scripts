#!/bin/sh
#SBATCH -J batch
#SBATCH -c 2
#SBATCH -n 1
#SBATCH -w dagr
#SBATCH -e /home/shared/wwaites/cirrus-scripts/logs/03.batch-%A_%a.err
#SBATCH -o /home/shared/wwaites/cirrus-scripts/logs/03.batch-%A_%a.out

## this job purposely runs on dagr to avoid unnecessary I/O

/home/shared/wwaites/cirrus-scripts/03.batch "${1}"
