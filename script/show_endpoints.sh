#!/bin/bash

# 日時の取得
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskの情報を取得
RAW_DATA=$(/usr/sbin/asterisk -rx "pjsip show endpoints")

# awkで整形（より堅牢な書き方に変更）
FORMATTED_INFO=$(echo "$RAW_DATA" | awk '
BEGIN { FS=" "; ep_count=0 }

/^Endpoint:/ {
    ep_count++;
    ep_name[ep_count] = $2;
    sub(/^Endpoint: [^ ]+ /, "", $0);
    sub(/ 0 of inf.*/, "", $0);
    ep_stat[ep_count] = $0;
}

/^Contact:/ {
    # Contact の2番目に @ が含まれる場合はそこからIPを取る
    if ($2 ~ /@/) {
        match($2, /@[^:;]+/);
        ep_ip[ep_count] = substr($2, RSTART+1, RLENGTH-1);
    } else if ($2 ~ /^[0-9]+\./) {
        # 直接IPが来る場合
        ep_ip[ep_count] = $2;
    }
    # RTT 抽出 (Avail の直後の数値)
    if ($0 ~ /Avail/) {
        for(i=1; i<=NF; i++) if ($i ~ /^[0-9]+\.[0-9]+$/) ep_rtt[ep_count] = $i "ms";
    }
}

/^Match:/ {
    split($2, m, "/");
    ep_ip[ep_count] = m[1];
}

END {
    for (i=1; i<=ep_count; i++) {
        # 短い状態名に変換
        status = ""
        if (ep_stat[i] ~ /Unavailable/) status = "断線"
        else if (ep_stat[i] ~ /Not in use/) status = "待機"
        else status = "使用中"

        ip = (ep_ip[i] ? ep_ip[i] : "-")
        rtt = (ep_rtt[i] ? "(" ep_rtt[i] ")" : "")
        # シンプルな1行出力: 名前: 状態 — IP (RTT)
        printf "%s: %s — %s %s\n", ep_name[i], status, ip, rtt
    }
    # 合計行を出力
    printf "合計: %d\n", ep_count
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