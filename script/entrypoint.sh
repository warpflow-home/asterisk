#!/bin/bash
set -e

# 1. Tailscaleに必要なTUNデバイスの作成
if [ ! -c /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# 2. tmpfs ディレクトリの初期化（起動時に毎回作成・権限設定）
echo "Initializing tmpfs directories..."
mkdir -p /var/log/asterisk/cdr-csv
mkdir -p /var/spool/asterisk/outgoing
mkdir -p /var/spool/asterisk/tmp
chown -R asterisk:asterisk /var/log/asterisk
chown -R asterisk:asterisk /var/spool/asterisk
chmod -R 755 /var/log/asterisk
chmod -R 755 /var/spool/asterisk

# 3. Tailscale状態保存用ディレクトリの確認
mkdir -p /var/lib/tailscale

# 4. tailscaled をバックグラウンドで起動
echo "Starting tailscaled..."
tailscaled --state=/var/lib/tailscale/tailscaled.state &

sleep 3

# 5. Auth Keyが設定されていればTailscaleネットワークに参加
if [ -n "$TS_AUTHKEY" ]; then
    echo "Connecting to Tailscale..."
    tailscale up --authkey=${TS_AUTHKEY} --hostname=asterisk-pbx
else
    echo "Warning: TS_AUTHKEY is not set!"
fi

# 6. Asterisk をフォアグラウンドで起動（セキュリティのためasteriskユーザーに権限を落とす）
echo "Starting Asterisk..."
exec asterisk -f -U asterisk -G asterisk