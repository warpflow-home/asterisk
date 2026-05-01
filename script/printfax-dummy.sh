#!/bin/bash

# ダミー用の固定一時ファイル名を生成
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
PDFFILE="/tmp/dummy_fax_$$.pdf"

# ダミーのPDFをインターネットからダウンロード
curl -sL "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf" -o "$PDFFILE"

# CUPSサーバーのIPと、ジョブの実行ユーザーを明示的に指定
CUPS_SERVER="cups" lp -d Canon_G3060 -o media=A4 -o fit-to-page "$PDFFILE"

if [ $? -eq 0 ]; then
    if [ -n "$NTFY_URL" ]; then
        curl -s -H "Title: FAX印刷成功" \
             -H "Tags: printer" \
             -d "プリンタへデータを送信しました。" \
             "${NTFY_URL}" > /dev/null
    fi
else
    if [ -n "$NTFY_URL" ]; then
        curl -s -H "Title: FAX印刷エラー" \
             -H "Priority: high" \
             -H "Tags: warning" \
             -d "CUPSへの印刷ジョブ投入に失敗しました。" \
             "${NTFY_URL}" > /dev/null
    fi
fi

# 一時ファイルの削除
rm -f "$PDFFILE"