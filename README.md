# Asterisk HomeLab on Docker Swarm HA

このリポジトリは、Docker Swarm の高可用性（HA）クラスター環境上で動作させることを前提とした、Asterisk PBX の実践的なホームラボ環境です。

Macvlan ネットワークを用いた物理LANへの直接接続（SIP/RTPの安定化）と、CUPSコンテナを用いたFAXの自動PDF化＆ネットワークプリント、さらに Nextcloud (WebDAV) への自動バックアップ機能を備えています。

## 🌟 主な機能

* **完全コンテナ化された Asterisk PBX**: カスタムビルドされた軽量イメージ上で動作します。
* **Swarm Macvlan 対応**: NATを回避し、指定した固定IP（`192.168.1.200`）で物理LANに直接接続します。
* **FAXの自動受信とPDF変換**: TIFF形式で受信したFAXを、DPI情報を維持したまま自動で正しい向きのA4 PDFに変換します。
* **CUPS 連携プリント**: 受信したFAXデータを、同一ネットワーク上のプリンター（Canon G3060: `192.168.1.221`）へ自動印刷します。
* **WebDAV 自動アップロード**: 変換されたPDFを、NextcloudのWebDAV API経由で指定フォルダへ自動的に保存します。
* **ntfy.sh プッシュ通知**: 着信時やFAX受信・印刷・保存の成功/失敗時に、スマホへリアルタイム通知を送ります。

## 🏗️ アーキテクチャ

本スタックは以下のネットワーク構成を前提としています。

1. **`swarm-macvlan`**: Asteriskコンテナが物理LANと同じIP帯（192.168.1.x）を取得し、SIP/RTP通信を行うためのネットワーク。
2. **`swarm-overlay`**: AsteriskとCUPSコンテナが内部通信を行うためのSwarmオーバレイネットワーク。

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
       │                  (Overlay Net)
       │                        ▼
       ├─ (Ingress) ──▶ [ CUPS Container ] (Port: 631) ──▶ [ 物理プリンター: 192.168.1.221 ]
       │
       └─ (External) ─▶ [ Nextcloud (WebDAV) / ntfy.sh ]
```