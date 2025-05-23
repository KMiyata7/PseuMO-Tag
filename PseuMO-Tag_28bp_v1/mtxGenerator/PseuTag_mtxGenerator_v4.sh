#!/bin/bash
# PseuTag_mtxGenerator.sh
# K.Miyata, JFCR
# 複数のPseuTagテキストファイルを結合し, Error correct後に, 再分割する. 最後に, サンプル毎にBarcode matrixを作成する.
# v1: 24.10.15
# v2: 25.03.09: sample listを引数から指定できるように変更. 'PseuTag_mtxGenerator.sh'を稼働するために必要な他のProgramのpassを設定
# v4: 25.04.04: Change the Levenshtein distance to 2.
# Ex: sh codes/PseuTag_mtxGenerator_v2.sh [1.sample_list.txt] [2.result.csv] [3./Volumes/Shared/Miyata/Epi_Dry/0.originalCodes_240327/PseuMO-Tag/mtxGenerator];
# NEED FILEs
# 1. sample_list.txt
  # $ cat sample_list.txt
  # TEST1
  # TEST2
  # TEST3
  # TEST4
  # TEST5
# 2. Barcode
  # "process/${sampleName}/${sampleName}.txt"が必要
  # $ cat /Volumes/Shared2/Miyata/Epi_Dry/1.AmpliconSeq/250217_2_AsPC1_DTP_2/process/cont1_S3/cont1_S3.txt | head -n 3
  # CTCGTAGACTGGGAGTTATGAGTCAGCG
  # CAAGTGTGCTGTCAGCCATGGTTCATTT
  # GCAGTGACCTCGGAGGCTTGGTTCATGA

set -e;
mkdir -p Barcode_correct process;
# sample_list="sample_list.txt" # 結合するファイルリストをsample_list.txtから読み込む
sample_list=${1:-"sample_list.txt"} # 結合するファイルリストをsample_list.txtから読み込む
result_file=${2:-"result.csv"} 
analysis_dir=${3:-"/Volumes/Shared/Miyata/Epi_Dry/0.originalCodes_240327/PseuMO-Tag/mtxGenerator"}  # 'PseuTag_mtxGenerator.sh'を稼働するために必要な他のProgramのpass

line_count_file="process/line_counts.txt" # 行数を保存するファイル（processディレクトリに保存）
merged_file="process/merged_file.txt" # 結合後のファイル（processディレクトリに保存）
processed_file="process/processed_file.txt" # Error correct後のファイル

# sample_list.txtの存在確認
if [[ ! -f $sample_list ]]; then
  echo "Error: $sample_list not found!" >&2
  exit 1
fi

# 1. 各ファイルの行数を取得して保存
> $line_count_file  # 行数ファイルを初期化
> $merged_file      # 結合ファイルを初期化

# ファイル名を保存するリスト
file_names=()

mkdir -p Barcode;
while read i; do
  cp process/${i}/${i}.txt Barcode
done < $sample_list

# sample_list.txt内のファイルをループで処理
echo '1 of 6: MERGE BARCODEs';
while read -r file; do
  echo $file
  file_names+=("$file")  # ファイル名をリストに追加
  # 各ファイルの行数を取得しline_counts.txtに記録
  if [[ -f Barcode/"$file".txt ]]; then
    wc -l Barcode/"$file".txt | awk '{print $1}' >> $line_count_file
    # ファイルを結合してmerged_file.txtに追加
    cat Barcode/"$file".txt >> $merged_file
  else
    echo "File $file.txt not found" >&2
  fi
done < $sample_list

# 2. MergeしたPseuTagファイルに対して, Error correctを実施
echo '2 of 6: ERROR CORRECT';
starcode --input $merged_file --dist 2 --sphere --output process/merged_file_starcode.txt --seq-id --quiet;
python ${analysis_dir}/PseuTag_corrector_v3.2.py --input process/merged_file_starcode.txt --output $processed_file;

# 3. 保存された行数に基づいてファイルを再度分割
echo '4 of 6: SPLIT MERGED BARCODEs';
start_line=1
i=0
while read -r line_count; do
  end_line=$((start_line + line_count - 1))
  # ファイル名を取得して、$file_processed.txtとして保存
  file="${file_names[$i]}"
  sed -n "${start_line},${end_line}p" $processed_file > Barcode_correct/"${file}.txt"
  start_line=$((end_line + 1))
  i=$((i + 1))
done < $line_count_file

# Uniq PseuTagを出力
echo '5 of 6: EXPORT UNIQUE BARCODEs';
if [[ -f PseuTag_Uniq.txt ]]; then
  echo "Warning: PseuTag_Uniq.txt will be overwritten." >&2
fi
sort $processed_file | uniq > PseuTag_Uniq.txt;

# 4. "PseuTag_Uniq.txt"を行, "sample_list.txt"を列として, Barcode_correctディレクトリ内に含まれているバーコードの出現回数をカウントする
echo '6 of 6: EXPORT BARCODE MATRIX';
# python ${analysis_dir}/PseuTag_counter_v1.py
python ${analysis_dir}/PseuTag_counter_v2.py $sample_list $result_file

echo "Processing completed!"
