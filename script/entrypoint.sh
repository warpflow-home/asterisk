#!/bin/bash
set -e

# 1. Tailscaleに必要なTUNデバイスの作成
if [ ! -c /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# 2. Tailscale状態保存用ディレクトリの確認
mkdir -p /var/lib/tailscale

# 3. tailscaled をバックグラウンドで起動
echo "Starting tailscaled..."
tailscaled --state=/var/lib/tailscale/tailscaled.state &

sleep 3

# 4. Auth Keyが設定されていればTailscaleネットワークに参加
if [ -n "$TS_AUTHKEY" ]; then
    echo "Connecting to Tailscale..."
    tailscale up --authkey=${TS_AUTHKEY} --hostname=asterisk-pbx
else
    echo "Warning: TS_AUTHKEY is not set!"
fi

# 5. Asterisk をフォアグラウンドで起動（セキュリティのためasteriskユーザーに権限を落とす）
echo "Starting Asterisk..."
exec asterisk -f -U asterisk -G asterisk