#!/bin/bash

# 日時の取得 (JST)
DATETIME=$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')

# Asteriskから生の情報を取得
ENDPOINTS_RAW=$(asterisk -rx "pjsip show endpoints")
CONTACTS_RAW=$(asterisk -rx "pjsip show contacts")

# 通知メッセージのヘッダー
MESSAGE="取得日時: ${DATETIME}

[endpoint : status : contact(ip)]"

# "Endpoint:" で始まる行からエンドポイント名とステータスを抽出してループ
# sedで余計な空白を整理してから処理します
while read -r line; do
    # エンドポイント名の抽出 (Endpoint: の後の文字列を抽出)
    EP_NAME=$(echo "$line" | sed -r 's/^Endpoint:\s+([^/ ]+).*/\1/')
    # ステータスの抽出 (行の後半にある状態を抽出)
    STATUS=$(echo "$line" | grep -oE '(Not in use|Unavailable|In use|Ringing|Busy)')

    # Contact(IP)情報の取得
    # pjsip show contacts の中から該当するエンドポイントのIP(Contact)を探す
    IP_ADDR=$(echo "$CONTACTS_RAW" | grep -A 1 "Endpoint:  $EP_NAME" | grep "Contact:" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]+)?' | head -n 1)

    if [ -z "$IP_ADDR" ]; then IP_ADDR="-"; fi
    if [ -z "$STATUS" ]; then STATUS="Unknown"; fi

    MESSAGE="${MESSAGE}
${EP_NAME} : ${STATUS} : ${IP_ADDR}"

done < <(echo "$ENDPOINTS_RAW" | grep "^Endpoint: ")

# ntfy.sh へ通知を送信
curl -H "Title: PJSIP Status Detail" \
     -H "Priority: default" \
     -H "Tags: telephone_receiver,network" \
     -d "${MESSAGE}" \
     https://ntfy.sh/KxgaRAdAYycAOnTS