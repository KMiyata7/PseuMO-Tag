#!/usr/bin/env python
# umi_counter.py (K. Miyata, JFCR)
#
# For a directory of per-cell text files (tag, UMI), count read support per
# (tag, UMI), keep for each UMI the row with the highest read count, append the
# count as a third column, and drop UMIs supported by a single read (count <= 1).
#
# Usage:
#   umi_counter.py --source_dir <dir> --output_dir <dir> [--cores <N>]
# Example:
#   umi_counter.py --source_dir process/split_PseuTag/ --output_dir process/split_PseuTag_umi/ --cores 8

import csv
import os
import argparse
from collections import defaultdict
from multiprocessing import Pool

def process_file(file_info):
    input_file_path, output_file_path = file_info

    # Count occurrences of each full row.
    counts = defaultdict(int)
    with open(input_file_path, 'r') as file:
        reader = csv.reader(file, delimiter='\t')
        for row in reader:
            counts[tuple(row)] += 1

    # Keep, for each UMI (second column), the row with the highest read count.
    max_counts = {}
    for row, count in counts.items():
        key = row[1]  # UMI as key
        if key not in max_counts or count > max_counts[key][2]:
            max_counts[key] = list(row) + [count]

    # Drop UMIs supported by a single read (count <= 1).
    final_rows = [row for row in max_counts.values() if row[2] > 1]

    # Write the deduplicated rows with the appended count.
    with open(output_file_path, 'w', newline='') as file:
        writer = csv.writer(file, delimiter='\t')
        for row in final_rows:
            writer.writerow(row)

def main():
    parser = argparse.ArgumentParser(description='Count UMIs for a directory split per cell.')
    parser.add_argument('--source_dir', type=str, default='process/split_PseuTag/', help='Input directory (default process/split_PseuTag/)')
    parser.add_argument('--output_dir', type=str, default='process/split_PseuTag_umi/', help='Output directory (default process/split_PseuTag_umi/)')
    parser.add_argument('--cores', type=int, default=4, help='Number of CPUs (default 4)')
    args = parser.parse_args()

    input_directory = args.source_dir
    output_directory = args.output_dir
    num_cores = args.cores

    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    file_paths = [(os.path.join(input_directory, filename), os.path.join(output_directory, filename))
                  for filename in os.listdir(input_directory) if filename.endswith('.txt')]

    with Pool(processes=num_cores) as pool:
        pool.map(process_file, file_paths)

if __name__ == "__main__":
    main()
