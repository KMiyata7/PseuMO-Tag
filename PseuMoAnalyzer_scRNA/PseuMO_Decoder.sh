#!/bin/bash
# PseuMO_Decoder.sh (K. Miyata, JFCR)
#
# Master pipeline that links clonal information to single-cell barcodes.
# It processes amplicon-seq data (templated on the scRNA-seq library) and
# produces CB x Tag count matrices for the PseuMO-Tag and the HashTag.
#
# Usage:
#   bash PseuMO_Decoder.sh --sampleName <SampleName> [--AnalyzerDir <Dir>] [--nCores <N>]
# Example:
#   bash PseuMO_Decoder.sh --sampleName Undetermined_S0 --nCores 10
#
# Requirements:
#   External tools : starcode, seqkit, cutadapt, fastqc, pigz
#   Python packages: pandas, matplotlib, numpy
#   Reference files: Ref/CB.txt, Ref/AllowList_PseuTag.txt, Ref/AllowList_HashTag.txt
#   Input FASTQ    : Fastq/<sampleName>_R1.fastq.gz, Fastq/<sampleName>_R2.fastq.gz
#
# Output:
#   PseuTag_matrix.csv, HashTag_matrix.csv  (CB x Tag count matrices)

# --- Default parameters --------------------------------------------------
sampleName="Undetermined_S0"
# By default, the analysis scripts are looked up in this script's own directory.
AnalyzerDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nCores=10

# --- Parse arguments -----------------------------------------------------
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --sampleName) sampleName="$2"; shift ;;
        --AnalyzerDir) AnalyzerDir="$2"; shift ;;
        --nCores) nCores="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# --- Analysis ------------------------------------------------------------
echo "START: $(date "+%Y-%m-%d %H:%M:%S")"

# 1. Trim R1/R2 reads
echo ">>> 1 of 6, TRIMMING <<<"
    # Required: Fastq/${sampleName}_R{1,2}.fastq.gz
bash ${AnalyzerDir}/PseuMO_trimmer.sh --sampleName $sampleName --nCores $nCores

# 2-A. Error correction of the 10x cell barcode (CB)
echo ">>> 2A of 6, ERROR CORRECTION for CB <<<"
python ${AnalyzerDir}/CB_corrector.py --input process/${sampleName}_R1_CB.txt --output process/${sampleName}_R1_CB_mod.txt --cores $nCores
    # Required: Ref/CB.txt

# 2-B. Error correction of the PseuMO-Tag
echo ">>> 2B of 6, ERROR CORRECTION for PseuMO-Tag <<<"
starcode --input process/${sampleName}_R2_PseuTag.txt --dist 1 --sphere --output process/${sampleName}_R2_PseuTag_star.txt --seq-id --quiet
python ${AnalyzerDir}/PseuTag_corrector.py --input process/${sampleName}_R2_PseuTag_star.txt --output process/${sampleName}_R2_PseuTag_mod.txt --sampleName ${sampleName} --tagName PseuTag

# 2-C. Error correction of the UMI
echo ">>> 2C of 6, ERROR CORRECTION for UMI <<<"
starcode --input process/${sampleName}_R1_UMI.txt --dist 1 --sphere --output process/${sampleName}_R1_UMI_star.txt --seq-id --quiet
python ${AnalyzerDir}/PseuTag_corrector.py --input process/${sampleName}_R1_UMI_star.txt --output process/${sampleName}_R1_UMI_mod.txt --sampleName ${sampleName} --tagName UMI

# 2-D. Assignment of the HashTag (shRNA)
echo ">>> 2D of 6, ERROR CORRECTION for Hash-Tag <<<"
python ${AnalyzerDir}/HashTag_corrector.py --input process/${sampleName}_R2_HashTag.txt --output process/${sampleName}_R2_HashTag_mod_tmp.txt --cores $nCores
python ${AnalyzerDir}/HashTag_converter.py --input process/${sampleName}_R2_HashTag_mod_tmp.txt --output process/${sampleName}_R2_HashTag_mod.txt

# 3. Combine CB, UMI, PseuTag and HashTag into a single table
echo ">>> 3 of 6, Combination of CB, UMI, PseuTag and HashTag <<<"
    # Uses: process/${sampleName}_R1_CB_mod.txt, _R1_UMI_mod.txt,
    #       _R2_PseuTag_mod.txt, _R2_HashTag_mod.txt
bash ${AnalyzerDir}/BCDs_combiner.sh ${sampleName}

# 4. Split "PseuMO-Tag + UMI" and "HashTag + UMI" per CB
echo ">>> 4 of 6, Split PseuMO-Tag and Hash-Tag for each CB <<<"
python ${AnalyzerDir}/BCDs_splitter.py --input ${sampleName}_cTable.txt --pseutag process/split_PseuTag --hashtag process/split_HashTag --cores $nCores

# 5. Count UMIs per CB; drop tags supported by a single read
echo ">>> 5 of 6, Counting UMI <<<"
python ${AnalyzerDir}/umi_counter.py --source_dir process/split_PseuTag/ --output_dir process/split_PseuTag_umi/ --cores $nCores
python ${AnalyzerDir}/umi_counter.py --source_dir process/split_HashTag/ --output_dir process/split_HashTag_umi/ --cores $nCores

# 6. Count the number of unique (UMI-deduplicated) tags per CB
echo ">>> 6 of 6, Counting PseuMO-Tags per CB <<<"
python ${AnalyzerDir}/tags_counter_umi.py --source_dir process/split_PseuTag_umi/ --allow_list_file Ref/AllowList_PseuTag.txt --output_csv_path PseuTag_matrix.csv --cores $nCores
python ${AnalyzerDir}/tags_counter_umi.py --source_dir process/split_HashTag_umi/ --allow_list_file Ref/AllowList_HashTag.txt --output_csv_path HashTag_matrix.csv --cores $nCores

echo "END: $(date "+%Y-%m-%d %H:%M:%S")"
