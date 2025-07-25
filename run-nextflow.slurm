#!/bin/bash
#SBATCH --job-name=K_pneunomiae_nextflow
#SBATCH --output=slurm-nextflow.out
#SBATCH --error=slurm-nextflow.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=1
# #SBATCH --mem=64G

module load Nextflow/24.10.2
module load Miniforge3/24.7.1-2

nextflow run main.nf -resume -profile hpc
