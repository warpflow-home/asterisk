#!/bin/bash

# 日時の取得
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskの情報を取得
RAW_DATA=$(/usr/sbin/asterisk -rx "pjsip show endpoints")

# awkで簡潔に整形（エンドポイント、ステータス、IP のみ）
FORMATTED_INFO=$(echo "$RAW_DATA" | awk '
BEGIN { endpoint=""; status="" }

/^Endpoint:/ {
    if (endpoint!="") printf "%s (%s)\n", endpoint, status
    endpoint=$2
    status=""
    for (i=3; i<=NF; i++) {
        if ($i ~ /^(in use|Not in use|Unavailable)/) {
            status=$i; break
        }
    }
    next
}

/^Contact:/ {
    if ($2 ~ /@/) {
        match($2, /@[^:;]+/)
        ip=substr($2, RSTART+1, RLENGTH-1)
        printf "%s (%s) - IP: %s\n", endpoint, status, ip
        endpoint=""
    }
}

END {
    if (endpoint!="") printf "%s (%s)\n", endpoint, status
}')

CONTENT="${FORMATTED_INFO}"

# ntfy.sh へ通知
curl -H "Title: PJSIP 接続レポート" \
     -H "Priority: default" \
     -H "Tags: telephone_receiver,network" \
     -d "取得日時: ${DATETIME}

${CONTENT}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS