#!/bin/bash
# BCDs_combiner.sh (K. Miyata, JFCR)
#
# Combine the error-corrected "CB", "UMI", "PseuMO-Tag" and "HashTag" columns
# into a single table, then remove any row containing "UNK" in any column.
#
# Usage:
#   bash BCDs_combiner.sh <sampleName>
#
# Column order: 1:CB, 2:UMI, 3:PseuTag, 4:HashTag

sampleName=$1

paste process/${sampleName}_R1_CB_mod.txt \
      process/${sampleName}_R1_UMI_mod.txt \
      process/${sampleName}_R2_PseuTag_mod.txt \
      process/${sampleName}_R2_HashTag_mod.txt > process/${sampleName}_cTable_tmp.txt

# Drop rows in which any of the four columns is "UNK"
awk '!($1 ~ /UNK/ || $2 ~ /UNK/ || $3 ~ /UNK/ || $4 ~ /UNK/)' process/${sampleName}_cTable_tmp.txt > ${sampleName}_cTable.txt
