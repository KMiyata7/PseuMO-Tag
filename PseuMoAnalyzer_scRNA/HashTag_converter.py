#!/usr/bin/env python
# HashTag_converter.py (K. Miyata, JFCR)
#
# Take the error-corrected 5 bp shRNA-tag file (output of HashTag_corrector.py)
# and convert each tag into its shRNA name. Tags with no entry are written as "UNK".
#
# Usage:
#   HashTag_converter.py --input <corrected txt> --output <converted txt>
# Example:
#   HashTag_converter.py --input process/${sampleName}_R2_HashTag_mod_tmp.txt \
#                        --output process/${sampleName}_R2_HashTag_mod.txt

import argparse

# ------------------------------------------------------------------
# shRNA tag-to-name map.
# NOTE: These entries are specific to this study; edit them for your own experiment.
shRNA_map = {
    "ATGCA": "SCR",
    "AGCTG": "KDM",
    "TGCTA": "SET",
    "CTGAA": "ARI",
    "GCCAA": "SMA",
}

# ------------------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Convert a 5 bp shRNA-tag file into shRNA names. '
                    'Tags with no entry are written as "UNK".')
    parser.add_argument('--input', help='Input file (5 bp shRNA-tag text)', required=True)
    parser.add_argument('--output', help='Output file (converted to shRNA names)', required=True)
    args = parser.parse_args()

    with open(args.input, 'r') as input_file, open(args.output, 'w') as output_file:
        for line in input_file:
            line = line.strip()
            output_line = shRNA_map.get(line, "UNK")
            output_file.write(output_line + '\n')
