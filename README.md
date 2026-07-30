# PseuMO-Tag Decoder
**PseuMO-Tag**: <ins>**Pseu**</ins>do-<ins>**M**</ins>ulti<ins>**O**</ins>mics and cell <ins>**Tag**</ins>ging<br>

The development of this analysis tool is described in the following [preprint](https://doi.org/10.1101/2025.05.24.655549).

**Tutorial By Kenichi Miyata, JFCR**  

---
!["PseuMO-Tag"](images/Fig.1a.png)
---

## 0. Setting up the analysis environment
We recommend creating a Conda environment to install the required packages for PseuMO-Tag Decoder.  
After installing and configuring Conda, create an environment for the PseuMO-Tag decoding workflow using the commands below.

```bash
# Create a new Conda environment and install all necessary packages
conda create -n pseumo python=3.7 parallel pigz r-heatmap3 cutadapt starcode fastqc seqkit bowtie2 samtools matplotlib pandas -c bioconda -y

# Install additional tools using Homebrew (for macOS users)
brew install lolcat figlet
```

Now you can run PseuMO-Tag Decoder as long as the `pseumo` environment is activated:

```bash
conda activate pseumo
```

---

# 1. scRNA-seq

The following one-step package requires only 5 files.

1. Fastq/${sampleName}_R1.fastq.gz
2. Fastq/${sampleName}_R2.fastq.gz
3. Ref/AllowList_HashTag.txt
4. Ref/AllowList_PseuTag.txt
5. Ref/CB.txt
```shell:
% head Ref/AllowList_HashTag.txt
SCR
% head Ref/AllowList_PseuTag.txt
GGCGTATTCC
GGGAATGTTA
AGACACCTTC
CAAGTGTAGA
TAAAGGGGCG
TAGGCTAACT
ATGAACGGAT
CATTGGTCCG
CGCCACGTCA
CGGCACCCAG
% head Ref/CB.txt
AAACCCAAGCAAATCA-1
AAACCCAAGCACTAGG-1
AAACCCAAGCGCCGTT-1
AAACCCAAGCGGTAAC-1
AAACCCAAGCTGACAG-1
AAACCCAAGTGAACAT-1
AAACCCAAGTGGATAT-1
AAACCCACAATTAGGA-1
AAACCCACAATTCTTC-1
AAACCCACATATCTCT-1
```

### one-step package
```shell:
bash PseuMO_Decoder.sh --sampleName ${sampleName} --AnalyzerDir $AnalyzerDir
```
**Requied**
- --sampleName - Sample name. If the Amplicon's FastQ file name is "20240111Amp-ARI3-02_S6_R1/2.fastq.gz", the sample name is "20240111Amp-ARI3-02_S6". Please place Amplicon's FastQ files (R1 & R2) in the "Fastq" directory.
- --AnalyzerDir - Directory Containing Analysis Pipelines.

**Options**
- --nCores - Number of cores. Default: 10

---


## 2. Amplicon-seq (gDNA)
### Directory: `PseuMO-Tag_28bp_v1`
### Step 1) Extraction of PseuMO-Tag barcode sequences (`NNNGTNNNCTNNNAGNNNTGNNNCANNN`)
Extract high-quality and pattern-matched barcodes from Amplicon-seq data. No error correction is performed.  

For example: Only the underlined Ssequences remain.  
`GTCGAGGCAGGAAACAGCTATGACTATGCA`<ins>**NNNGTNNNCTNNNAGNNNTGNNNCANNN**</ins>`TGCATCGTTGAGCAATAA`

Prepare `Fastq/[sampleName]_R1.fastq.gz` and `sample_list.txt` in the current directory.

```bash
conda activate pseumo
bash ${code_dir}/PseuTag_Processor_v2.sh --sampleList sample_list.txt
```

### **Required Arguments**
- `--sampleList` (default: `sample_list.txt`, optional)  
  List of sample names. If the FastQ file name is `20240111Amp-ARI3_S6_R1.fastq.gz`, the sample name should be `20240111Amp-ARI3_S6`.  

```bash
$ tree
.
├── Fastq
│   ├── cont1_S3_R1.fastq.gz
│   └── cont2_S4_R1.fastq.gz
└── sample_list.txt
```
```bash
$ cat sample_list.txt
cont1_S3
cont2_S4
```

### **Options**
- `--help` - Show usage information

---

### Step 2) Create count matrix of PseuMO-Tag barcode sequences
1. Combine multiple PseuTag text files (AFTER running `PseuTag_Processor.sh`).
2. Perform error correction on the merged data across all samples.
3. Create a count matrix for PseuTag barcodes.

```bash
bash ${code_dir}/mtxGenerator/PseuTag_mtxGenerator_v3.sh \
  --sampleList sample_list.txt \
  --resultFile results.csv \
  --analysisDir ${code_dir}/mtxGenerator
```

### **Required Arguments**
- `--sampleList` (default: `sample_list.txt`, optional)  
  List of samples.
- `--resultFile` (default: `results.csv`, optional)  
  Name of the output file. Count matrix (Raw reads) of PseuMO-Tag barcode sequences (rows) per sample (columns)
- `--analysisDir` (default: `/Volumes/Shared/Miyata/Epi_Dry/0.originalCodes_240327/PseuMO-Tag/mtxGenerator`, optional)  
  Directory of analysis scripts.

### **Required Arguments**
- `--sampleList` (default: `sample_list.txt`, optional)  
  List of samples. Same as Step 1.
- `--resultFile` (default: `results.csv`, optional)  
  Name of the output file. The count matrix of PseuMO-Tag barcode sequences (rows) with raw read counts for each sample (columns).
- `--analysisDir` (default: `/Volumes/Shared/Miyata/Epi_Dry/0.originalCodes_240327/PseuMO-Tag/mtxGenerator`, optional)  
  Directory containing analysis scripts.

<br>  

