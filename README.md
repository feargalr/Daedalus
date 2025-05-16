# Daedalus

Like its namesake, Daedalus builds things. This pipeline was built for metagenomic assembly and the identification of cross-reactive epitopes.

## **Overview**
**Daedalus** is a bioinformatics pipeline that assembles metagenomes, predicts genes, and identifies cross-reactive epitopes from metagenomic data. It integrates:

- **MetaSPAdes** – for assembly  
- **Prodigal-GV** – for gene prediction  
- **SeqKit** – for searching epitope sequences  

Everything is wrapped into a single command-line script: `daedalus.sh`.

## **Pipeline Workflow**
1. **Metagenomic Assembly**  
   Uses MetaSPAdes to assemble sequencing reads (from SRA ID or local FASTQs).

2. **Gene Prediction**  
   Predicts genes using a parallel version of Prodigal-GV.

3. **Epitope Search**  
   Scans predicted proteins for epitope matches using SeqKit.

## **Installation**

### **1. Clone the repository**
```bash
git clone https://github.com/feargalr/Daedalus.git
cd Daedalus
```

### **2. Install dependencies**
```bash
conda env create -f daedalus_env.yml
conda activate daedalus

#For multi-threaded gene prediction use the parallel-prodigal-gv.py script available here
git clone https://github.com/apcamargo/prodigal-gv
Then copy or symlink `parallel-prodigal-gv.py` to your `$PATH`, or edit the path in `daedalus.sh` to match your setup.
```

## **Usage**
```bash
Usage:
  bash daedalus.sh -e <epitope_fasta> -n <num_cores> -m <memory_gb> [--sra <SRA_ID>] [--read1 <read1.fastq.gz> --read2 <read2.fastq.gz>]

Flags:
  -e, --epitopes      Path to epitope FASTA file (required)
  -n, --num-cores     Number of cores (default: 1)
  -m, --memory        Memory in GB (default: 8)
  --sra <SRA_ID>      SRA accession ID (optional)
  --read1 <file>      Path to local R1 FASTQ file (required if no SRA)
  --read2 <file>      Path to local R2 FASTQ file (required if no SRA)
  -h, --help          Show this help message

Notes:
- If --sra is provided, local --read1 and --read2 are ignored.
- If no SRA is provided, both --read1 and --read2 must be specified.

Examples:
  bash daedalus.sh --sra SRR123456 -e epitopes.fasta -n 32 -m 64
  bash daedalus.sh --read1 sample_1.fastq.gz --read2 sample_2.fastq.gz -e epitopes.fasta -n 16 -m 32
```

## **Inputs**
- **Epitope FASTA**: Required – a list of peptide sequences to search for.
- **SRA accession** *or* paired FASTQ files: Provide one or the other.

## **Output**
- `spades_output/`: Contains assembled scaffolds and protein predictions.
- `daedalus_results.txt`: List of matched epitopes.

## **Notes**
- SRA downloads are handled via `fasterq-dump`.
- Intermediate and final files are compressed with `pigz` for efficiency.
