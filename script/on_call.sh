#!/bin/bash

# $1 には extensions.conf から渡された発信者番号が入ります
CALLER_ID=$1
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# 通知メッセージの作成
MESSAGE="call:${CALLER_ID} (${DATETIME})"

# ntfy.sh へ通知を送信 (タイトルとアイコンタグ付き)
curl -H "Title: 着信通知" \
     -H "Priority: default" \
     -d "${MESSAGE}" \
     https://ntfy.warpflow.net/xw53brZ6HsWlyP6A
