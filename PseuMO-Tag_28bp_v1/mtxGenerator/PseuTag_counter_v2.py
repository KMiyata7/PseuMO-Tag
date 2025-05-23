# PseuTag_counter.py
# K.Miyata, JFCR
# v1: 24.10.15
# v2: 25.03.09: sample_listとoutput_fileを引数で指定できるように変更
# Ex: python codes/PseuTag_counter_v2.py [sample_list.txt] [result.csv];
# "PseuTag_Uniq.txt"を行, "sample_list.txt"を列として, Barcode_correctディレクトリ内に含まれているバーコードの出現回数をカウントする

import os
import numpy as np
import csv
import sys

# Get command-line arguments
if len(sys.argv) > 2:
    sample_list_file = sys.argv[1]
    output_csv_file = sys.argv[2]
else:
    print("Usage: python PseuTag_counter_v2.py [sample_list.txt] [result.csv]")
    sys.exit(1)

# ファイルのパスを指定
pseutag_file = 'PseuTag_Uniq.txt'
# sample_list_file = 'sample_list.txt'
barcode_correct_dir = 'Barcode_correct'
# output_csv_file = 'result.csv'

# 行名と列名を読み込む
with open(pseutag_file, 'r') as f:
    row_names = [line.strip().upper() for line in f.readlines()]  # 大文字小文字を無視
    # print(f"Row names: {row_names}")

with open(sample_list_file, 'r') as f:
    col_names = [line.strip() for line in f.readlines()]
    # print(f"Column names: {col_names}")

# 行数と列数を基にゼロ行列を作成
matrix = np.zeros((len(row_names), len(col_names)), dtype=int)

# 各ファイルについて行名の出現回数をカウントし、行列に追加
for col_idx, col_name in enumerate(col_names):
    file_path = os.path.join(barcode_correct_dir, f'{col_name}.txt')
    
    # ファイルが存在するか確認
    if not os.path.exists(file_path):
        print(f"ファイルが存在しません: {file_path}")
        continue
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read().upper()  # 大文字小文字を無視
        # print(f"Checking file: {file_path}")
        # print(f"File content: {content}")
    
    # 各行名の出現回数をカウントして行列に記録
    for row_idx, row_name in enumerate(row_names):
        count = content.count(row_name)
        matrix[row_idx, col_idx] = count
        # print(f"Row name: {row_name}, Count: {count}")

# 結果の行列をCSVファイルに書き込む
with open(output_csv_file, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)

    # 最初の行に列名（サンプル名）を追加
    writer.writerow([''] + col_names)

    # 各行に行名とそのデータを追加
    for row_idx, row_name in enumerate(row_names):
        writer.writerow([row_name] + list(matrix[row_idx]))
