# Ref/

Place the reference files required by the pipeline here. They are **not** bundled
with this repository because they are experiment-specific.

- `CB.txt` — post-QC 16 bp cell barcodes exported from your scRNA-seq object
  (one per line; a trailing `-1` is optional).
- `AllowList_PseuTag.txt` — expected PseuMO-Tag sequences (one per line);
  these become the columns of `PseuTag_matrix.csv`.
- `AllowList_HashTag.txt` — expected HashTag names (one per line);
  these become the columns of `HashTag_matrix.csv` and must match the names
  produced by `HashTag_converter.py`.

See the main [README](../README.md) for full format details.
