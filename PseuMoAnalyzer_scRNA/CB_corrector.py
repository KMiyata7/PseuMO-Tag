#!/usr/bin/env python
# CB_corrector.py (K. Miyata, JFCR)
#
# Correct amplicon errors in the 16 bp cell barcode (CB) using the
# post-QC "Cellular Barcode" list from Seurat as the reference.
# A read that matches no reference within Hamming distance 1 is written as "UNK".
#
# Note: "Ref/CB.txt" is required. A trailing "-1" in the reference is optional.
#
# Usage:
#   CB_corrector.py --input <R1 16 bp txt> --output <error-corrected txt> [--cores <N>]
# Example:
#   CB_corrector.py --input process/${sampleName}_R1_selected.txt \
#                   --output process/${sampleName}_R1_mod.txt --cores 10

import os
import sys
import multiprocessing
from concurrent.futures import ProcessPoolExecutor, as_completed
import argparse

# ------------------------------------------------------------------
# 1. Load the reference: the 16 bp cellular barcodes from Seurat.
ref_file_path = "Ref/CB.txt"
if not os.path.exists(ref_file_path):
    print(f"Error: The file '{ref_file_path}' does not exist.")
    sys.exit(1)

target_strings = []
with open(ref_file_path, 'r') as file:
    for line in file:
        # Strip the newline and drop a trailing "-1" if present.
        cleaned_line = line.strip()
        if cleaned_line.endswith("-1"):
            cleaned_line = cleaned_line[:-2]
        target_strings.append(cleaned_line)

# ------------------------------------------------------------------
# 2. Functions

# Return True if the two strings differ at exactly one position.
def is_one_letter_diff(input_str, target_str):
    if len(input_str) != len(target_str):
        return False
    diff_count = 0
    for i in range(len(input_str)):
        if input_str[i] != target_str[i]:
            diff_count += 1
            if diff_count > 1:
                return False
    return diff_count == 1

# Return the input if it matches a reference exactly or within Hamming
# distance 1; otherwise return "UNK".
def check_string(input_str, target_strings):
    if input_str in target_strings:
        return input_str
    for target in target_strings:
        if is_one_letter_diff(input_str, target):
            return target
    return "UNK"

# Apply check_string to every line of a chunk and keep the original index.
def process_lines(chunk):
    index, lines = chunk
    results = [(index, check_string(line[1].strip(), target_strings)) for line in lines]
    return results

# Split a list into chunks of size n, yielding (start_index, chunk).
def chunkify(lst, n):
    for i in range(0, len(lst), n):
        yield i, lst[i:i + n]

# Read the input, process the chunks in parallel, restore the original
# order, and write the corrected barcodes to the output file.
def main(file_path, output_file, num_workers=None):
    with open(file_path, 'r') as file:
        lines = list(enumerate(file.readlines()))

    if not num_workers:
        num_workers = multiprocessing.cpu_count()

    # Guard against a chunk size of 0 when there are fewer lines than workers.
    chunk_size = max(1, len(lines) // num_workers)
    chunks = list(chunkify(lines, chunk_size))

    results = []
    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        future_to_chunk = {executor.submit(process_lines, chunk): chunk for chunk in chunks}
        for future in as_completed(future_to_chunk):
            results.extend(future.result())

    # Restore the original order by index and write the results.
    sorted_results = sorted(results, key=lambda x: x[0])
    with open(output_file, 'w') as file_out:
        for _, result in sorted_results:
            file_out.write(result + '\n')

# ------------------------------------------------------------------
# 3. Entry point
if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Correct amplicon errors in the 16 bp cell barcode using the '
                    'post-QC "Cellular Barcode" list from Seurat as the reference. '
                    'Unmatched barcodes are written as "UNK".')
    parser.add_argument('--input', help='R1 16 bp barcode text file', required=True)
    parser.add_argument('--output', help='Error-corrected text file', required=True)
    parser.add_argument('--cores', help='Number of CPUs (default 1)', default=1)
    args = parser.parse_args()
    main(args.input, args.output, int(args.cores))
