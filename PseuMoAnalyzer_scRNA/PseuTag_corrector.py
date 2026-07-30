#!/usr/bin/env python
# PseuTag_corrector.py (K. Miyata, JFCR)
#
# Correct PCR errors in the PseuMO-Tag (the 9-11 bp remaining after removing the
# shRNA tag from R2). The input is a starcode output; this script expands the
# clustered barcodes back to their original read order and also draws Pareto
# charts of the barcode counts.
#
# Usage:
#   PseuTag_corrector.py --input <starcode output> --output <output txt> \
#                        --sampleName <sampleName> --tagName <PseuTag|UMI>
# Example:
#   PseuTag_corrector.py --input process/${sampleName}_R2_PseuTag_star.txt \
#                        --output process/${sampleName}_R2_PseuTag_mod.txt \
#                        --sampleName ${sampleName} --tagName PseuTag

import os
import glob
import argparse
import pandas as pd
import matplotlib.pyplot as plt

# ------------------------------------------------------------------
# 1. Function

def process_file(input_file, output_file):
    output_lines = {}  # index -> corrected barcode

    with open(input_file, 'r', encoding='utf-8') as file:
        for line in file:
            # starcode output columns: 1) name (barcode seq), 2) count (ignored),
            # 3) indices (comma-separated read indices).
            name, _, indices = line.strip().split('\t')
            for index in indices.split(','):
                idx = int(index.strip())
                output_lines[idx] = name

    # Write every index from 1..max so that all reads are represented (empty if missing).
    max_index = max(output_lines.keys())
    with open(output_file, 'w', encoding='utf-8') as file:
        for i in range(1, max_index + 1):
            file.write(f"{output_lines.get(i, '')}\n")

# ------------------------------------------------------------------
# 2. Run
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Error correction of barcodes (PseuMO-Tag or UMI).')
    parser.add_argument('--input', type=str, required=True,
                        help='Input file path (starcode output, e.g. process/${sampleName}_R2_PseuTag_star.txt)')
    parser.add_argument('--output', type=str, required=True, help='Output file path')
    parser.add_argument('--sampleName', type=str, required=True, help='Sample name')
    parser.add_argument('--tagName', type=str, required=True, help='PseuTag or UMI')
    args = parser.parse_args()

    process_file(args.input, args.output)

    # --- Plotting -------------------------------------------------
    # Load the starcode count data for the corresponding tag.
    path_template = os.path.join("process", f"{args.sampleName}_R[12]_{args.tagName}_star.txt")
    plot_file_path = glob.glob(path_template)
    bcd_counts = pd.read_table(plot_file_path[0], header=None)

    # Sort counts in descending order and compute the cumulative percentage.
    sorted_counts = bcd_counts[1].sort_values(ascending=False)
    cumulative_percentage = sorted_counts.cumsum() / sorted_counts.sum() * 100

    # Pareto chart (linear scale)
    fig, ax1 = plt.subplots(figsize=(10, 8))
    ax1.bar(range(len(sorted_counts)), sorted_counts, color='C0')
    ax2 = ax1.twinx()
    ax2.plot(range(len(cumulative_percentage)), cumulative_percentage, color='C1', marker='D', ms=7, label='Cumulative %')
    ax1.set_xlabel('Tags')
    ax1.set_ylabel('Counts (Unique Barcodes)', color='C0')
    ax2.set_ylabel('Cumulative Percentage (%)', color='C1')
    ax1.tick_params(axis='y', colors='C0')
    ax2.tick_params(axis='y', colors='C1')
    fig.tight_layout()
    fig_name1 = 'Plots/ParetoChart_' + args.sampleName + '_' + args.tagName + '.jpeg'
    plt.savefig(fig_name1, format='jpeg')

    # Pareto chart (log10 scale)
    fig, ax2 = plt.subplots(figsize=(10, 8))
    ax2.bar(range(len(sorted_counts)), sorted_counts, color='C0')
    ax2.set_yscale('log')
    ax2.set_xlabel('Tags')
    ax2.set_ylabel('log10 Counts (Unique Barcodes)')
    plt.tight_layout()
    fig_name2 = 'Plots/ParetoChartLog_' + args.sampleName + '_' + args.tagName + '.jpeg'
    plt.savefig(fig_name2, format='jpeg')
    plt.close()
