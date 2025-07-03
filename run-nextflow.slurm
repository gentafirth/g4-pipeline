#!/bin/bash
#SBATCH --job-name=K_pneunomiae_nextflow
#SBATCH --output=slurm-nextflow.out
#SBATCH --error=slurm-nextflow.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8

module load Nextflow/24.10.2
module load Anaconda3/2024.02-1
module load gcccore/10.2.0
module load apptainer/1.0.3

nextflow run main.nf -profile hpc
