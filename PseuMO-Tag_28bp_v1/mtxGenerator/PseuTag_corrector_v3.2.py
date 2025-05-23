#!/usr/bin/env python
# PseuTag_corrector.py
# v1: 24.04.06
# v2: 24.04.07 BCD count plotも出力されるように追記
# v3: 24.04.09 微修正
# v3.2: 24.10.15 plotを削除
# PseuMO-Tag(R2からshRNAを削った9~11bp)のPCRエラーを修正する
# USAGE: python ${AnalyzerDir}/PseuTag_corrector_v3.py --input [starcodeによるエラー修正後のファイル] --output [出力ファイル];
# EXAMP: python ${AnalyzerDir}/PseuTag_corrector_v3.py --input process/${sampleName}_R2_PseuTag_star.txt --output process/${sampleName}_R2_PseuTag_mod.txt;

# ********************************************************
# 0. 必要なモジュールのインポート
import time
import os
import argparse
import pandas as pd
import numpy as np
import glob
# ********************************************************

# ********************************************************
# 1. 関数の定義
def process_file(input_file, output_file):
    output_lines = {} # 各行に配置する名前を保持する辞書

    with open(input_file, 'r', encoding='utf-8') as file:
        for line in file:
            # 入力ファイルをタブで分割. 1列目:name(Seq of BCD), 2列目:無視(検出頻度), 3列目:indices(インデックス)
            name, _, indices = line.strip().split('\t')
            for index in indices.split(','): # カンマ区切りのインデックスを分解
                idx = int(index.strip())
                output_lines[idx] = name # インデックスに修正後のBCDを格納するための辞書

    # 最大インデックスを取得し、出力ファイルを生成 (出力ファイルにすべてのインデックスに対応する行を確実に含めるため)
    max_index = max(output_lines.keys())
    with open(output_file, 'w', encoding='utf-8') as file:
        for i in range(1, max_index + 1):
            file.write(f"{output_lines.get(i, '')}\n")
# ********************************************************

# ********************************************************
# 2. 関数の実行
start_time = time.time()

# *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** 
parser = argparse.ArgumentParser(description='Error correction of Barcodes.')
parser.add_argument('--input', type=str, required=True, help='Input file path. process/${sampleName}_R2_PseuTag_star.txt or process/${sampleName}_R2_UMI_star.txt is strongly recommended')
parser.add_argument('--output', type=str, required=True, help='Output directory for PseuMO')
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
# print("START: ", start_time_str, ", END: ", end_time_str, ", TOTAL: ", elapsed_time_str)
# ********************************************************
