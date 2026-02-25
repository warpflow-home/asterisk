#!/bin/bash

# 日時の取得 (TZを指定して確実に日本時間にする)
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskから情報を取得し、必要な部分だけを抽出・整形する
# 1. grep "^Endpoint: " : "Endpoint: " で始まる行だけを取り出す
# 2. grep -v "<Endpoint/" : ヘッダー行を除外する
# 3. awk -F '  +' : 2つ以上の連続するスペースを区切り文字として列を分割する
# 4. split($2, ep, "/") : "6001/6001" のようになっている名前部分の "/" 以降を切り捨てる
ENDPOINTS_INFO=$(asterisk -rx "pjsip show endpoints" | grep "^Endpoint: " | grep -v "<Endpoint/" | awk -F '  +' '{
    split($2, ep, "/");
    print ep[1] ":" $3
}')

# 通知メッセージの組み立て
MESSAGE="取得日時: ${DATETIME}

endpoint:state
${ENDPOINTS_INFO}"

# ntfy.sh へ通知を送信
curl -H "Title: PJSIP Endpoints Status" \
     -H "Priority: default" \
     -H "Tags: telephone_receiver" \
     -d "${MESSAGE}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS