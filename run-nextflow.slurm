#!/bin/bash
#SBATCH --job-name=bacterial_nextflow_pipeline
#SBATCH --output=slurm-nextflow.out
#SBATCH --error=slurm-nextflow.err
#SBATCH --time=120:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G

module load Nextflow/24.10.2
module load Miniforge3/24.7.1-2

nextflow run main.nf -resume -profile hpc --species 'S_pneumoniae'
