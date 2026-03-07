#!/bin/bash

# $1 には extensions.conf から渡された発信者番号が入ります
CALLER_ID=$1
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# 通知メッセージの作成
MESSAGE="call:${CALLER_ID} (${DATETIME})"

# ntfy.sh へ通知を送信 (NTFY_URLが設定されている場合のみ)
if [ -n "$NTFY_URL" ]; then
    curl -s -H "Title: 着信通知" \
         -H "Priority: default" \
         -d "${MESSAGE}" \
         "${NTFY_URL}" > /dev/null
fi