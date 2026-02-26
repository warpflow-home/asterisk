#!/bin/bash

# extensions.conf から渡された引数
FAXFILE=$1
FAXSTATUS=$2

FILENAME=$(basename "$FAXFILE")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
PDFFILE="${FAXFILE%.*}.pdf"

# =========================================================
# 1. ファイルの存在チェックと通知
# =========================================================
if [ ! -f "$FAXFILE" ]; then
    # FAX受信失敗時（内線電話の不在着信時など）
    curl -H "Title: FAX受信失敗" \
         -H "Priority: high" \
         -H "Tags: warning" \
         -d "画像データが生成されませんでした(ステータス: ${FAXSTATUS:-不明})。" \
         https://ntfy.sh/KxgaRAdAYycAOnTS
    
    # 印刷対象がないため、ここでスクリプトを終了
    exit 1
fi

# 実際のFAX受信成功時
curl -H "Title: FAX受信完了" \
     -H "Priority: default" \
     -H "Tags: fax,page_facing_up" \
     -d "FAXを受信しました。印刷を開始します。ファイル: ${FILENAME}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS

# TIFFをPDFに変換 (A4サイズ指定)
tiff2pdf -o "$PDFFILE" -p A4 -F "$FAXFILE"

# =========================================================
# 2. CUPS経由で印刷実行
# =========================================================
# -h localhost:631 は hostnet 環境でのCUPSコンテナ宛て
lp -h 192.168.1.240:631 -d Canon_G3060 -o media=A4 -o fit-to-page "$PDFFILE"

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