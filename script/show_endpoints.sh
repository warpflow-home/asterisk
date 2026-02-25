#!/bin/bash

# 日時の取得 (JST)
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# 一時的な作業用ファイルの作成
TMP_FILE=$(mktemp)

# エンドポイントのリストを取得 (Endpoint名とStatusを抽出)
# awkを使用して必要な列(Endpoint, Status)を抜き出し、一時ファイルに保存
asterisk -rx "pjsip show endpoints" | grep "^Endpoint: " | grep -v "<Endpoint/" | awk -F '  +' '{
    split($2, ep, "/");
    print ep[1], $3
}' > "$TMP_FILE"

# Contact(IP)情報の取得
CONTACTS=$(asterisk -rx "pjsip show contacts")

# 通知用メッセージの組み立て
MESSAGE="取得日時: ${DATETIME}

[endpoint : status : contact(ip)]"

while read -r LINE; do
    EP_NAME=$(echo "$LINE" | cut -d' ' -f1)
    STATUS=$(echo "$LINE" | cut -d' ' -f2-)
    
    # contacts情報から、このEndpointに対応するIPアドレスを検索
    IP_ADDR=$(echo "$CONTACTS" | grep -w "$EP_NAME" | grep "Contact:" | awk -F '  +' '{print $3}' | cut -d'/' -f1 | head -n 1)
    
    # IPが見つからない（Unavailable等）場合は "-" を表示
    if [ -z "$IP_ADDR" ]; then
        IP_ADDR="-"
    fi
    
    MESSAGE="${MESSAGE}
${EP_NAME} : ${STATUS} : ${IP_ADDR}"
done < "$TMP_FILE"

# 一時ファイルの削除
rm -f "$TMP_FILE"

# ntfy.sh へ通知を送信
curl -H "Title: PJSIP Status Detail" \
     -H "Priority: default" \
     -H "Tags: telephone_receiver,network" \
     -d "${MESSAGE}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS