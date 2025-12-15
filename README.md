# Daedalus

Like its namesake, Daedalus builds things. This pipeline was built for metagenomic assembly and the identification of cross-reactive epitopes. Daedalus is a wrapper pipeline that orchestrates several established bioinformatics tools, and so we *strongly encourage* users cite the underlying software components appropriately in any resulting publications.


## **Overview**
**Daedalus** is a bioinformatics pipeline that assembles metagenomes, predicts genes, and identifies cross-reactive epitopes from metagenomic data. It integrates:

- **SRA-Tools** - for downloading sequenceing data from the SRA (optional)
- **fastp** - for read quality control and filtering
- **nohuman**- for remove of human reads
- **MetaSPAdes** – for assembly  
- **Prodigal-GV** – for gene prediction  
- **SeqKit** – for searching epitope sequences  
- **Pigz** – for compressing output  

Everything is wrapped into a single executable: daedalus. You can simply give daedalus an SRA ID and it will return a list of epitopes identified in that sample post-assembly.

## **Pipeline Workflow**

1. **Input acquisition**
   - Download reads from the SRA using `fasterq-dump`, or
   - Use local paired-end FASTQ files.

2. **Read quality control**
   - Quality filtering and adapter trimming using **fastp**.

3. **Host read removal**
   - Removal of human reads using **nohuman**. Please see the [nohuman GitHub repository](https://github.com/mbhall88/nohuman) for the most up-to-date recommendations on which database to use.
4. **Metagenomic assembly**
   - Assembly of filtered reads using **MetaSPAdes**.

5. **Gene prediction**
   - Prediction of protein-coding genes using **Prodigal-GV**.

6. **Epitope search**
   - Identification of epitope matches in predicted proteins using **SeqKit**.

7. **Output compression**
   - Compression of large intermediate and final outputs using **pigz**.

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

# After activating the conda environment, install the `daedalus` executable into the environment:

cp daedalus "$CONDA_PREFIX/bin/daedalus"

#For multi-threaded gene prediction use the parallel-prodigal-gv.py script available here
git clone https://github.com/apcamargo/prodigal-gv
#Then copy or symlink `parallel-prodigal-gv.py` to your `$PATH`, or edit the path in `daedalus.sh` to match your setup.

#Ensure the nohuman db location is either specified with the flag or set at the $NOHUMAN_DB variable.

```

## **Usage**
```bash
Usage:
  daedalus -e <epitope_fasta> -n <num_cores> -m <memory_gb> [--sra <SRA_ID>] [--read1 <read1.fastq.gz> --read2 <read2.fastq.gz>]

Flags:
  -e, --epitopes      Path to epitope FASTA file (required)
  -n, --num-cores     Number of cores (default: 1)
  -m, --memory        Memory in GB (default: 8)
  --sra <SRA_ID>      SRA accession ID (optional)
  --read1 <file>      Path to local R1 FASTQ file (required if no SRA)
  --read2 <file>      Path to local R2 FASTQ file (required if no SRA)
  --nohuman-db <path>   Path to nohuman database (or set $NOHUMAN_DB)
  -h, --help          Show this help message
  -V, --version       Print version and exit

Notes:
- If --sra is provided, local --read1 and --read2 are ignored.
- If no SRA is provided, both --read1 and --read2 must be specified.

Examples:
  daedalus --sra SRR123456 -e epitopes.fasta -n 32 -m 64
  daedalus --read1 sample_1.fastq.gz --read2 sample_2.fastq.gz -e epitopes.fasta -n 16 -m 32
```

## **Inputs**
- **Epitope FASTA**: Required – a list of peptide sequences to search for.
- **SRA accession** *or* paired FASTQ files: Provide one or the other.

## **Output**
- `sra_fastq/`: SRA downloaded files.
- `fastp_output/`: Quality filtered reads and nohuman removed reads.
- `spades_output/`: Contains assembled scaffolds and protein predictions.
- `all_matches.txt`: List of matched epitopes and corresponding genes allowing for one mismatch.
- `epitope_counts.txt`: Count of number of exact matches greater than length 4.

