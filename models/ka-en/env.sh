#!/bin/bash
export SBATCH_ACCOUNT=t2-cs119-gpu
export SBATCH_PARTITION=pascal
export SLURM_TASKS_PER_NODE=1
export SBATCH_GRES=gpu:1

