FROM andrius/asterisk:latest

USER root

# Install libvorbis for format_ogg_vorbis.so
RUN apt-get update && apt-get install -y libvorbisenc2 && rm -rf /var/lib/apt/lists/*

# Create CDR directory and set permissions
RUN mkdir -p /var/log/asterisk/cdr-csv && \
    chown -R asterisk:asterisk /var/log/asterisk && \
    chmod -R 755 /var/log/asterisk

USER asterisk
