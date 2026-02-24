FROM andrius/asterisk:latest

USER root

# Install libvorbis for format_ogg_vorbis.so
RUN apt-get update && apt-get install -y libvorbisenc2 && rm -rf /var/lib/apt/lists/*

USER asterisk
