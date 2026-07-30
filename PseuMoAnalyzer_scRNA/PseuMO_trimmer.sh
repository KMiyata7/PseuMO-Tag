#!/bin/bash
# PseuMO_trimmer.sh (K. Miyata, JFCR)
#
# From the amplicon-seq FASTQ, remove the PCR handle and keep only reads that
# contain a PseuMO-Tag. For each retained R2 read, the corresponding R1 read is
# used to extract the cell barcode (CB) and the UMI.
#
# Usage:
#   bash PseuMO_trimmer.sh --sampleName <SampleName> [--frontAdapt <seq>] [--backAdapt <seq>] [--nCores <N>]
#
# Required input:
#   Fastq/${sampleName}_R{1,2}.fastq.gz
#
# Required tools: seqkit, cutadapt, fastqc, pigz

# ********************************************************
# 0. Check required tools
if ! command -v seqkit &> /dev/null; then
    echo "ERROR: seqkit is not installed."
    exit 1
fi
if ! command -v cutadapt &> /dev/null; then
    echo "ERROR: cutadapt is not installed."
    exit 1
fi
if ! command -v fastqc &> /dev/null; then
    echo "ERROR: fastqc is not installed."
    exit 1
fi
if ! command -v pigz &> /dev/null; then
    echo "ERROR: pigz is not installed."
    exit 1
fi
# ********************************************************

# ********************************************************
# 1. Parse arguments
# Default settings
sampleName=""                                          # e.g. Mixed_test
frontAdapt='CAGGAAACAGCTATGACT'                        # 5' adapter, 18 bp
backAdapt='CGTTGAGCAATAACTAGCGAGCGGACTGTCTCTTATAC'     # 3' adapter, 38 bp
nCores=10

# Analyze arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --sampleName) sampleName="$2"; shift ;;
        --frontAdapt) frontAdapt="$2"; shift ;;
        --backAdapt) backAdapt="$2"; shift ;;
        --nCores) nCores="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

echo "*************************************"
echo "Sample name: $sampleName"
echo "5' adapter : $frontAdapt"
echo "3' adapter : $backAdapt"
echo "*************************************"
# ********************************************************

# Record the start time
start=$(date +%s)

# ********************************************************
# 2. Run
mkdir -p process FastQC log Plots

echo "1. FastQC"
fastqc --nogroup -o FastQC Fastq/${sampleName}_R{1,2}.fastq.gz --threads 6 >> log/FastQC.txt 2>> log/FastQC.txt

echo "2. CUTADAPT"
echo "[Front CUT]" >> log/Cutadapt.txt
echo "Fastq/${sampleName}_R2.fastq.gz" >> log/Cutadapt.txt
cutadapt --cores=${nCores} -g ${frontAdapt} Fastq/${sampleName}_R2.fastq.gz 2>> log/Cutadapt.txt | pigz -cf > process/${sampleName}_R2_1cut.fastq.gz
echo "*************************************************************************" >> log/Cutadapt.txt
echo "[Back CUT]" >> log/Cutadapt.txt
echo "Fastq/${sampleName}_R2_1cut.fastq.gz" >> log/Cutadapt.txt
cutadapt --cores=${nCores} -a ${backAdapt} process/${sampleName}_R2_1cut.fastq.gz 2>> log/Cutadapt.txt | pigz -cf > process/${sampleName}_R2_2cut.fastq.gz
echo "*************************************************************************" >> log/Cutadapt.txt

echo "3. FILTRATION"   # Keep only 19-21 bp reads that were trimmed correctly at both ends, and drop reads containing 'N'
gzip -dc process/${sampleName}_R2_2cut.fastq.gz | seqkit seq -m 19 -M 21 -g | seqkit grep -srv -p 'N' | pigz -cf > process/${sampleName}_R2_Hash-PseuTag.fastq.gz
fastqc --nogroup -o FastQC process/${sampleName}_R2_Hash-PseuTag.fastq.gz --threads 6 >> log/FastQC.txt 2>> log/FastQC.txt

echo "4. Converting FastQ to sequence"
seqkit seq -s process/${sampleName}_R2_Hash-PseuTag.fastq.gz > process/${sampleName}_R2_Hash-PseuTag.txt   # layout: 'HashTag'-'PseuTag'
cut -c1-5  process/${sampleName}_R2_Hash-PseuTag.txt > process/${sampleName}_R2_HashTag.txt                # 'HashTag' : first 5 bp
cut -c6-15 process/${sampleName}_R2_Hash-PseuTag.txt > process/${sampleName}_R2_PseuTag.txt                # 'PseuTag' : bp 6-15

echo "5. Converting R1"   # Extract R2 headers, select matching R1 reads, then split into CB and UMI
seqkit seq -ni process/${sampleName}_R2_Hash-PseuTag.fastq.gz -j 10 > process/${sampleName}_R2_Hash-PseuTag_ID.txt
# Select R1 reads whose IDs correspond to R2 reads retained (trimmed to 19-21 bp)
gzip -dc Fastq/${sampleName}_R1.fastq.gz | seqkit grep -f process/${sampleName}_R2_Hash-PseuTag_ID.txt -j 10 | pigz -cf > process/${sampleName}_R1_selected.fastq.gz
gzip -dc process/${sampleName}_R1_selected.fastq.gz | seqkit subseq -r 1:16  | pigz -cf > process/${sampleName}_R1_CB.fastq.gz
gzip -dc process/${sampleName}_R1_selected.fastq.gz | seqkit subseq -r 17:28 | pigz -cf > process/${sampleName}_R1_UMI.fastq.gz
fastqc --nogroup -o FastQC process/${sampleName}_R1_selected.fastq.gz --threads 6 >> log/FastQC.txt 2>> log/FastQC.txt
fastqc --nogroup -o FastQC process/${sampleName}_R1_CB.fastq.gz --threads 6 >> log/FastQC.txt 2>> log/FastQC.txt
fastqc --nogroup -o FastQC process/${sampleName}_R1_UMI.fastq.gz --threads 6 >> log/FastQC.txt 2>> log/FastQC.txt
seqkit seq -s process/${sampleName}_R1_CB.fastq.gz  > process/${sampleName}_R1_CB.txt    # CB  (16 bp)
seqkit seq -s process/${sampleName}_R1_UMI.fastq.gz > process/${sampleName}_R1_UMI.txt   # UMI (12 bp)
rm process/${sampleName}_R2_1cut.fastq.gz process/${sampleName}_R2_2cut.fastq.gz process/${sampleName}_R1_CB.fastq.gz process/${sampleName}_R1_UMI.fastq.gz process/${sampleName}_R2_Hash-PseuTag_ID.txt
# ********************************************************

# Record the end time
end=$(date +%s)
duration=$((end - start))
minutes=$((duration / 60))
seconds=$((duration % 60))
echo "Total processing time: $minutes minutes and $seconds seconds."
echo "*************************************"
