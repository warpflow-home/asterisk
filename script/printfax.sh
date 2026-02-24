#!/bin/bash

FAXFILE=$1
FAXSTATUS=$2

FILENAME=$(basename "$FAXFILE")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# =========================================================
# 【設定】プリンタのIPアドレス
PRINTER_IP="192.168.1.221"
# Canon G3060 の AirPrint (IPP) 用URI
PRINTER_URI="ipp://${PRINTER_IP}/ipp/print"
# ipptool用の標準印刷ジョブ定義ファイル
IPP_TEST_FILE="/usr/share/cups/ipptool/print-job.test"
# =========================================================

# 1. 画像ファイルが存在するかチェック (FAX受信失敗時のダミーテスト)
if [ ! -f "$FAXFILE" ]; then
  curl -H "Title: FAX受信失敗" \
       -H "Priority: high" \
       -H "Tags: warning" \
       -d "画像データが生成されませんでした(ステータス: ${FAXSTATUS})。IPP(AirPrint)通信テストのためダミーPDFを送信します。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS

  DUMMY_PDF="/tmp/dummy_test.pdf"
  curl -sL "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf" -o "$DUMMY_PDF"

  if [ -f "$DUMMY_PDF" ]; then
    # 【変更】ipptool を使ってプリンタにPDFを送信
    ipptool -tv -f "$DUMMY_PDF" "$PRINTER_URI" "$IPP_TEST_FILE"
    
    if [ $? -eq 0 ]; then
      curl -H "Title: ダミー印刷完了" \
           -H "Tags: printer" \
           -d "プリンタ ($PRINTER_IP) へIPP経由でダミーデータを送信しました。" \
           https://ntfy.sh/KxgaRAdAYycAOnTS
    else
      curl -H "Title: FAX印刷通信エラー" \
           -H "Priority: high" \
           -H "Tags: warning" \
           -d "プリンタ ($PRINTER_IP) へのIPP通信に失敗しました。" \
           https://ntfy.sh/KxgaRAdAYycAOnTS
    fi
    rm -f "$DUMMY_PDF"
  fi
  exit 1
fi

# 2. 受信成功の通知
MESSAGE="FAXを受信しました (${DATETIME}) ファイル名: ${FILENAME} (ステータス: ${FAXSTATUS})"
curl -H "Title: FAX受信完了" \
     -H "Priority: default" \
     -H "Tags: fax,page_facing_up" \
     -d "${MESSAGE}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS

# 3. TIFFファイルをPDFに変換
PDFFILE="${FAXFILE%.*}.pdf"
tiff2pdf -o "$PDFFILE" -p A4 -F "$FAXFILE"

if [ $? -ne 0 ]; then
  curl -H "Title: FAX印刷エラー" \
       -H "Priority: high" \
       -d "TIFFからPDFへの変換に失敗しました。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
  exit 1
fi

# 4. 【変更】ipptool を使って本番のPDFをプリンタに送信
ipptool -tv -f "$PDFFILE" "$PRINTER_URI" "$IPP_TEST_FILE"

if [ $? -eq 0 ]; then
  curl -H "Title: FAX印刷完了" \
       -H "Tags: printer" \
       -d "プリンタ ($PRINTER_IP) へ印刷データを送信しました。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
else
  curl -H "Title: FAX印刷通信エラー" \
       -H "Priority: high" \
       -d "プリンタ ($PRINTER_IP) への通信に失敗しました。" \
       https://ntfy.sh/KxgaRAdAYycAOnTS
fi

rm -f "$PDFFILE"