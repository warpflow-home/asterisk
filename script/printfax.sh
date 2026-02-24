#!/bin/bash

FAXFILE=$1
FILENAME=$(basename "$FAXFILE")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

MESSAGE="FAXを受信しました (${DATETIME}) ファイル名: ${FILENAME}"

curl -H "Title: FAX受信完了" \
     -H "Priority: high" \
     -H "Tags: fax,page_facing_up" \
     -d "${MESSAGE}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS

# ==========================================================
# 印刷スクリプトの呼び出し (バックグラウンド実行)
# ==========================================================
/var/lib/asterisk/scripts/print.sh "${FAXFILE}" &