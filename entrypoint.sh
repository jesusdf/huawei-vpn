#!/bin/sh
#
# Headless entrypoint for the Huawei UniVPN SSL VPN client.
#
# Runs the official client fully headless (no X11/VNC): it renders a connection
# profile from templates using the VPN_* environment variables, starts the
# privileged helper daemon and drives the CLI client (UniVPNCS) with expect,
# feeding the credentials at runtime so they never touch disk.
#
set -u

UNIVPN_DIR=/usr/local/UniVPN
CLIENT="$UNIVPN_DIR/serviceclient/UniVPNCS"

log() { echo "[entrypoint] $*"; }

# --- Required / optional configuration ---------------------------------------
: "${VPN_GATEWAY:?VPN_GATEWAY is required (gateway IP or hostname)}"
: "${VPN_USERNAME:?VPN_USERNAME is required}"
: "${VPN_PASSWORD:?VPN_PASSWORD is required}"

VPN_PORT="${VPN_PORT:-443}"                       # SSL VPN default is HTTPS/443
TUN_DEVICE="${TUN_DEVICE:-cnem_vnic}"             # built-in interface name

# Only ever one connection, so its name is a fixed constant.
CONNECTION_NAME=HUAWEIVPN

# UniVPNCS segfaults if USER is unset, and it derives the profile directory
# from HOME ($HOME/UniVPN).
export USER="${USER:-root}"
export HOME="${HOME:-/root}"

# --- /dev/net/tun sanity -----------------------------------------------------
if [ ! -c /dev/net/tun ]; then
    log "ERROR: /dev/net/tun is missing. Run with: --cap-add NET_ADMIN --device /dev/net/tun"
    exit 1
fi

# --- Custom tun interface name ----------------------------------------------
# The client hard-codes "cnem_vnic" and also *monitors* the interface by that
# name (renaming it at runtime makes the client tear the tunnel down). The only
# reliable way to change it is to patch the literal in a private copy of the
# binary before launch. The replacement must fit in the original 9 bytes.
if [ "$TUN_DEVICE" = "cnem_vnic" ]; then
    cp -a "$CLIENT.orig" "$CLIENT"
elif [ "${#TUN_DEVICE}" -gt 9 ]; then
    log "ERROR: TUN_DEVICE '$TUN_DEVICE' is too long (max 9 characters)."
    exit 1
else
    log "Renaming VPN interface to '$TUN_DEVICE'"
    TUN_DEVICE="$TUN_DEVICE" perl -0777 -pe '
        BEGIN { $d = $ENV{TUN_DEVICE}; $r = $d . ("\0" x (9 - length $d)); }
        s/cnem_vnic/$r/g
    ' "$CLIENT.orig" > "$CLIENT"
    chmod 0755 "$CLIENT"
fi

# --- Render the connection profile from templates ----------------------------
mkdir -p "$HOME/UniVPN/config"
sed -e "s|@@GATEWAY@@|$VPN_GATEWAY|g" -e "s|@@PORT@@|$VPN_PORT|g" \
    /opt/univpn/profile.ini.tmpl > "$HOME/UniVPN/config/${CONNECTION_NAME}.ini"
sed -e "s|@@PROFILE@@|${CONNECTION_NAME}.ini|g" \
    /opt/univpn/sysconfig.ini.tmpl > "$HOME/UniVPN/sysconfig.ini"

log "Profile '${CONNECTION_NAME}' -> ${VPN_GATEWAY}:${VPN_PORT} (interface '${TUN_DEVICE}')"

export CONNECTION_NAME VPN_USERNAME VPN_PASSWORD
cd "$UNIVPN_DIR/serviceclient"

start_daemon() {
    if ! pgrep -f UniVPNPromoteService >/dev/null 2>&1; then
        log "Starting UniVPNPromoteService"
        "$UNIVPN_DIR/promote/UniVPNPromoteService" >/tmp/promote.log 2>&1 &
        sleep 2
    fi
}

shutdown() {
    log "Shutting down"
    pkill -f UniVPNCS 2>/dev/null || true
    pkill -f UniVPNPromoteService 2>/dev/null || true
    exit 0
}
trap shutdown TERM INT

# --- Supervisor loop: keep the tunnel up, reconnect on drop ------------------
while true; do
    start_daemon
    log "Connecting..."
    expect -f /opt/univpn/connect.exp
    log "Tunnel session ended (rc=$?); reconnecting in 10s"
    pkill -9 -f UniVPNCS 2>/dev/null || true
    sleep 10
done
