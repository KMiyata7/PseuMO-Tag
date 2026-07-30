#!/bin/bash
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
# PseuTag_Processor.sh - PseuMO-Tag Amplicon-seq Data Processing
# Purpose: Extract high-quality (Phred >= 30), pattern-matched sequences
#          (NNNGTNNNCTNNNAGNNNTGNNNCANNN, 28 bp) from Amplicon-Seq data.
#          No error correction is performed here.
# Author : K. Miyata, JFCR
#
# Change log:
#   v1 (2025/03/09) : Initial version.
#   v2 (2025/03/15) : Minor modifications for public release.
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

# EXAMPLE
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
# code_dir="/path/to/PseuMO-Tag";
# bash ${code_dir}/PseuTag_Processor.sh --sampleList sample_list.txt;
#   --sampleList   Sample list file (default: sample_list.txt)
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

# REQUIRED files
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
# 1. Sample list
#    $ cat sample_list.txt
#    cont1_S3
#    cont2_S4
# 2. FastQ files
#    Fastq/${sampleName}_R1.fastq.gz
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

# EXPORTED files
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
# process/${sampleName}/Fastq_process/${sampleName}_R1_1.fastq.gz: After trimming front adapter (30 bp)
# process/${sampleName}/Fastq_process/${sampleName}_R1_2.fastq.gz: After trimming back adapter (18 bp)
# process/${sampleName}/Fastq_process/${sampleName}_R1_3.fastq.gz: After keeping reads of exactly 28 bp
# process/${sampleName}/Fastq_process/${sampleName}_R1_4.fastq.gz: After keeping reads matching 'NNNGTNNNCTNNNAGNNNTGNNNCANNN'
# process/${sampleName}/Fastq_process/${sampleName}_R1_5.fastq.gz: After quality filtering
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

set -e  # Exit on any error
trap 'echo "Error occurred. Exiting script."; exit 1' ERR

# Function to check that required commands are installed.
check_dependencies() {
    MISSING=()

    # Required commands for the pipeline.
    for cmd in fastqc cutadapt pigz seqkit; do
        if ! command -v "$cmd" &> /dev/null; then
            MISSING+=("$cmd")
        fi
    done

    if [ ${#MISSING[@]} -ne 0 ]; then
        echo -e "\e[1;31m[ERROR] The following required packages are missing:\e[0m"
        for pkg in "${MISSING[@]}"; do
            echo "  - $pkg"
        done
        echo -e "\e[1;33m[INFO] Please install the missing packages and try again.\e[0m"
        exit 1
    fi
}
# Execute the check
check_dependencies

# Function to parse command-line arguments
parse_arguments() {
    SAMPLE_LIST="sample_list.txt"  # Default value

    while [[ $# -gt 0 ]]; do
        case $1 in
            --sampleList)
                SAMPLE_LIST="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--sampleList <file>]"
                echo "  --sampleList   Specify the sample list file (default: sample_list.txt)"
                exit 0
                ;;
            *)
                echo "Error: Unknown argument: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
}

# Execute argument parsing
parse_arguments "$@"

# Print selected parameters
echo "Using sample list: $SAMPLE_LIST"

# Check if sample list file exists
if [[ ! -f $SAMPLE_LIST ]]; then
    echo "Error: Sample list file '$SAMPLE_LIST' not found!" >&2
    exit 1
fi

# Function to display an ASCII banner.
# figlet / lolcat are optional; the banner degrades gracefully if they are missing.
show_banner() {
    printf "\e[1;34m"
    if command -v figlet &> /dev/null && command -v lolcat &> /dev/null; then
        figlet -f standard "PseuMO-Tag" | lolcat -a -d
    elif command -v figlet &> /dev/null; then
        figlet -f standard "PseuMO-Tag"
    else
        echo "PseuMO-Tag"
    fi
    echo "---------------------------------------------------"
    printf "\e[1;31m  PseuMO: Barcode Processing Pipeline\e[0m\n"
    echo "  Version: 2.0 (2025/03/15)"
    echo "---------------------------------------------------"
    printf "\e[0m\n"
}
# Show the banner at script startup
show_banner

mkdir -p process;

process_sample() {
  sampleName=$1
  echo "Processing: $sampleName"

  cd process;
  mkdir -p ${sampleName}/{Fastq,Fastq_process,FastQC,log}
  cd ${sampleName}

  cp ../../Fastq/${sampleName}_R1.fastq.gz Fastq/

  # Run FastQC for raw data
  fastqc --nogroup -o FastQC Fastq/${sampleName}_R1.fastq.gz >> log/log.txt 2>> log/log.txt


  ## Common adapter sequences ##
  frontAdapt='GTCGAGGCAGGAAACAGCTATGACTATGCA'  # 30 bp
  backAdapt='TGCATCGTTGAGCAATAA'               # 18 bp
  # PseuMO-Tag barcode: NNNGTNNNCTNNNAGNNNTGNNNCANNN (28 bp) -> total 76 bp

  echo -e '\n' >> log/log.txt;

  #### 1. Filter_1 ####
  # Trim front adapter (30 bp)
  echo "Trimming front adapter..." >> log/log.txt;
  echo '### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###' >> log/log.txt;
  cutadapt -g ${frontAdapt} Fastq/${sampleName}_R1.fastq.gz 2>> log/log.txt | pigz -cf > Fastq_process/${sampleName}_R1_1.fastq.gz
  echo '### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###' >> log/log.txt;
  echo -e '\n' >> log/log.txt;

  #### 2. Filter_2 ####
  # Trim back adapter (18 bp)
  echo "Trimming back adapter..." >> log/log.txt;
  echo '### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###' >> log/log.txt;
  cutadapt -a ${backAdapt} Fastq_process/${sampleName}_R1_1.fastq.gz 2>> log/log.txt | pigz -cf > Fastq_process/${sampleName}_R1_2.fastq.gz
  echo '### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###' >> log/log.txt;
  echo -e '\n' >> log/log.txt;

  #### 3. Filter_3 ####
  # Keep only reads of exactly 28 bp
  echo "Filtering sequences of exactly 28bp..." >> log/log.txt;
  echo -e '\n' >> log/log.txt;
  seqkit seq -m 28 -M 28 -g Fastq_process/${sampleName}_R1_2.fastq.gz | pigz -cf > Fastq_process/${sampleName}_R1_3.fastq.gz

  # Check that the output file exists and is not empty
  if [ ! -s Fastq_process/${sampleName}_R1_3.fastq.gz ]; then
    echo "Error: File not found or empty after filtering 28bp reads!"
    exit 1
  fi

  #### 4. Filter_4 ####
  # Keep only reads matching the expected barcode pattern
  echo "Filtering sequences matching the pattern 'NNNGTNNNCTNNNAGNNNTGNNNCANNN'..." >> log/log.txt;
  echo -e '\n' >> log/log.txt;
  gzip -dc Fastq_process/${sampleName}_R1_3.fastq.gz | seqkit grep -s -r -p "^[ATGC]{3}GT[ATGC]{3}CT[ATGC]{3}AG[ATGC]{3}TG[ATGC]{3}CA[ATGC]{3}$" | pigz -cf > Fastq_process/${sampleName}_R1_4.fastq.gz

  # Check that the output file exists and is not empty
  if [ ! -s Fastq_process/${sampleName}_R1_4.fastq.gz ]; then
    echo "Error: No reads matched the specified pattern!"
    exit 1
  fi

  #### 5. Filter_5 ####
  # Filter by Phred quality score.
  # --min-qual 30: keep reads whose mean Phred quality score is >= 30.
  echo "Running Filtering for Phred --min-qual 30..." >> log/log.txt;
  echo -e '\n' >> log/log.txt;
  gzip -dc Fastq_process/${sampleName}_R1_4.fastq.gz | seqkit seq --min-qual 30 | pigz -cf > Fastq_process/${sampleName}_R1_5.fastq.gz;
  # Note: ideally we would keep only reads whose *minimum* Phred score is >= 10,
  #       but seqkit filters on mean quality, so that is not directly available.

  # Check that the output file exists and is not empty
  if [ ! -s Fastq_process/${sampleName}_R1_5.fastq.gz ]; then
      echo "Error: No reads passed the Phred quality filtering!"
      exit 1
  fi

  # Run FastQC for processed data
  echo "Running FastQC for processed data..." >> log/log.txt;
  echo '### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###' >> log/log.txt;
  fastqc --nogroup -o FastQC Fastq_process/${sampleName}_R1_{1..5}.fastq.gz >> log/log.txt 2>> log/log.txt
  echo '### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###' >> log/log.txt;
  echo -e '\n' >> log/log.txt;

  #### 6. Convert FastQ to TXT ####
  # Extract barcode sequences
  echo "Extracting barcode sequences..." >> log/log.txt;
  echo -e '\n' >> log/log.txt;
  seqkit seq -s Fastq_process/${sampleName}_R1_5.fastq.gz > ${sampleName}.txt

  cd ..
}

export -f process_sample  # Export function for parallel execution

# Parallel processing using xargs (max 4 parallel jobs)
echo "Starting parallel processing with sample list: $SAMPLE_LIST"
cat $SAMPLE_LIST | xargs -I{} -P 4 bash -c 'process_sample "{}"'

# QC - Before processing
# The "|| [[ -n ... ]]" guard also reads the last line when the file has no trailing newline.
while read -r sampleName || [[ -n "$sampleName" ]]; do
    [[ -z "$sampleName" ]] && continue
    seqkit stats -a -T process/${sampleName}/Fastq/${sampleName}_R1.fastq.gz >> process/Stats_before.tsv
done < "$SAMPLE_LIST"

# QC - After processing
while read -r sampleName || [[ -n "$sampleName" ]]; do
    [[ -z "$sampleName" ]] && continue
    seqkit stats -a -T process/${sampleName}/Fastq_process/${sampleName}_R1_5.fastq.gz >> process/Stats_after.tsv
done < "$SAMPLE_LIST"

echo "All samples processed successfully!"
