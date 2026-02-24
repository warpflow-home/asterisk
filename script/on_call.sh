#!/bin/bash

# $1 には extensions.conf から渡された発信者番号が入ります
CALLER_ID=$1
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# 通知メッセージの作成
MESSAGE="着信がありました: 発信者番号 ${CALLER_ID} (${DATETIME})"

# ntfy.sh へ通知を送信 (タイトルとアイコンタグ付き)
curl -H "Title: 着信通知" \
     -H "Tags: telephone_receiver" \
     -H "Priority: default" \
     -d "${MESSAGE}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS