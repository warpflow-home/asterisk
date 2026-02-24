#!/bin/bash

# extensions.conf から渡されたFAXのファイルパス ($1)
FAXFILE=$1
FILENAME=$(basename "$FAXFILE")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# 通知メッセージの作成
MESSAGE="FAXを受信しました (${DATETIME}) ファイル名: ${FILENAME}"

# ntfy.sh へ通知を送信 (すでに on_call.sh でお使いのトピックへ通知します)
curl -H "Title: FAX受信完了" \
     -H "Priority: high" \
     -d "${MESSAGE}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS

# ==========================================================
# ※必要に応じてここに TIFF から PDF への変換処理などを追記します。
# 例:
# tiff2pdf -o "${FAXFILE%.*}.pdf" "${FAXFILE}"
# ==========================================================