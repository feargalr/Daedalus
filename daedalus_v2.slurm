#!/bin/bash --login
#SBATCH --job-name=daedalus_%j  
#SBATCH --output=daedalus_%j.log                       # Log file with job ID
#SBATCH --error=daedalus_%j.err                        # Error file with job ID

#SBATCH --nodes=1                                        # Request one node
#SBATCH --cpus-per-task=32                               # Number of CPU cores
#SBATCH --mem=64G                                        # Memory allocation
#SBATCH --time=16:00:00                                  # Time limit (72 hours)

# Author: Feargal J. Ryan
# Date: 2025-02-12
# GitHub: https://github.com/feargalr/
# Email: feargalr@gmail.com
# Description: Daedalus pipeline for finding cross-reactive epitopes in shotgun metagenomics data

# Activate conda environment
source /software/projects/pawsey1180/fryan/miniconda3/etc/profile.d/conda.sh
conda activate /software/projects/pawsey1180/fryan/miniconda3/envs/daedalus

# Run MetaSPAdes
spades.py --meta -1 *_1.fastq.gz -2 *_2.fastq.gz \
          -o spades_output -t 32 --memory 64

cd spades_output
python3 /home/fryan/bin/parallel-prodigal-gv.py -t 32 -q -i scaffolds.fasta -a proteins.faa

seqkit locate -m 1 -j 32 --pattern-file /home/fryan/sars_cov2_epitope.fasta proteins.faa >> daedalus_results.txt

pigz -p 32 -9 *fasta *faa *fastg *gfa
