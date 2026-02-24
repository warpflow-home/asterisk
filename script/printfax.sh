#!/bin/bash

FAXFILE=$1
FAXSTATUS=$2
PDFFILE="${FAXFILE%.*}.pdf"

# 1. FAX受信失敗時のダミー処理
if [ ! -f "$FAXFILE" ]; then
    curl -H "Title: FAX受信失敗" -d "画像がないためダミーを印刷します" https://ntfy.sh/KxgaRAdAYycAOnTS
    curl -sL "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf" -o "$PDFFILE"
else
    # 2. 正常受信時のTIFF -> PDF変換
    tiff2pdf -o "$PDFFILE" -p A4 -F "$FAXFILE"
fi

# 3. CUPS（localhost:631）経由で印刷実行
# -h localhost:631 は hostnet を使っているため有効です
lp -h localhost:631 -d Canon_G3060 -o media=A4 -o fit-to-page "$PDFFILE"

if [ $? -eq 0 ]; then
    curl -H "Title: FAX印刷成功" -d "CUPS経由でプリンタへ送りました" https://ntfy.sh/KxgaRAdAYycAOnTS
else
    curl -H "Title: FAX印刷失敗" -d "CUPSへの送信に失敗しました" https://ntfy.sh/KxgaRAdAYycAOnTS
fi

rm -f "$PDFFILE"