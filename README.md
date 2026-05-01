# Asterisk HomeLab on Docker

このリポジトリは、Docker 上で動作させることを前提とした、Asterisk PBX の実践的なホームラボ環境です。

Macvlan ネットワークを用いた物理LANへの直接接続（SIP/RTPの安定化）と、CUPSコンテナを用いたFAXの自動PDF化＆ネットワークプリント、さらに Nextcloud (WebDAV) への自動バックアップ機能を備えています。

## 🌟 主な機能

* **完全コンテナ化された Asterisk PBX**: カスタムビルドされた軽量イメージ上で動作します。
* **Macvlan ネットワーク対応**: NATを回避し、指定した固定IP（`192.168.1.200`）で物理LANに直接接続します。
* **FAXの自動受信とPDF変換**: TIFF形式で受信したFAXを、DPI情報を維持したまま自動で正しい向きのA4 PDFに変換します。
* **CUPS 連携プリント**: 受信したFAXデータを、同一ネットワーク上のプリンター（Canon G3060: `192.168.1.221`）へ自動印刷します。
* **WebDAV 自動アップロード**: 変換されたPDFを、NextcloudのWebDAV API経由で指定フォルダへ自動的に保存します。
* **ntfy.sh プッシュ通知**: 着信時やFAX受信・印刷・保存の成功/失敗時に、スマホへリアルタイム通知を送ります。

## 🏗️ アーキテクチャ

本スタックは以下のネットワーク構成を前提としています。

1. **`macvlan-net`**: Asteriskコンテナが物理LANと同じIP帯（192.168.1.x）を取得し、SIP/RTP通信を行うためのネットワーク。
2. **`bridge-net`**: AsteriskとCUPSコンテナが内部通信を行うための通常のブリッジネットワーク。

| 変数名 | 説明 | 設定例 |
|--------|------|--------|
| NTFY_URL | ntfy.sh の通知先トピックURL | https://ntfy.example.com/mytopic |
| NC_URL | NextcloudのベースURL | https://nextcloud.example.com |
| NC_USER | Nextcloudのログインユーザー名 | my_user または user@example.com |
| NC_APP_PASSWORD | Nextcloudで発行したアプリパスワード | abcde-12345-fghij-67890 |

```text
[物理LAN: 192.168.1.0/24]
       │
       ├─ (Macvlan) ──▶ [ Asterisk Container ] (IP: 192.168.1.200)
       │                        │
       │                  (Bridge Net)
       │                        ▼
       ├─ (Port 631) ──▶ [ CUPS Container ] (Port: 631) ──▶ [ 物理プリンター: 192.168.1.221 ]
       │
       └─ (External) ─▶ [ Nextcloud (WebDAV) / ntfy.sh ]
```

## 🚀 クイックスタート

### 前提条件

- Docker & Docker Compose がインストール済み
- 物理ネットワーク: `192.168.1.0/24`
- ホストのネットワークインターフェース: `enp1s0`（compose.ymlに記載）
- Asteriskコンテナに割り当てるIP: `192.168.1.200`
- CUPS対応プリンター: `192.168.1.221`
- Nextcloud インスタンス（オプション）
- ntfy.sh トピック（オプション）

### セットアップ手順

1. **環境設定ファイルの作成**

   ```bash
   cp .env.example asterisk.env
   # 以下のファイルを編集して、自環境に合わせてください
   vi asterisk.env
   ```

   各変数の説明:
   - `NTFY_URL`: ntfy.sh プッシュ通知の送信先URL（オプション）
   - `NC_URL`: Nextcloud インスタンスのベースURL
   - `NC_USER`: Nextcloud ユーザー名またはメールアドレス
   - `NC_APP_PASSWORD`: Nextcloud 設定から生成したアプリパスワード
   - `TS_AUTHKEY`: Tailscale 認証キー（[ここから取得](https://login.tailscale.com/admin/authkeys)）

2. **データディレクトリの作成**

   Tailscale のステート情報を永続化するために、ホスト側にディレクトリを作成します。

   ```bash
   mkdir -p ./data/tailscale
   ```

3. **Docker Compose で起動**

   ```bash
   docker compose up -d
   ```

   ログを確認:
   ```bash
   docker compose logs -f asterisk
   docker compose logs -f cups
   ```

4. **動作確認**

   Asterisk CLI にアクセス:
   ```bash
   docker exec -it asterisk asterisk -r
   ```

   PJSIP エンドポイント確認:
   ```bash
   docker exec -it asterisk asterisk -rx "pjsip show endpoints"
   ```

### ネットワーク設定の変更

`compose.yml` 内の以下の箇所をカスタマイズできます:

- **Macvlan の親インターフェース**: `networks.macvlan-net.driver_opts.parent`
  - デフォルト: `enp1s0`
  - 環境に合わせて変更してください
  
- **サブネット**: `networks.macvlan-net.ipam.config.subnet`
  - デフォルト: `192.168.1.0/24`
  
- **Asterisk 固定IP**: `services.asterisk.networks.macvlan-net.ipv4_address`
  - デフォルト: `192.168.1.200`

## 📝 設定・スクリプト

### Asterisk 設定ファイル

- `config/pjsip.conf`: PJSIPエンドポイント設定（内線電話、外線ゲートウェイ）
- `config/extensions.conf`: ダイヤルプラン設定
- `config/modules.conf`: Asterisk モジュール読み込み設定
- `config/rtp.conf`: RTP/SRTP設定
- `config/musiconhold.conf`: 保留音設定
- `config/asterisk.conf`: Asterisk 基本設定

### スクリプト

- `script/entrypoint.sh`: コンテナ起動時の初期化スクリプト（Tailscale接続）
- `script/printfax.sh`: FAX受信時の自動処理（PDF変換→Nextcloud保存→プリント→通知）
- `script/printfax-dummy.sh`: FAX印刷のテストスクリプト
- `script/on_call.sh`: 着信時の通知スクリプト
- `script/show_endpoints.sh`: PJSIP エンドポイント情報を取得・通知

## 🔧 トラブルシューティング

### Asterisk コンテナが起動しない

```bash
docker compose logs asterisk
```

でエラーログを確認してください。

### FAX機能が動かない

1. FAX 受信デモテスト:
   ```bash
   # 内線 6000 にダイヤルする、またはシェルから:
   docker exec -it asterisk asterisk -rx "extension exten => 6000"
   ```

2. CUPS との通信確認:
   ```bash
   docker exec -it asterisk lpadmin -p Canon_G3060 -l
   ```

### CUPS サーバーに接続できない

1. CUPS コンテナのステータス確認:
   ```bash
   docker compose logs cups
   ```

2. ネットワーク確認:
   ```bash
   docker exec -it asterisk ping -c 3 cups
   ```

## 📚 参考資料

- [Asterisk 公式ドキュメント](https://wiki.asterisk.org/)
- [Nextcloud WebDAV API](https://docs.nextcloud.com/server/latest/developer_manual/client_apis/WebDAV/basic.html)
- [ntfy.sh](https://ntfy.sh/)
- [Docker Macvlan ドライバー](https://docs.docker.com/network/macvlan/)