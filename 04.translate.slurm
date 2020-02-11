#!/bin/sh
#SBATCH -J translate
#SBATCH -c 8
#SBATCH -n 1
#SBATCH -e /home/shared/wwaites/cirrus-scripts/logs/04.translate-%j.err
#SBATCH -o /home/shared/wwaites/cirrus-scripts/logs/04.translate-%j.out

## ARGUMENTS: lang batchno

echo Translating ${1}/${2}
/home/shared/wwaites/cirrus-scripts/04.translate "${1}" "${2}"
echo Done
