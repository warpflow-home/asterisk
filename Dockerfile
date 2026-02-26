FROM andrius/asterisk:latest
USER root

# 必要なパッケージのインストール
# asterisk-core-sounds-en-ulaw などを追加
RUN apt-get update && apt-get install -y \
    libvorbisenc2 \
    curl \
    ca-certificates \
    libtiff-tools \
    cups-client \
    asterisk-core-sounds-en-ulaw \
    asterisk-moh-opsound-wav \
    && rm -rf /var/lib/apt/lists/*

# ディレクトリの作成
RUN mkdir -p /var/log/asterisk/cdr-csv && \
    mkdir -p /var/lib/asterisk/moh && \
    mkdir -p /var/lib/asterisk/sounds/ja && \
    chown -R asterisk:asterisk /var/log/asterisk && \
    chmod -R 755 /var/log/asterisk && \
    rm -f /etc/asterisk/users.conf

# ===== スクリプトのコピー =====
COPY ./script /var/lib/asterisk/scripts
RUN chown -R asterisk:asterisk /var/lib/asterisk/scripts && \
    chmod -R 755 /var/lib/asterisk/scripts

# ===== 保留音ファイルのコピー =====
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

RUN chown asterisk:asterisk /etc/asterisk/pjsip.conf \
                            /etc/asterisk/extensions.conf \
                            /etc/asterisk/modules.conf \
                            /etc/asterisk/rtp.conf \
                            /etc/asterisk/features.conf \
                            /etc/asterisk/musiconhold.conf && \
    chmod 644 /etc/asterisk/pjsip.conf \
              /etc/asterisk/extensions.conf \
              /etc/asterisk/modules.conf \
              /etc/asterisk/rtp.conf \
              /etc/asterisk/features.conf \
              /etc/asterisk/musiconhold.conf

USER asterisk