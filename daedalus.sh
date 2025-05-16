#!/bin/bash

# Default values
SRA_ID=""
NUM_CORES=1
MEM_GB=8
EPI_FASTA=""
READ1=""
READ2=""

# Help message
show_help() {
    echo "
Daedalus Pipeline

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
"
}

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--num-cores) NUM_CORES="$2"; shift ;;
        -m|--memory) MEM_GB="$2"; shift ;;
        -e|--epitopes) EPI_FASTA="$2"; shift ;;
        --sra) SRA_ID="$2"; shift ;;
        --read1) READ1="$2"; shift ;;
        --read2) READ2="$2"; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Check required arguments
if [ -z "$EPI_FASTA" ]; then
    echo "ERROR: Epitope FASTA file (-e) is required."
    show_help
    exit 1
fi

if [ -n "$SRA_ID" ]; then
    echo "Using SRA accession: $SRA_ID"
elif [ -n "$READ1" ] && [ -n "$READ2" ]; then
    echo "Using local FASTQ files: $READ1, $READ2"
else
    echo "ERROR: Provide either --sra <SRA_ID> or both --read1 and --read2."
    show_help
    exit 1
fi


# Handle SRA or local FASTQ
if [ -n "$SRA_ID" ]; then
    mkdir -p sra_fastq
    fasterq-dump $SRA_ID --split-files -O sra_fastq

    if [ -f "sra_fastq/${SRA_ID}_1.fastq" ] && [ -f "sra_fastq/${SRA_ID}_2.fastq" ]; then

        pigz -p $NUM_CORES -9 sra_fastq/*fastq ; SPADES_INPUT="-1 sra_fastq/${SRA_ID}_1.fastq.gz -2 sra_fastq/${SRA_ID}_2.fastq.gz"
    elif [ -f "sra_fastq/${SRA_ID}.fastq.gz" ]; then
        SPADES_INPUT="-s sra_fastq/${SRA_ID}.fastq.gz"
    else
        echo "ERROR: SRA download failed or produced no FASTQ files. Exiting."
        exit 1
    fi
else
    if [ ! -f "$READ1" ] || [ ! -f "$READ2" ]; then
        echo "ERROR: One or both local FASTQ files not found. Exiting."
        exit 1
    fi
    SPADES_INPUT="-1 $READ1 -2 $READ2"
fi

echo "Running MetaSPAdes..."
spades.py --meta $SPADES_INPUT -o spades_output -t $NUM_CORES --memory $MEM_GB

cd spades_output
echo "Running Prodigal-GV..."
python3 /home/fryan/bin/parallel-prodigal-gv.py -t $NUM_CORES -q -i scaffolds.fasta -a proteins.faa

echo "Running SeqKit epitope search..."
seqkit locate -m 1 -j $NUM_CORES --pattern-file "$EPI_FASTA" proteins.faa >> ../daedalus_results.txt

cd ..
echo "Compressing outputs..."
pigz -p $NUM_CORES -9 spades_output/*fasta spades_output/*faa spades_output/*fastg spades_output/*gfa

echo "Daedalus pipeline completed successfully!"
