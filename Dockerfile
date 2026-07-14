FROM ubuntu:22.04

ENV LANG=C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_DATE
ARG COMMIT_SHA

# https://github.com/opencontainers/image-spec/blob/master/spec.md
LABEL org.opencontainers.image.title='huawei-vpn' \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.description='Headless Huawei SSL VPN (UniVPN) client' \
      org.opencontainers.image.documentation='https://github.com/jesusdf/huawei-vpn/blob/master/README.md' \
      org.opencontainers.image.version='2.0' \
      org.opencontainers.image.source='https://github.com/jesusdf/huawei-vpn' \
      org.opencontainers.image.revision="${COMMIT_SHA}"

# http://www.leagsoft.com/doc/article/103107.html
# https://download.leagsoft.com/download/UniVPN/linux/univpn-linux-64-10781.13.0.0522.zip
COPY bin/univpn*/*.run /tmp/univpn.run

# The UniVPN CLI (UniVPNCS) and its helper daemon are plain console binaries and
# need no X11/Qt. We only pull in expect (to drive the CLI), iproute2 (routing
# visibility / healthcheck) and procps (process supervision in the entrypoint).
RUN /usr/bin/apt-get update && \
    /usr/bin/apt-get dist-upgrade -y && \
    /usr/bin/apt-get install -y --no-install-recommends \
        expect iproute2 iptables procps ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    /usr/bin/apt-get clean

# Install the client and keep a pristine copy of UniVPNCS so the entrypoint can
# re-patch the interface name on every start.
RUN set -x && \
    mkdir -p /usr/share/fonts && \
    chmod +x /tmp/univpn.run && \
    /tmp/univpn.run && \
    cp -a /usr/local/UniVPN/serviceclient/UniVPNCS /usr/local/UniVPN/serviceclient/UniVPNCS.orig && \
    rm -f /usr/local/UniVPN/*.run && \
    rm -rf /tmp && mkdir /tmp && chmod 1777 /tmp

COPY univpn/ /opt/univpn/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /opt/univpn/connect.exp

CMD ["/entrypoint.sh"]
