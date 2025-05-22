# PseuMO-Tag Decoder
**PseuMO-Tag**: <ins>**Pseu**</ins>do-<ins>**M**</ins>ulti<ins>**O**</ins>mics and cell <ins>**Tag**</ins>ging

**Tutorial By Kenichi Miyata**  

---
<img width="1586" alt="スクリーンショット 2025-04-25 14 23 29" src="https://github.com/user-attachments/assets/22af0194-3b76-4bdd-9d17-bacf04f2e14a" />
The paper will have been submitted to BioRxiv.

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

## 1. Amplicon-seq (gDNA)
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




---
## 2. Amplicon-seq (gDNA)
### Directory: `PseuMO-Tag_10bp_v1`
### Step 1) Extraction of PseuMO-Tag barcode sequences (`NNNNNNNNNN`)
Extract high-quality and pattern-matched barcodes from Amplicon-seq data. No error correction is performed.  

For example: Only the underlined Ssequences remain.  
`GTCGAGGCAGGAAACAGCTATGACTATGCA`<ins>**NNNNNNNNNN**</ins>`TGCATCGTTGAGCAATAACTAGCGAGCGGACAGATC`

Prepare `Fastq/[sampleName]_R1.fastq.gz` and `sample_list.txt` in the current directory.

```bash
conda activate pseumo
bash ${code_dir}/PseuTag_Processor_v3.sh --sampleList sample_list.txt
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




---
## 3. Amplicon-seq (gDNA)
### Directory: `PseuMO-Tag_20bp_v1`
### Step 1) Extraction of PseuMO-Tag barcode sequences (`WSWSWSWSWSWSWSWSWSWS`)
Extract high-quality and pattern-matched barcodes from Amplicon-seq data. No error correction is performed.  

For example: Only the underlined Ssequences remain.  
`GTCGAGGCAGGAAACAGCTATGACTAGTAC`<ins>**WSWSWSWSWSWSWSWSWSWS**</ins>`GTACTCGTTGAGCAATAACTAGCGAG`

Prepare `Fastq/[sampleName]_R1.fastq.gz` and `sample_list.txt` in the current directory.

```bash
conda activate pseumo
bash ${code_dir}/PseuTag_Processor_v3.sh --sampleList sample_list.txt
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


---

****************************************************************
## OLD VERSION: 1. Amplicon-seq (cDNA or Plasmid DNA) 
### Step 1) Extraction of PseuMO-Tag barcode sequences
Prepare ```Fastq/[sampleName]_R{1,2}.fastq.gz``` in the Current directory.

```shell:
conda activate pseumo
sampleName=sampleName # ex. 20240111Amp-ARI3-02_S6
sh AmpSeqToBCD_v1.sh --sampleName $sampleName
```
**Requied**
- --sampleName - Sample name. If the Amplicon's FastQ file name is ```20240111Amp-ARI3-02_S6_R1/2.fastq.gz```, the sample name is ```20240111Amp-ARI3-02_S6```. Please place Amplicon's FastQ files (R1 & R2) in the Fastq directory.

**Options**
- --frontAdapt - 5’ adapter sequence. Default: ```GTCGAGGCAGGAAACAGCTATGACT``` 
- --backAdapt - 3’ adapter sequence. Default: ```CGTTGAGCAATAACTAGCGAGCGGACAGATC```
- --hashTag - Hash-Tag sequence. Default: ```ATGCA```
- --minLenBCD - The minium allowable PseuMO-Tag barcode length. Default: 9
- --maxLenBCD - The maximum allowable PseuMO-Tag barcode length. Default: 11
- --Levenshtein - Levenshtein distance. Default: 1

For example: Only the Ns between the underlined letters remains. <br>
GTCGAGGCAGGAAACAGCTATGACT<ins>ATGCA</ins>NNNNNNNNNN<ins>TGCAT</ins>CGTTGAGCAATAACTAGCGAGCGGACAGATC


### Step 2) Extraction of upper barcode sequences
This step can extract only high-read barcodes from error-corrected barcode file.  
```shell:
fileName=${sampleName}/barcode.txt # ex. 20240111Amp-ARI3-02_S6/20240111Amp-ARI3-02_S6_PseuMO_Correct.txt
python PseuTag_selecter_v1.py --input $fileName
```
**Requied**
- ----input - Input file path. Tab-delimited three-column text file (A Barcode Sequence / Counts / Barcode Sequences) is required.

**Options**
- --output - Output file path.
- --threshValue - The threshold number of reads allowed, based on the barcode with the highest number of reads. (Default: 0.1)
- `-h` -- help

<br>  

****************************************************************
# 2. scRNA-seq

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
bash PseuMO_Decoder_v2.sh --sampleName ${sampleName} --AnalyzerDir $AnalyzerDir
```
**Requied**
- --sampleName - Sample name. If the Amplicon's FastQ file name is "20240111Amp-ARI3-02_S6_R1/2.fastq.gz", the sample name is "20240111Amp-ARI3-02_S6". Please place Amplicon's FastQ files (R1 & R2) in the "Fastq" directory.
- --AnalyzerDir - Directory Containing Analysis Pipelines.

**Options**
- --nCores - Number of cores. Default: 10

<br>
<br>

### Step-by-step method

#### Step 0) Sample Information Setup and Preparation

```shell:
sampleName="sampleName"
analysisDir="/pathTo/AnalysisDir"
cd ${analysisDir}

AnalyzerDir="/pathTo/PseuMoAnalyzer_scRNA"
chmod +x ${AnalyzerDir}/*

mkdir -p Fastq;
rsync -avP /pathTo/FastqFiles/ Fastq/
```

#### Step 1) Trimming & Extracting raw barcode sequences
This step outputs adapter trimming and then shRNA-Tag & PseuMO-Tag sequences from R2, and cellular barcode sequences from R1 as a text file.  
```shell:
${AnalyzerDir}/PseuMO_trimmer_v2.sh --sampleName $sampleName
```
**Requied**
- --sampleName - Sample name. If the Amplicon's FastQ file name is "20240111Amp-ARI3-02_S6_R1/2.fastq.gz", the sample name is "20240111Amp-ARI3-02_S6". Please place Amplicon's FastQ files (R1 & R2) in the "Fastq" directory.

**Options**
- --frontAdapt - 5’ adapter sequence. Default: ```CAGGAAACAGCTATGACT```
- --backAdapt - 3’ adapter sequence. Default: ```CGTTGAGCAATAACTAGCGAGCGGA```

**Output files:**  
- shRNA-Tag: process/${sampleName}_R2_Hash.txt  
- PseuMO-Tag: process/${sampleName}_R2_PseuMO.txt  
- Cellular barcode: process/${sampleName}_R1_selected.txt  
<br>  

### Step 2-A) Correction of Cellular Barcode (BCDof10x)
Using the barcode sequence of the cell subpopulation (exported from Seurat, etc.) as a reference, correct errors in the cell barcode sequence (Hamming distance up to 1 is allowed). If there is no matching barcode, "UNK" is output.  
```shell:
${AnalyzerDir}/CB_corrector_v1.py --input process/${sampleName}_R1_selected.txt --output process/${sampleName}_R1_mod.txt --cores 10
```
**Requied**
- --input - Raw cell barcode sequence. Typically, the file output in step 1 (process/${sampleName}_R1_selected.txt)  
- --output - Output file name. "process/${sampleName}_R1_mod.txt" is recommended  
- --cores - Default: 1. Strongly recommend using as many cores as possible  
- Reference cellular barcodes - Cell barcode information used for single cell analysis. Make sure it is "Ref/CB.txt".
If you are using Seurat, use the text file output below as input.
```write.table(colnames(Seurat.object), "${analysisDir}/Ref/CB.txt", quote = FALSE, row.names = FALSE, col.names = FALSE)```
  
**Options**
- `-h` -- help

**Output files:**  
- process/${sampleName}_R1_mod.txt - Cell barcode information after error correction  
<br>  

### Step 2-B) Correction of PseuMO-Tag (BCDofPseuMO)
This step corrects PseuMO-Tag errors (errors are allowed up to 1 Levenshtein distance). A plot of the PseuMO-Tag file and its number of reads after error correction is also output.
```shell:
starcode --input process/${sampleName}_R2_PseuMO.txt --dist 1 --sphere --output process/${sampleName}_R2_PseuMO_star_id.txt --seq-id --quiet
```
```shell:
${AnalyzerDir}/BCDofPseuMO_corrector_v3.py --input process/${sampleName}_R2_PseuMO_star.txt --output process/${sampleName}_R2_PseuMO_mod.txt --sampleName ${sampleName}
```
**Requied**
- --input - Output file after starcode processing
- --output - Output file name after error correction. "process/${sampleName}_R2_PseuMO_mod.txt" is recommneded.
- --sampleName - Variable ${sampleName} is recommended.
 
**Options**
- `-h` -- help  

**Output files:**  
- process/${sampleName}_R2_PseuMO_mod.txt - PseuMO-Tag sequences after error correction  
- PseuMO_CountPlot.jpeg - The plot of detected PseuMO-Tag sequences (x-axis) and their number of detections (reads) (y-axis)
<br>  

### Step 2-C) Correction of Hash (shRNA)
```shell:
${AnalyzerDir}/HashTag_corrector_v3.py --input process/${sampleName}_R2_HashTag.txt --output process/${sampleName}_R2_HashTag_mod_tmp.txt --cores 10;
${AnalyzerDir}/HashTag_converter_v2.py --input process/${sampleName}_R2_HashTag_mod_tmp.txt --output process/${sampleName}_R2_HashTag_mod.txt;
```
**Requied**
- --input - Input file
- --output - Output file
**Options**
- `-h` -- help  
<br>  

### Step 3) Combine A, B, C and D
Combine the text files "CB", "PseuMO-Tag", "UMI" and "HashTag" (remove "UNK").
```shell:
${AnalyzerDir}/BCDs_combiner_v1.sh ${sampleName};
```
**Requied**
- "${sampleName}_R1_mod.txt" + "process/${sampleName}_R2_PseuTag_mod.txt" + "process/${sampleName}_R2_HashTag_mod.txt" > "process/${sampleName}_cTable_tmp.txt"
<br>  

### Step 4) Split the PseuMO-Tag & shRNA info every Cellular barcode from the cTable with 3 columns 10xBCD/PseuMO-Tag/Hash
```shell:
${AnalyzerDir}/BCDs_splitter_v1.py --input ${sampleName}_cTable.txt --pseutag process/split_PseuTag --hashtag process/split_HashTag --cores 10;
```
**Requied**
- --input - Input file. "${sampleName}_cTable.txt" is recommended.

**Options**
- --pseutag - Output directory for storing PseuMO-Tags divided per cell. Default: process/split_PseuTag
- --hashtag - Output directory for storing Hash-Tags divided per cell. Default: process/split_HashTag
- `-h` -- help  
<br>  

### Step 5) Split the PseuMO-Tag & shRNA info every Cellular barcode from the cTable with 3 columns 10xBCD/PseuMO-Tag/Hash
This UMI analysis is based on "Sun et al. Nature Computational Science, 4, 128-143 (2024)".

### Step 5) Split the PseuMO-Tag & shRNA info every Cellular barcode from the cTable with 3 columns 10xBCD/PseuMO-Tag/Hash
```shell:
${AnalyzerDir}/tags_counter_v1.py --source_dir process/split_HashTag --allow_list_file Ref/AllowList_HashTag.txt --output_csv_path HashTag_matrix.csv
${AnalyzerDir}/tags_counter_v1.py --source_dir process/split_PseuTag --allow_list_file Ref/AllowList_PseuTag.txt --output_csv_path PseuTag_matrix.csv
```
**Requied**
- --ref - XXX. Default: AllowList_Hash.txt
- --input - Input file. Default: process/split_shRNA/

**Options**
- `-h` -- help

### Calculate the number of Hash for every Cellular Barcode
```shell:
sh ${AnalyzerDir}/shRNA_counter_v1.sh;
python ${AnalyzerDir}/shRNA_determinator_v1.py;
```
- `-h` -- help


**The output file PseuTag_matrix.csv is the count matrix for CB and PseuMO-Tag. Next, clone calling step is performed in R to link the cells to the lineage.**



****************************************************************
# 3. scATAC-seq (Coming Soon...)
****************************************************************


## **Contact**
For any questions or issues, please contact **Kenichi Miyata**  
📧 Email: kenichi.miyata@jfcr.or.jp

---
