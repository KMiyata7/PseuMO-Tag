# PseuMO-Tag (28 bp) barcode analysis pipeline

Processing and barcode-matrix generation for PseuMO-Tag amplicon sequencing,
using the 28 bp barcode structure `NNNGTNNNCTNNNAGNNNTGNNNCANNN`.

The workflow has two stages:

1. **Read processing** (`PseuTag_Processor.sh`) — trims adapters, keeps reads
   of exactly 28 bp that match the barcode pattern, filters by quality, and
   exports the barcode sequence of every surviving read.
2. **Matrix generation** (`mtxGenerator/`) — merges the per-sample barcodes,
   error-corrects them with `starcode`, splits them back per sample, and builds
   a barcode-by-sample count matrix.

## Directory layout

```
PseuMO-Tag_28bp/
├── PseuTag_Processor.sh          # Stage 1: read processing
├── mtxGenerator/
│   ├── PseuTag_mtxGenerator.sh   # Stage 2: driver (merge → correct → split → count)
│   ├── PseuTag_corrector.py      #   called by the driver (reshape starcode output)
│   └── PseuTag_counter.py        #   called by the driver (build the count matrix)
├── README.md
└── LICENSE
```

## Requirements

Stage 1 (`PseuTag_Processor.sh`):

- `fastqc`, `cutadapt`, `pigz`, `seqkit`
- `figlet` and `lolcat` are **optional** (used only for the startup banner; the
  script runs normally without them).

Stage 2 (`mtxGenerator/`):

- `starcode`
- Python 3 with `numpy`

## Usage

### Stage 1 — read processing

Prepare a sample list and the FastQ files:

```
sample_list.txt        # one sample name per line, e.g. cont1_S3
Fastq/${sampleName}_R1.fastq.gz
```

Run:

```bash
bash PseuTag_Processor.sh --sampleList sample_list.txt
```

Main outputs (per sample):

- `process/${sampleName}/Fastq_process/${sampleName}_R1_{1..5}.fastq.gz` —
  intermediate files for each filtering step.
- `process/${sampleName}/${sampleName}.txt` — barcode sequence of every
  surviving read (input to stage 2).
- `process/Stats_before.tsv`, `process/Stats_after.tsv` — read statistics.

### Stage 2 — barcode matrix

Run from the directory that contains `process/` (the output of stage 1):

```bash
sh mtxGenerator/PseuTag_mtxGenerator.sh sample_list.txt result.csv
```

Arguments (all optional):

1. sample list (default `sample_list.txt`)
2. output matrix (default `result.csv`)
3. directory holding the helper scripts (default: the driver's own directory,
   i.e. `mtxGenerator/`)

Main outputs:

- `PseuTag_Uniq.txt` — the unique, error-corrected barcodes.
- `result.csv` — the barcode-by-sample count matrix.
- `Barcode_correct/${sampleName}.txt` — per-sample corrected barcodes.

## Notes

- The error-correction distance in stage 2 is a Levenshtein distance of 2
  (`starcode --dist 2 --sphere`).
- Barcode matching is case-insensitive when the matrix is built.
