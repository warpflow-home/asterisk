#!/bin/bash

# 日時の取得
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskの情報を取得し、awkで詳細にパース
FORMATTED_INFO=$(asterisk -rx "pjsip show endpoints" | awk '
BEGIN {
    # 出力用変数の初期化
    ep=""; status=""; ip="-"; rtt="-";
}

# Endpoint行の処理
/^Endpoint:/ {
    # 前のエンドポイントの情報があれば出力
    if (ep != "") print_result();
    
    ep = $2;
    status = $3;
    if ($4 == "in") status = status " " $4 " " $5; # "Not in use" 対応
    # 初期化
    ip = "-"; rtt = "-";
}

# Contact行からIPとRTTを抽出
/^Contact:/ {
    # $2 は sip:201@10.0.0.2:51789;ob の形式
    split($2, a, "@");
    split(a[2], b, /[:;]/); # IP部分だけ取り出す
    ip = b[1];
    if ($5 == "Avail") rtt = $6 "ms";
}

# Identify/Match行からIPを抽出（固定IPデバイス用）
/^Match:/ {
    split($2, c, "/");
    ip = c[1];
}

# 最後に残ったデータを処理するためにEND節で関数を呼ぶ
END {
    if (ep != "") print_result();
}

# 1行にまとめて出力する関数
function print_result() {
    # アイコン判定
    icon = (status == "Unavailable") ? "❌" : "✅";
    
    # ステータスの日本語化
    disp_stat = status;
    if (status == "Unavailable") disp_stat = "断線";
    if (status == "Not in use") disp_stat = "待機";
    
    # フォーマット: ・[アイコン] 名前: ステータス [IPアドレス] (RTT)
    printf "・%s %-6s: %s [%s] %s\n", icon, ep, disp_stat, ip, (rtt == "-" ? "" : "("rtt")");
}
' | sed 's/ *$//') # 文末の余計な空白を削除

# ntfy.sh へ通知を送信
curl -H "Title: PJSIP 接続レポート" \
     -H "Priority: default" \
     -H "Tags: telephone_receiver,network" \
     -d "取得日時: ${DATETIME}

${FORMATTED_INFO}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS