FROM ubuntu:22.04

ENV LANG C.UTF-8
ENV DISPLAY :1

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_DATE 
ARG COMMIT_SHA

# https://github.com/opencontainers/image-spec/blob/master/spec.md
LABEL org.opencontainers.image.title='huawei-vpn' \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.description='Huawei SSL VPN official client' \
      org.opencontainers.image.documentation='https://github.com/jesusdf/huawei-vpn/blob/master/README.md' \
      org.opencontainers.image.version='1.0' \
      org.opencontainers.image.source='https://github.com/jesusdf/huawei-vpn' \
      org.opencontainers.image.revision="${COMMIT_SHA}"

# http://www.leagsoft.com/doc/article/103107.html
# https://download.leagsoft.com/download/UniVPN/linux/univpn-linux-64-10781.13.0.0522.zip
COPY bin/univpn*/*.run /tmp/univpn.run

RUN /usr/bin/apt-get update && \
    /usr/bin/apt-get dist-upgrade -y && \
    /usr/bin/apt-get install -y libqt5gui5 qt5dxcb-plugin xcb xcb-proto && \
    /usr/bin/apt-get install -y xserver-xorg-video-dummy x11-apps && \
    rm -rf /var/lib/apt/lists/* && \
    /usr/bin/apt-get clean

RUN set -x && \
    mkdir -p /usr/share/fonts/ && \
    chmod +x /tmp/univpn.run && \
    /tmp/univpn.run && \
    rm -f /usr/local/UniVPN/*.run && \
    rm -rf /tmp && \
    mkdir /tmp && \
    chmod 777 /tmp

COPY xorg.conf /
COPY startup.sh /

CMD ["/startup.sh"]