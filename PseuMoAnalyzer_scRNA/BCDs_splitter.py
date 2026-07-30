#!/usr/bin/env python
# BCDs_splitter.py (K. Miyata, JFCR)
#
# Given a 4-column table ("CB", "UMI", "PseuMO-Tag", "HashTag"), split it per
# cell barcode (CB): for each CB, write "PseuMO-Tag + UMI" and "HashTag + UMI"
# into per-CB text files.
#
# Usage:
#   BCDs_splitter.py --input <4-column txt> --pseutag <dir> --hashtag <dir> [--cores <N>]
# Example:
#   BCDs_splitter.py --input ${sampleName}_cTable.txt \
#                    --pseutag process/split_PseuTag --hashtag process/split_HashTag --cores 20

import time
import os
import sys
import shutil
import argparse
from concurrent.futures import ProcessPoolExecutor

# ------------------------------------------------------------------
# 1. Functions

# Split one line and append "PseuTag + UMI" and "HashTag + UMI" to the
# corresponding per-CB files.
def process_line(line, output_dirs):
    cell_barcode, umi, pseumo_barcode, shrna = line.strip().split('\t')
    with open(f'{output_dirs["PseuTag"]}/{cell_barcode}.txt', 'a') as pseumo_file:
        pseumo_file.write(f'{pseumo_barcode}\t{umi}\n')
    with open(f'{output_dirs["HashTag"]}/{cell_barcode}.txt', 'a') as shrna_file:
        shrna_file.write(f'{shrna}\t{umi}\n')

# Prepare the output directories (with an interactive overwrite prompt), then
# process the input file in parallel (output line order is not preserved).
def main(input_file_path, output_dirs, num_cpus):
    for dir_path in output_dirs.values():
        if os.path.exists(dir_path):
            # Ask before deleting an existing directory.
            response = input(f"The directory '{dir_path}' already exists. Do you wish to delete all its contents? [y/N]: ")
            if response.lower() == 'y':
                shutil.rmtree(dir_path)
                print(f"Deleted: {dir_path}")
                os.makedirs(dir_path)
            else:
                print(f"Deletion skipped: {dir_path}")
        else:
            os.makedirs(dir_path)

    with open(input_file_path, 'r') as file, ProcessPoolExecutor(max_workers=num_cpus) as executor:
        future_to_line = {executor.submit(process_line, line, output_dirs): line for line in file}
        for future in future_to_line:
            future.result()

# ------------------------------------------------------------------
# 2. Entry point
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Split a 4-column barcode table per cell barcode.')
    parser.add_argument('--input', type=str, required=True, help='Input file path')
    parser.add_argument('--pseutag', type=str, default='process/split_PseuTag', help='Output directory for PseuMO-Tag')
    parser.add_argument('--hashtag', type=str, default='process/split_HashTag', help='Output directory for HashTag (shRNA)')
    parser.add_argument('--cores', type=int, default=4, help='Number of CPUs (default 4)')
    args = parser.parse_args()

    output_dirs = {
        'PseuTag': args.pseutag,
        'HashTag': args.hashtag,
    }

    sys.stdout.write("Analyzing...")
    sys.stdout.flush()

    main(args.input, output_dirs, args.cores)

    sys.stdout.write("\r" + " " * len("Analyzing...") + "\r")
    sys.stdout.flush()
