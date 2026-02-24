#!/bin/bash

# 引数として渡されたFAXのTIFFファイルパス
FAXFILE=$1

# =========================================================
# 【設定】ご自身のネットワークプリンタのIPアドレスに変更してください
PRINTER_IP="192.168.1.221"  # ← ここを実際のプリンタのIPにする
PRINTER_PORT="9100"         # 多くのネットワークプリンタのRAW印刷用ポート
# =========================================================

if [ ! -f "$FAXFILE" ]; then
  echo "Error: File not found (${FAXFILE})"
  exit 1
fi

# 変換後のPDFファイルのパス
PDFFILE="${FAXFILE%.*}.pdf"

# 1. TIFFファイルをPDFに変換 (A4サイズに合わせて変換)
tiff2pdf -o "$PDFFILE" -p A4 -F "$FAXFILE"

if [ $? -ne 0 ]; then
  curl -H "Title: FAX印刷エラー" \
       -H "Priority: high" \
       -H "Tags: warning" \
       -d "TIFFからPDFへの変換に失敗しました。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
  exit 1
fi

# 2. プリンタの9100ポートへPDFデータを直接送信
nc -w 5 $PRINTER_IP $PRINTER_PORT < "$PDFFILE"

if [ $? -eq 0 ]; then
  curl -H "Title: FAX印刷完了" \
       -H "Tags: printer" \
       -d "プリンタ ($PRINTER_IP) へ印刷データを送信しました。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
else
  curl -H "Title: FAX印刷通信エラー" \
       -H "Priority: high" \
       -H "Tags: warning" \
       -d "プリンタ ($PRINTER_IP) への通信に失敗しました。電源やIPアドレスを確認してください。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
fi

# 一時的に作成したPDFファイルは削除 (元のTIFFファイルは残ります)
rm -f "$PDFFILE"