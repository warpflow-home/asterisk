#!/bin/bash

# ダミー用の固定一時ファイル名を生成
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
PDFFILE="/tmp/dummy_fax_$$.pdf"

# ダミーのPDFをインターネットからダウンロード
curl -sL "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf" -o "$PDFFILE"

# ダウンロードしたPDFをそのまま印刷 (tiff2pdfの処理は不要なため削除)
lp -h 192.168.1.240:631 -d Canon_G3060 -o media=A4 -o fit-to-page "$PDFFILE"

if [ $? -eq 0 ]; then
    curl -H "Title: FAX印刷成功" \
         -H "Tags: printer" \
         -d "プリンタへデータを送信しました。" \
         https://ntfy.warpflow.net/xw53brZ6HsWlyP6A
else
    curl -H "Title: FAX印刷エラー" \
         -H "Priority: high" \
         -H "Tags: warning" \
         -d "CUPSへの印刷ジョブ投入に失敗しました。" \
         https://ntfy.warpflow.net/xw53brZ6HsWlyP6A
fi

# 一時ファイルの削除
rm -f "$PDFFILE"