#!/usr/bin/env python
# PseuTag_corrector.py
# Author: K. Miyata, JFCR
#
# Change log:
#   v1   (2024/04/06) : Initial version.
#   v2   (2024/04/07) : Added a barcode-count plot.
#   v3   (2024/04/09) : Minor fixes.
#   v3.2 (2024/10/15) : Removed the plot.
#
# Purpose:
#   Reconstruct per-read barcodes after error correction. Given the
#   starcode output (clustered barcodes with the read indices that belong
#   to each cluster), write one corrected barcode per line, ordered by the
#   original read index.
#
# USAGE:
#   python ${AnalyzerDir}/PseuTag_corrector.py --input [starcode output] --output [output file]
# EXAMPLE:
#   python ${AnalyzerDir}/PseuTag_corrector.py --input process/merged_file_starcode.txt --output process/processed_file.txt

# ********************************************************
# 0. Imports
import time
import argparse
# ********************************************************

# ********************************************************
# 1. Function definition
def process_file(input_file, output_file):
    output_lines = {}  # Maps original read index -> corrected barcode

    with open(input_file, 'r', encoding='utf-8') as file:
        for line in file:
            # Each starcode line is tab-separated:
            #   column 1: name (corrected barcode sequence)
            #   column 2: ignored (cluster count)
            #   column 3: indices (comma-separated original read indices)
            name, _, indices = line.strip().split('\t')
            for index in indices.split(','):  # Split the comma-separated indices
                idx = int(index.strip())
                output_lines[idx] = name  # Store the corrected barcode at this index

    # Determine the largest index and write one line per index so that every
    # original read position is represented in the output (gaps stay empty).
    max_index = max(output_lines.keys())
    with open(output_file, 'w', encoding='utf-8') as file:
        for i in range(1, max_index + 1):
            file.write(f"{output_lines.get(i, '')}\n")
# ********************************************************

# ********************************************************
# 2. Run
start_time = time.time()

# *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
parser = argparse.ArgumentParser(description='Error correction of barcodes.')
parser.add_argument('--input', type=str, required=True,
                    help='Input file path (starcode output, e.g. process/merged_file_starcode.txt).')
parser.add_argument('--output', type=str, required=True,
                    help='Output file path for the corrected barcodes.')
args = parser.parse_args()
process_file(args.input, args.output)
# *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

end_time = time.time()
elapsed_time = end_time - start_time
hours = int(elapsed_time // 3600)
minutes = int((elapsed_time % 3600) // 60)
start_time_str = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(start_time))
end_time_str = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(end_time))
elapsed_time_str = f"{hours} hr, {minutes} min" if hours > 0 else f"{minutes} min"
# print("START:", start_time_str, ", END:", end_time_str, ", TOTAL:", elapsed_time_str)
# ********************************************************
