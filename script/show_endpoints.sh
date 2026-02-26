#!/bin/bash

# 日時の取得
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskの情報を取得
RAW_DATA=$(/usr/sbin/asterisk -rx "pjsip show endpoints")

# awkで整形（より堅牢な書き方に変更）
FORMATTED_INFO=$(echo "$RAW_DATA" | awk '
BEGIN { FS=" "; prev_name=""; prev_ip=""; found=0 }

/^Endpoint:/ {
    if (prev_name!="") {
        printf "%s: %s\n", prev_name, (prev_ip?prev_ip:"-")
        found=1
    }
    prev_name=$2; prev_ip=""; next
}

/^Contact:/ {
    if ($2 ~ /@/) { match($2, /@[^:;]+/); prev_ip=substr($2, RSTART+1, RLENGTH-1) }
    else if ($2 ~ /^[0-9]/) prev_ip=$2
    next
}

/^Match:/ { split($2,m,"/"); prev_ip=m[1]; next }

END {
    if (prev_name!="") { printf "%s: %s\n", prev_name, (prev_ip?prev_ip:"-"); found=1 }
    # found フラグは不要だが残す（出力は空でも可）
}')

# もし整形結果が空なら、元のデータをそのまま入れる
if [ -z "$FORMATTED_INFO" ]; then
    CONTENT="解析エラーまたはデータなし:\n${RAW_DATA}"
else
    CONTENT="${FORMATTED_INFO}"
fi

# ntfy.sh へ通知
curl -H "Title: PJSIP 接続レポート" \
     -H "Priority: default" \
     -H "Tags: telephone_receiver,network" \
     -d "取得日時: ${DATETIME}

${CONTENT}" \
     https://ntfy.warpflow.net/xw53brZ6HsWlyP6A