# PseuMoAnalyzer_scRNA

Analysis pipeline that links **clonal barcode information (the "PseuMO-Tag")** to
**single-cell transcriptomes**. Starting from amplicon-seq FASTQ files (amplified
from the 10x scRNA-seq library as template), the pipeline error-corrects the cell
barcode (CB), UMI, PseuMO-Tag and HashTag (shRNA tag), and produces per-cell
count matrices that can be merged with the corresponding scRNA-seq object
(e.g. a Seurat object) for downstream clone calling.

Author: K. Miyata, JFCR

## Outputs

Running the pipeline produces two CSV count matrices in the working directory:

- `PseuTag_matrix.csv` — rows: cell barcodes (CB), columns: PseuMO-Tags, values: UMI counts
- `HashTag_matrix.csv` — rows: cell barcodes (CB), columns: HashTags (shRNA), values: UMI counts

## Requirements

**External command-line tools** (must be on `PATH`):

- [starcode](https://github.com/gui11aume/starcode)
- [seqkit](https://bioinf.shenwei.me/seqkit/)
- [cutadapt](https://cutadapt.readthedocs.io/)
- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [pigz](https://zlib.net/pigz/)

**Python 3** with:

- pandas
- matplotlib
- numpy

The tools above are commonly available via `conda`/`mamba` (e.g. bioconda).

## Input layout

Place the paired-end amplicon-seq FASTQ files and the reference files as follows,
then run the pipeline from that working directory:

```
<working_dir>/
├── Fastq/
│   ├── <sampleName>_R1.fastq.gz   # R1: CB (1-16 bp) + UMI (17-28 bp)
│   └── <sampleName>_R2.fastq.gz   # R2: HashTag (5 bp) + PseuMO-Tag (~10 bp), flanked by PCR handles
└── Ref/
    ├── CB.txt
    ├── AllowList_PseuTag.txt
    └── AllowList_HashTag.txt
```

### Reference file formats

- **`Ref/CB.txt`** — the post-QC 16 bp cell barcodes exported from your scRNA-seq
  object (one barcode per line). A trailing `-1` (the 10x suffix) is optional and
  is stripped automatically. These are used as the reference for CB error correction.

  ```
  AAACCCAAGAAACCAT
  AAACCCAAGAAACTCA
  ...
  ```

- **`Ref/AllowList_PseuTag.txt`** — the list of expected PseuMO-Tag sequences
  (one per line). These become the columns of `PseuTag_matrix.csv`.

  ```
  ACGTACGTAC
  TGCATGCATG
  ...
  ```

- **`Ref/AllowList_HashTag.txt`** — the list of expected HashTag names
  (one per line). These become the columns of `HashTag_matrix.csv`, and must
  match the names produced by `HashTag_converter.py` (see below).

  ```
  SCR
  KDM
  SET
  ARI
  SMA
  ```

## Usage

```bash
# (activate the environment that provides starcode/seqkit/cutadapt/fastqc/pigz)
bash PseuMO_Decoder.sh --sampleName <SampleName> --nCores 10
```

Options for `PseuMO_Decoder.sh`:

- `--sampleName` : sample name (matches the `Fastq/<sampleName>_R{1,2}.fastq.gz` prefix)
- `--AnalyzerDir` : directory containing these scripts (default: the directory of `PseuMO_Decoder.sh`)
- `--nCores` : number of CPU cores (default: 10)

## Pipeline steps

`PseuMO_Decoder.sh` orchestrates the following:

1. **Trimming** (`PseuMO_trimmer.sh`) — remove PCR handles from R2, keep 19-21 bp
   reads without `N`, split R2 into HashTag (5 bp) and PseuMO-Tag, and extract the
   matching R1 into CB (16 bp) and UMI (12 bp).
2. **Error correction**
   - CB (`CB_corrector.py`, reference `Ref/CB.txt`, Hamming distance 1)
   - PseuMO-Tag (`starcode` + `PseuTag_corrector.py`)
   - UMI (`starcode` + `PseuTag_corrector.py`)
   - HashTag (`HashTag_corrector.py` + `HashTag_converter.py`)
3. **Combine** (`BCDs_combiner.sh`) — paste CB, UMI, PseuTag and HashTag columns and
   drop rows containing `UNK`.
4. **Split per CB** (`BCDs_splitter.py`) — write `PseuTag + UMI` and `HashTag + UMI`
   into per-cell files.
5. **UMI counting** (`umi_counter.py`) — deduplicate by UMI and remove UMIs supported
   by a single read.
6. **Tag counting** (`tags_counter_umi.py`) — count unique tags per CB against the
   allow lists and export the CSV matrices.

Downstream clone calling is performed separately in R and is **not** included in this repository.

## Experiment-specific values to edit

The following values are specific to the original study. Edit them to match your own experiment:

- **shRNA tags and names** — in `HashTag_corrector.py` (`target_strings`, the 5 bp
  reference tags) and `HashTag_converter.py` (`shRNA_map`, the tag-to-name map).
  Keep these two consistent with each other and with `Ref/AllowList_HashTag.txt`.
- **Adapter sequences** — in `PseuMO_trimmer.sh` (`frontAdapt`, `backAdapt`), or pass
  them on the command line via `--frontAdapt` / `--backAdapt`.
- **Read structure** — R1 is assumed to be CB (1-16 bp) + UMI (17-28 bp), and R2 is
  HashTag (first 5 bp) + PseuMO-Tag (bp 6-15). Adjust the `cut`/`subseq` ranges in
  `PseuMO_trimmer.sh` if your library differs.

## Files

| File | Role |
| --- | --- |
| `PseuMO_Decoder.sh` | Master pipeline (entry point) |
| `PseuMO_trimmer.sh` | Trimming and R1/R2 extraction |
| `CB_corrector.py` | Cell barcode error correction |
| `PseuTag_corrector.py` | PseuMO-Tag / UMI correction (post-starcode) + Pareto plots |
| `HashTag_corrector.py` | HashTag (shRNA) error correction |
| `HashTag_converter.py` | HashTag sequence-to-name conversion |
| `BCDs_combiner.sh` | Combine CB/UMI/PseuTag/HashTag columns |
| `BCDs_splitter.py` | Split combined table per cell barcode |
| `umi_counter.py` | UMI deduplication and counting |
| `tags_counter_umi.py` | Per-CB tag counting → CSV matrix |

## License

Released under the MIT License. See [LICENSE](LICENSE).
