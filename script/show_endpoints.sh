#!/bin/bash

# 日時の取得
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskの情報を取得
RAW_DATA=$(/usr/sbin/asterisk -rx "pjsip show endpoints")

# awkで整形（行頭のスペースを許容し、ヘッダーを無視するよう改良）
FORMATTED_INFO=$(echo "$RAW_DATA" | awk '
BEGIN { prev_name=""; prev_ip=""; found=0 }

# "Endpoint:" を含む行（行頭のスペースも許可）
/^[ \t]*Endpoint:/ {
    # "<Endpoint..." のようなヘッダー行はスキップ
    if ($2 ~ /^</) next;
    
    if (prev_name!="") {
        printf "%s: %s\n", prev_name, (prev_ip?prev_ip:"-")
        found=1
    }
    prev_name=$2; prev_ip=""; next
}

/^[ \t]*Contact:/ {
    if ($2 ~ /^</) next;
    if ($2 ~ /@/) { match($2, /@[^:;]+/); prev_ip=substr($2, RSTART+1, RLENGTH-1) }
    else if ($2 ~ /^[0-9]/) prev_ip=$2
    next
}

/^[ \t]*Match:/ {
    if ($2 ~ /^</) next;
    split($2,m,"/"); prev_ip=m[1]; next
}

END {
    if (prev_name!="") { printf "%s: %s\n", prev_name, (prev_ip?prev_ip:"-"); found=1 }
}')

# もし整形結果が空なら、元のデータをそのまま入れる
if [ -z "$FORMATTED_INFO" ]; then
    CONTENT="解析エラーまたはデータなし:\n${RAW_DATA}"
else
    CONTENT="${FORMATTED_INFO}"
fi

# ntfy.sh へ通知 (NTFY_URLが設定されている場合のみ)
if [ -n "$NTFY_URL" ]; then
    curl -s -H "Title: PJSIP 接続レポート" \
         -H "Priority: default" \
         -H "Tags: telephone_receiver,network" \
         -d "取得日時: ${DATETIME}

${CONTENT}" \
         "${NTFY_URL}" > /dev/null
fi