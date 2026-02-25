#!/bin/bash

# 日時の取得
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskの情報を取得
RAW_DATA=$(asterisk -rx "pjsip show endpoints")

# awkで整形
FORMATTED_INFO=$(echo "$RAW_DATA" | awk '
# 1レコード出力する関数
function print_record() {
    if (ep_name == "" || ep_name ~ /^</) return;
    
    # アイコンとステータス
    icon = (ep_stat ~ /Unavailable/) ? "❌" : "✅";
    gsub(/Not in use/, "待機", ep_stat);
    gsub(/Unavailable/, "断線", ep_stat);
    
    # 表示
    printf "・%s %-6s: %s [%s] %s\n", icon, ep_name, ep_stat, (ep_ip=="" ? "-" : ep_ip), (ep_rtt=="" ? "" : "("ep_rtt")");
}

# Endpoint行 (ヘッダー "<" で始まるものは除外)
/^Endpoint: [^<]/ {
    print_record(); # 前の行があれば出力
    
    ep_name = $2;
    # ステータス抽出 (Endpoint名以降、"0 of inf"の前まで)
    stat_part = $0;
    sub(/^Endpoint: [^ ]+ /, "", stat_part);
    sub(/ 0 of inf.*/, "", stat_part);
    ep_stat = stat_part;
    
    # 初期化
    ep_ip = ""; ep_rtt = "";
}

# Contact行からIPとRTTを抽出
/^Contact: [^<]/ {
    # IP抽出: @の後ろ、[:;]の前
    if ($2 ~ /@/) {
        split($2, a, "@");
        split(a[2], b, /[:;]/);
        ep_ip = b[1];
    }
    # RTT抽出: Availのあとの数値
    if ($0 ~ /Avail/) {
        ep_rtt = $NF "ms";
    }
}

# Match行からIPを抽出
/^Match: [^<]/ {
    split($2, m, "/");
    ep_ip = m[1];
}

# 最後に残ったレコードを出力
END { print_record(); }
')

# 通知内容の構築
if [ -z "$FORMATTED_INFO" ]; then
    CONTENT="有効なエンドポイントデータが見つかりませんでした。"
else
    CONTENT="$FORMATTED_INFO"
fi

# ntfy.sh へ通知
curl -H "Title: PJSIP 接続レポート" \
     -H "Priority: default" \
     -H "Tags: telephone_receiver,network" \
     -d "取得日時: ${DATETIME}

${CONTENT}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS