# Daedalus
Like its namesake, Daedalus assembles things. This pipeline was built for metagenomic assembly and the identification of cross-reactive epitopes.

## **Overview**
**Daedalus** is a bioinformatics pipeline that assembles metagenomes, predicts all genes, and identifies cross-reactive epitopes from metagenomic data. It integrates **MetaSPAdes** for assembly, **Prodigal-GV** for gene prediction, and **SeqKit** for epitope sequence searches.  

## **Pipeline Workflow**
1. **Metagenomic Assembly** – Uses **MetaSPAdes** to assemble raw sequencing reads.  
2. **Gene Prediction** – Predicts all genes using **Prodigal-GV**.  
3. **Epitope Search** – Uses **SeqKit** to scan predicted genes for known cross-reactive epitope sequences.  

## **Installation**
### **1. Clone the Repository**
```bash
git clone https://github.com/yourusername/Daedalus.git
cd Daedalus
```

### **2. Install dependencies**
```bash
conda env create -f daedalus_env.yml
conda activate daedalus

#For multi-threaded gene prediction use the parallel-prodigal-gv.py script available here
git clone https://github.com/apcamargo/prodigal-gv
```
