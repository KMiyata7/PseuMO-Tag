#!/bin/bash
# PseuTag_mtxGenerator.sh
# Author: K. Miyata, JFCR
#
# Purpose:
#   Merge multiple PseuTag barcode text files, run error correction on the
#   merged file, split it back per sample, and finally build a barcode count
#   matrix for each sample.
#
# Change log:
#   v1 (2024/10/15) : Initial version.
#   v2 (2025/03/09) : Sample list can be passed as an argument; the paths of
#                     the helper programs are configurable.
#   v4 (2025/04/04) : Changed the Levenshtein distance to 2.
#
# USAGE:
#   sh codes/PseuTag_mtxGenerator.sh [1.sample_list.txt] [2.result.csv] [3.analysis_dir]
#     1. sample_list.txt : sample list (default: sample_list.txt)
#     2. result.csv      : output matrix (default: result.csv)
#     3. analysis_dir    : directory holding the helper scripts
#                          (default: this script's own directory)
#
# REQUIRED files:
#   1. sample_list.txt
#      $ cat sample_list.txt
#      TEST1
#      TEST2
#      TEST3
#   2. Barcodes: "process/${sampleName}/${sampleName}.txt" for each sample, e.g.
#      $ head -n 3 process/cont1_S3/cont1_S3.txt
#      CTCGTAGACTGGGAGTTATGAGTCAGCG
#      CAAGTGTGCTGTCAGCCATGGTTCATTT
#      GCAGTGACCTCGGAGGCTTGGTTCATGA

set -e;
mkdir -p Barcode_correct process;

# Locate this script's directory so the helper programs can be found by default.
default_dir="$(cd "$(dirname "$0")" && pwd)"

sample_list=${1:-"sample_list.txt"}   # File list to merge, read from sample_list.txt
result_file=${2:-"result.csv"}
analysis_dir=${3:-"$default_dir"}      # Directory holding the helper programs

line_count_file="process/line_counts.txt"  # File that stores per-sample line counts
merged_file="process/merged_file.txt"       # Merged file
processed_file="process/processed_file.txt" # File after error correction

# Check that the sample list exists.
if [[ ! -f $sample_list ]]; then
  echo "Error: $sample_list not found!" >&2
  exit 1
fi

# 1. Record the line count of each file and initialize the merged file.
> $line_count_file  # Initialize the line-count file
> $merged_file      # Initialize the merged file

# List that holds the file names.
file_names=()

mkdir -p Barcode;
while read -r i || [[ -n "$i" ]]; do
  [[ -z "$i" ]] && continue
  cp process/${i}/${i}.txt Barcode
done < $sample_list

# Loop over the files listed in sample_list.txt.
echo '1 of 5: MERGE BARCODEs';
while read -r file || [[ -n "$file" ]]; do
  [[ -z "$file" ]] && continue
  echo $file
  file_names+=("$file")  # Add the file name to the list
  # Record each file's line count in line_counts.txt.
  if [[ -f Barcode/"$file".txt ]]; then
    wc -l Barcode/"$file".txt | awk '{print $1}' >> $line_count_file
    # Append the file to merged_file.txt.
    cat Barcode/"$file".txt >> $merged_file
  else
    echo "File $file.txt not found" >&2
  fi
done < $sample_list

# 2. Run error correction on the merged PseuTag file.
echo '2 of 5: ERROR CORRECT';
starcode --input $merged_file --dist 2 --sphere --output process/merged_file_starcode.txt --seq-id --quiet;
python ${analysis_dir}/PseuTag_corrector.py --input process/merged_file_starcode.txt --output $processed_file;

# 3. Split the corrected file back into per-sample files using the saved line counts.
echo '3 of 5: SPLIT MERGED BARCODEs';
start_line=1
i=0
while read -r line_count; do
  end_line=$((start_line + line_count - 1))
  # Save each sample as Barcode_correct/${file}.txt.
  file="${file_names[$i]}"
  sed -n "${start_line},${end_line}p" $processed_file > Barcode_correct/"${file}.txt"
  start_line=$((end_line + 1))
  i=$((i + 1))
done < $line_count_file

# 4. Export the unique PseuTags.
echo '4 of 5: EXPORT UNIQUE BARCODEs';
if [[ -f PseuTag_Uniq.txt ]]; then
  echo "Warning: PseuTag_Uniq.txt will be overwritten." >&2
fi
sort $processed_file | uniq > PseuTag_Uniq.txt;

# 5. Build the barcode count matrix (rows: PseuTag_Uniq.txt, columns: sample_list.txt).
echo '5 of 5: EXPORT BARCODE MATRIX';
python ${analysis_dir}/PseuTag_counter.py $sample_list $result_file

echo "Processing completed!"
