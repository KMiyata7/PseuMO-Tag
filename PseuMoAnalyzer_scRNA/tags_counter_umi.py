#!/usr/bin/env python
# tags_counter_umi.py (K. Miyata, JFCR)
#
# Count the number of Hash/PseuMO-Tags contained in all per-cell text files in
# "source_dir" (one file per cell barcode) and export the counts as a CSV
# matrix (rows: cell barcodes, columns: tags from the allow list).
#
# Usage:
#   tags_counter_umi.py --source_dir <dir> --allow_list_file <txt> --output_csv_path <csv> [--cores <N>]
# Example:
#   tags_counter_umi.py --source_dir process/split_PseuTag_umi/ \
#                       --allow_list_file Ref/AllowList_PseuTag.txt \
#                       --output_csv_path PseuTag_matrix.csv --cores 10

import os
import sys
import argparse
from collections import Counter
from concurrent.futures import ProcessPoolExecutor
import pandas as pd

def process_file(file_path):
    with open(file_path, 'r') as f:
        counts = Counter(line.split('\t')[0].strip() for line in f)
    return os.path.basename(file_path).replace('.txt', ''), counts

def main():
    source_dir = args.source_dir
    allow_list_file = args.allow_list_file
    max_workers = args.cores
    output_csv_path = args.output_csv_path

    # Ask before overwriting an existing output file.
    if os.path.exists(output_csv_path):
        response = input(f"The file '{output_csv_path}' already exists. Do you want to overwrite it? [y/N]: ").strip().lower()
        if response != 'y':
            print("Aborting the process.")
            sys.exit()

    sys.stdout.write("Analyzing...")
    sys.stdout.flush()

    # Collect the input files and build the DataFrame index (one row per cell barcode).
    files = []
    df_index = []
    for f in os.listdir(source_dir):
        full_path = os.path.join(source_dir, f)
        if os.path.isfile(full_path) and f.endswith('.txt'):
            files.append(full_path)
            df_index.append(f.replace('.txt', ''))

    # Build the allow list (columns) and the empty count matrix.
    allow_list = pd.read_csv(allow_list_file, header=None).iloc[:, 0].tolist()
    df = pd.DataFrame(0, index=df_index, columns=allow_list)

    # Count tags in parallel and fill the matrix.
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        results = executor.map(process_file, files)
        for file_name, counts in results:
            for line_content, count in counts.items():
                if line_content in df.columns:
                    df.at[file_name, line_content] = count

    # Append "-1" to each cell barcode (10x convention) and export as CSV.
    df.index = df.index + "-1"
    df.to_csv(output_csv_path, index_label="CB")

    sys.stdout.write("\r" + " " * len("Analyzing...") + "\r")
    sys.stdout.flush()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Count the number of Hash/PseuMO-Tags in all per-cell text files '
                    '(split by cell barcode) in "source_dir" and export the counts as a CSV matrix.')
    parser.add_argument('--source_dir', type=str, default='process/split_shRNA/', help='Input directory (default process/split_shRNA/)')
    parser.add_argument('--allow_list_file', type=str, default='Ref/AllowList_Hash.txt', help='Allow list file path (default Ref/AllowList_Hash.txt)')
    parser.add_argument('--output_csv_path', type=str, default='output_matrix.csv', help='Output CSV path (default output_matrix.csv)')
    parser.add_argument('--cores', type=int, default=4, help='Number of CPUs (default 4)')
    args = parser.parse_args()
    main()
