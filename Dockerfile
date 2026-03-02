FROM andrius/asterisk:latest
USER root

# パッケージのインストール（aptからasterisk音声パッケージを削除し、tarを追加）
RUN apt-get update && apt-get install -y \
    libvorbisenc2 \
    curl \
    ca-certificates \
    libtiff-tools \
    cups-client \
    tar \
    && rm -rf /var/lib/apt/lists/*

# ディレクトリの作成
RUN mkdir -p /var/log/asterisk/cdr-csv && \
    mkdir -p /var/lib/asterisk/moh && \
    mkdir -p /var/lib/asterisk/sounds/en && \
    mkdir -p /var/lib/asterisk/sounds/ja && \
    chown -R asterisk:asterisk /var/log/asterisk && \
    chmod -R 755 /var/log/asterisk && \
    rm -f /etc/asterisk/users.conf

# ===== 公式からCore Sounds (英語ガイダンス) をダウンロードして展開 =====
RUN curl -L -o /tmp/asterisk-core-sounds-en-ulaw-current.tar.gz https://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-ulaw-current.tar.gz && \
    tar -xzf /tmp/asterisk-core-sounds-en-ulaw-current.tar.gz -C /var/lib/asterisk/sounds/en && \
    rm /tmp/asterisk-core-sounds-en-ulaw-current.tar.gz && \
    chown -R asterisk:asterisk /var/lib/asterisk/sounds && \
    chmod -R 755 /var/lib/asterisk/sounds

# ===== スクリプトのコピー =====
COPY ./script /var/lib/asterisk/scripts
RUN chown -R asterisk:asterisk /var/lib/asterisk/scripts && \
    chmod -R 755 /var/lib/asterisk/scripts

# ===== 保留音ファイルのコピー (ローカルの music フォルダ) =====
# ユーザーが用意した保留音を使うため、公式のデフォルトMOHはダウンロードしません
COPY ./music /var/lib/asterisk/moh
RUN chown -R asterisk:asterisk /var/lib/asterisk/moh && \
    chmod -R 755 /var/lib/asterisk/moh

# ===== 設定ファイルのコピー =====
COPY ./config/pjsip.conf /etc/asterisk/pjsip.conf
COPY ./config/extensions.conf /etc/asterisk/extensions.conf
COPY ./config/modules.conf /etc/asterisk/modules.conf
COPY ./config/rtp.conf /etc/asterisk/rtp.conf
COPY ./config/features.conf /etc/asterisk/features.conf
COPY ./config/musiconhold.conf /etc/asterisk/musiconhold.conf
COPY ./config/asterisk.conf /etc/asterisk/asterisk.conf

RUN chown asterisk:asterisk /etc/asterisk/pjsip.conf \
    /etc/asterisk/extensions.conf \
    /etc/asterisk/modules.conf \
    /etc/asterisk/rtp.conf \
    /etc/asterisk/features.conf \
    /etc/asterisk/musiconhold.conf \
    /etc/asterisk/asterisk.conf && \
    chmod 644 /etc/asterisk/pjsip.conf \
    /etc/asterisk/extensions.conf \
    /etc/asterisk/modules.conf \
    /etc/asterisk/rtp.conf \
    /etc/asterisk/features.conf \
    /etc/asterisk/musiconhold.conf \
    /etc/asterisk/asterisk.conf

# ===== CUPSクライアントのデフォルトサーバーを固定 =====
RUN mkdir -p /etc/cups && echo "ServerName 192.168.1.240" > /etc/cups/client.conf

USER asterisk