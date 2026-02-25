#!/bin/bash

# 日時の取得
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# AsteriskのCLIコマンドを実行して結果を変数に格納
ENDPOINTS_INFO=$(asterisk -rx "pjsip show endpoints")

# ntfy.sh へ通知を送信 (タイトルとアイコンタグ付き)
curl -H "Title: PJSIP Endpoints Status" \
     -H "Priority: default" \
     -H "Tags: telephone_receiver" \
     -d "取得日時: ${DATETIME}

${ENDPOINTS_INFO}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS