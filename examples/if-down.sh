#!/bin/sh
#
# Example "if-down" hook: runs when the VPN tunnel goes away (and on shutdown).
# It should undo whatever if-up.sh added; ignore errors if the rules are gone.
#
#   Arguments:    $1 = VPN interface name   $2 = tunnel-local IP
#   Environment:  TUN_DEVICE  VPN_IP  VPN_GATEWAY  VPN_PORT
#
TUN="${TUN_DEVICE:-$1}"

LOCAL_PORT=8080
REMOTE=192.168.5.10:80

iptables -t nat -D PREROUTING -p tcp --dport "$LOCAL_PORT" -j DNAT --to-destination "$REMOTE" 2>/dev/null || true
iptables -t nat -D OUTPUT     -p tcp --dport "$LOCAL_PORT" -j DNAT --to-destination "$REMOTE" 2>/dev/null || true
iptables -t nat -D POSTROUTING -o "$TUN" -j MASQUERADE 2>/dev/null || true
