#!/bin/bash

# extensions.conf から渡された引数
FAXFILE=$1
FAXSTATUS=$2

FILENAME=$(basename "$FAXFILE")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
PDFFILE="${FAXFILE%.*}.pdf"

curl -sL "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf" -o "$PDFFILE"
tiff2pdf -o "$PDFFILE" -p A4 -F "$FAXFILE"
lp -h localhost:631 -d Canon_G3060 -o media=A4 -o fit-to-page "$PDFFILE"

if [ $? -eq 0 ]; then
    curl -H "Title: FAX印刷成功" \
         -H "Tags: printer" \
         -d "プリンタへデータを送信しました。" \
         https://ntfy.sh/KxgaRAdAYycAOnTS
else
    curl -H "Title: FAX印刷エラー" \
         -H "Priority: high" \
         -H "Tags: warning" \
         -d "CUPSへの印刷ジョブ投入に失敗しました。" \
         https://ntfy.sh/KxgaRAdAYycAOnTS
fi

# 一時ファイルの削除
rm -f "$PDFFILE"