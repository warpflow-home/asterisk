#!/bin/bash

# 日時の取得
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskの情報を取得
RAW_DATA=$(/usr/sbin/asterisk -rx "pjsip show endpoints")

# awkで整形（より堅牢な書き方に変更）
FORMATTED_INFO=$(echo "$RAW_DATA" | awk '
BEGIN { FS=" "; ep_count=0 }

# "Endpoint:" で始まる行
/^Endpoint:/ {
    ep_count++;
    ep_name[ep_count] = $2;
    # ステータスを結合 (Not in use 対応)
    sub(/^Endpoint: [^ ]+ /, "", $0);
    sub(/ 0 of inf.*/, "", $0);
    ep_stat[ep_count] = $0;
}

# "Contact:" で始まる行（IPとRTTを抽出）
/^Contact:/ {
    # IP抽出: @ の後ろから : か ; まで
    match($2, /@[^:;]+/);
    ep_ip[ep_count] = substr($2, RSTART+1, RLENGTH-1);
    
    # RTT抽出: Avail の後ろの数字
    if ($0 ~ /Avail/) {
        for(i=1; i<=NF; i++) {
            if ($i ~ /^[0-9]+\.[0-9]+$/) ep_rtt[ep_count] = $i "ms";
        }
    }
}

# "Match:" で始まる行（固定IP用）
/^Match:/ {
    split($2, m, "/");
    ep_ip[ep_count] = m[1];
}

END {
    for (i=1; i<=ep_count; i++) {
        # アイコン判定
        icon = (ep_stat[i] ~ /Unavailable/) ? "❌" : "✅";
        # 表示名整形
        stat_name = ep_stat[i];
        gsub(/Not in use/, "待機", stat_name);
        gsub(/Unavailable/, "断線", stat_name);
        
        printf "・%s %-6s: %s [%s] %s\n", 
               icon, ep_name[i], stat_name, 
               (ep_ip[i] ? ep_ip[i] : "-"), 
               (ep_rtt[i] ? "(" ep_rtt[i] ")" : "");
    }
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
     https://ntfy.sh/KxgaRAdAYycAOnTS