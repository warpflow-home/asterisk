#!/bin/bash

# extensions.conf から渡された引数
FAXFILE=$1
FAXSTATUS=$2

FILENAME=$(basename "$FAXFILE")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
PDFFILE="${FAXFILE%.*}.pdf"

# 通知用の補助関数 (NTFY_URLが設定されている場合のみ実行)
send_ntfy() {
    local title=$1
    local priority=${2:-default}
    local tags=$3
    local message=$4

    if [ -n "$NTFY_URL" ]; then
        curl -s -H "Title: ${title}" \
             -H "Priority: ${priority}" \
             -H "Tags: ${tags}" \
             -d "${message}" \
             "${NTFY_URL}" > /dev/null
    fi
}

# =========================================================
# 1. ファイルの存在チェックと通知
# =========================================================
if [ ! -f "$FAXFILE" ]; then
    send_ntfy "FAX受信失敗" "high" "warning" "画像データが生成されませんでした(ステータス: ${FAXSTATUS:-不明})。"
    exit 1
fi

send_ntfy "FAX受信完了" "default" "fax,page_facing_up" "FAXを受信しました。印刷を開始します。ファイル: ${FILENAME}"

# TIFFをPDFに変換 (DPI情報を維持して変換)
tiff2pdf -o "$PDFFILE" "$FAXFILE"

# =========================================================
# 2. Nextcloud (WebDAV) へPDFを保存
# =========================================================
# 必要な環境変数がすべて揃っている場合のみ実行
if [ -n "$NC_URL" ] && [ -n "$NC_USER" ] && [ -n "$NC_APP_PASSWORD" ]; then
    # URLの末尾のスラッシュを整理してパスを結合
    BASE_URL="${NC_URL%/}"
    WEBDAV_PATH="${BASE_URL}/remote.php/dav/files/${NC_USER}/FAX/${FILENAME}.pdf"

    curl -s -u "${NC_USER}:${NC_APP_PASSWORD}" -T "$PDFFILE" "${WEBDAV_PATH}"
else
    send_ntfy "FAX保存スキップ" "default" "information_source" "Nextcloudの設定が不足しているため、WebDAVへの保存をスキップしました。"
fi

# =========================================================
# 3. CUPS経由で印刷実行
# =========================================================
CUPS_SERVER="cups" lp -d Canon_G3060 -o media=A4 -o fit-to-page "$PDFFILE"

if [ $? -eq 0 ]; then
    send_ntfy "FAX印刷成功" "default" "printer" "プリンタへデータを送信しました。"
else
    send_ntfy "FAX印刷エラー" "high" "warning" "CUPSへの印刷ジョブ投入に失敗しました。"
fi

# 一時ファイルの削除
rm -f "$PDFFILE"