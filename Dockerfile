FROM andrius/asterisk:latest

USER root

# libvorbis と curl をインストール
RUN apt-get update && apt-get install -y libvorbisenc2 curl && rm -rf /var/lib/apt/lists/*

# CDRディレクトリの作成、権限設定、不要なusers.confの削除
RUN mkdir -p /var/log/asterisk/cdr-csv && \
    chown -R asterisk:asterisk /var/log/asterisk && \
    chmod -R 755 /var/log/asterisk && \
    rm -f /etc/asterisk/users.conf

# ===== スクリプトのコピーと権限設定 =====
COPY ./script /var/lib/asterisk/scripts
RUN chown -R asterisk:asterisk /var/lib/asterisk/scripts && \
    chmod -R 755 /var/lib/asterisk/scripts

# ===== 設定ファイルのコピーと権限設定 =====
COPY ./config/pjsip.conf /etc/asterisk/pjsip.conf
COPY ./config/extensions.conf /etc/asterisk/extensions.conf
COPY ./config/modules.conf /etc/asterisk/modules.conf
COPY ./config/rtp.conf /etc/asterisk/rtp.conf

RUN chown asterisk:asterisk /etc/asterisk/pjsip.conf \
                            /etc/asterisk/extensions.conf \
                            /etc/asterisk/modules.conf \
                            /etc/asterisk/rtp.conf && \
    chmod 644 /etc/asterisk/pjsip.conf \
              /etc/asterisk/extensions.conf \
              /etc/asterisk/modules.conf \
              /etc/asterisk/rtp.conf

USER asterisk