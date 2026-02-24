#!/bin/bash

# extensions.conf から渡された引数
FAXFILE=$1
# Asterisk の FAXSTATUS 変数（SUCCESS, FAILED など）を2つ目の引数で受け取る
FAXSTATUS=$2

FILENAME=$(basename "$FAXFILE")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# =========================================================
# 【設定】ご自身のネットワークプリンタのIPアドレスに変更してください
PRINTER_IP="192.168.1.221"
PRINTER_PORT="9100"
# =========================================================

# 1. 画像ファイルが存在するかチェック (FAX受信失敗時の処理)
if [ ! -f "$FAXFILE" ]; then
  curl -H "Title: FAX受信失敗" \
       -H "Priority: high" \
       -H "Tags: warning" \
       -d "受信処理が行われましたが、画像データが生成されませんでした。(ステータス: ${FAXSTATUS:-不明})" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
  exit 1
fi

# 2. 受信成功の通知
MESSAGE="FAXを受信しました (${DATETIME}) ファイル名: ${FILENAME} (ステータス: ${FAXSTATUS})"
curl -H "Title: FAX受信完了" \
     -H "Priority: default" \
     -H "Tags: fax,page_facing_up" \
     -d "${MESSAGE}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS

# 3. TIFFファイルをPDFに変換 (A4サイズに合わせて変換)
PDFFILE="${FAXFILE%.*}.pdf"
tiff2pdf -o "$PDFFILE" -p A4 -F "$FAXFILE"

if [ $? -ne 0 ]; then
  curl -H "Title: FAX印刷エラー" \
       -H "Priority: high" \
       -H "Tags: warning" \
       -d "TIFFからPDFへの変換に失敗しました。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
  exit 1
fi

# 4. プリンタの9100ポートへPDFデータを直接送信
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
       -d "プリンタ ($PRINTER_IP) への通信に失敗しました。電源やIPを確認してください。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
fi

# 一時的に作成したPDFファイルを削除 (元のTIFFファイルは残します)
rm -f "$PDFFILE"