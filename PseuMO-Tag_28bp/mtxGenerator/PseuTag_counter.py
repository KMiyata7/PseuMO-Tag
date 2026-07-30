# PseuTag_counter.py
# Author: K. Miyata, JFCR
#
# Change log:
#   v1 (2024/10/15) : Initial version.
#   v2 (2025/03/09) : sample_list and output file are now given as arguments.
#
# Purpose:
#   Build a barcode-by-sample count matrix. Rows are the unique barcodes in
#   "PseuTag_Uniq.txt" and columns are the samples in the sample list. For
#   each sample, count how many times each barcode occurs in its file inside
#   the "Barcode_correct" directory.
#
# USAGE:
#   python codes/PseuTag_counter.py [sample_list.txt] [result.csv]

import os
import numpy as np
import csv
import sys

# Get command-line arguments
if len(sys.argv) > 2:
    sample_list_file = sys.argv[1]
    output_csv_file = sys.argv[2]
else:
    print("Usage: python PseuTag_counter.py [sample_list.txt] [result.csv]")
    sys.exit(1)

# Fixed input paths
pseutag_file = 'PseuTag_Uniq.txt'
barcode_correct_dir = 'Barcode_correct'

# Read row names (barcodes) and column names (samples). Case is ignored.
with open(pseutag_file, 'r') as f:
    row_names = [line.strip().upper() for line in f.readlines()]

with open(sample_list_file, 'r') as f:
    col_names = [line.strip() for line in f.readlines()]

# Create a zero matrix sized by the number of rows and columns.
matrix = np.zeros((len(row_names), len(col_names)), dtype=int)

# For each sample file, count the occurrences of each barcode.
for col_idx, col_name in enumerate(col_names):
    file_path = os.path.join(barcode_correct_dir, f'{col_name}.txt')

    # Check that the file exists.
    if not os.path.exists(file_path):
        print(f"File does not exist: {file_path}")
        continue

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read().upper()  # Ignore case

    # Count each barcode and record it in the matrix.
    for row_idx, row_name in enumerate(row_names):
        count = content.count(row_name)
        matrix[row_idx, col_idx] = count

# Write the resulting matrix to a CSV file.
with open(output_csv_file, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)

    # First row: column names (sample names).
    writer.writerow([''] + col_names)

    # One row per barcode with its counts.
    for row_idx, row_name in enumerate(row_names):
        writer.writerow([row_name] + list(matrix[row_idx]))
