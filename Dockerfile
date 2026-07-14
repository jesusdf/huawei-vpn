# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Stage 1 — builder: run the official UniVPN installer and strip the GUI.
#
# The installer is a proprietary shell + tarball blob; we run it on the same
# base it has always been validated against (ubuntu:22.04) so its behaviour
# does not change, then throw the whole stage away — only ~9 MB of headless
# binaries are copied into the runtime image below.
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

# http://www.leagsoft.com/doc/article/103107.html
# https://github.com/zx900930/docker-univpn/raw/main/bin/univpn-linux-64-10781.19.0.1214.zip
COPY bin/univpn*/*.run /tmp/univpn.run

# Install the client (installs to /usr/local/UniVPN and moves libgmcrypto.so to
# /lib), keep a pristine UniVPNCS so the entrypoint can re-patch the interface
# name on every start, then delete everything GUI-only. The UniVPNCS CLI and its
# promote daemon are plain glibc console binaries — no Qt/X11 — so libQt5*, the
# GUI binary, bundled fonts, PDFs and plugins (~45 MB) are all dead weight.
WORKDIR /build
RUN set -x && \
    chmod +x /tmp/univpn.run && \
    /tmp/univpn.run && \
    cp -a /usr/local/UniVPN/serviceclient/UniVPNCS \
          /usr/local/UniVPN/serviceclient/UniVPNCS.orig && \
    rm -rf /usr/local/UniVPN/lib \
           /usr/local/UniVPN/plugins \
           /usr/local/UniVPN/fonts \
           /usr/local/UniVPN/help \
           /usr/local/UniVPN/image \
           /usr/local/UniVPN/language \
           /usr/local/UniVPN/UniVPN \
           /usr/local/UniVPN/UniVPNUpdate \
           /usr/local/UniVPN/UniVPNA.sh \
           /usr/local/UniVPN/qt.conf \
           /usr/local/UniVPN/*.run

# ---------------------------------------------------------------------------
# Stage 2 — runtime: minimal Debian slim with just the headless client.
# ---------------------------------------------------------------------------
FROM debian:12-slim

ENV LANG=C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_DATE
ARG COMMIT_SHA

# https://github.com/opencontainers/image-spec/blob/master/spec.md
LABEL org.opencontainers.image.title='huawei-vpn' \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.description='Headless Huawei SSL VPN (UniVPN) client' \
      org.opencontainers.image.documentation='https://github.com/jesusdf/huawei-vpn/blob/master/README.md' \
      org.opencontainers.image.version='2.3' \
      org.opencontainers.image.source='https://github.com/jesusdf/huawei-vpn' \
      org.opencontainers.image.revision="${COMMIT_SHA}"

# Runtime dependencies only: expect (drives the CLI), iproute2 (routing /
# healthcheck), iptables (firewall hooks), procps (process supervision),
# ca-certificates (TLS). perl (for the interface-name patch) and awk are part
# of the Debian base. No Qt/X11.
RUN /usr/bin/apt-get update && \
    /usr/bin/apt-get dist-upgrade -y && \
    /usr/bin/apt-get install -y --no-install-recommends \
        expect iproute2 iptables procps ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    /usr/bin/apt-get clean

# The headless client: binaries + private libs, plus libgmcrypto.so which the
# installer relocates to /lib (there is no RPATH, so this path matters).
COPY --from=builder /usr/local/UniVPN /usr/local/UniVPN
COPY --from=builder /lib/libgmcrypto.so /lib/libgmcrypto.so

COPY univpn/ /opt/univpn/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /opt/univpn/connect.exp

# Healthy only while the VPN interface exists and carries a gateway-pushed route.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD ip route show dev "${TUN_DEVICE:-cnem_vnic}" | grep -q .

CMD ["/entrypoint.sh"]
