#!/bin/bash
#SBATCH --job-name=K_pneunomiae_nextflow
#SBATCH --output=slurm-nextflow.out
#SBATCH --error=slurm-nextflow.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8

module load Nextflow/24.10.2
module load Miniconda3/23.10.0-1

nextflow run main.nf -profile hpc
