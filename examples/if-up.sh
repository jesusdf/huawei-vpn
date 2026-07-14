#!/bin/sh
#
# Example "if-up" hook: runs once the VPN tunnel is up.
#
#   Arguments:    $1 = VPN interface name   $2 = tunnel-local IP
#   Environment:  TUN_DEVICE  VPN_IP  VPN_GATEWAY  VPN_PORT
#
# Mount it into the container at /etc/vpn/if-up.sh (see README). This example
# publishes a service that lives behind the VPN on a local port, so a container
# sharing this network stack can reach it at <this-container>:LOCAL_PORT.
#
set -e

TUN="${TUN_DEVICE:-$1}"

# <this container>:8080  ->  192.168.5.10:80  (a host reachable through the VPN)
LOCAL_PORT=8080
REMOTE=192.168.5.10:80

# Traffic arriving from other containers / the network.
iptables -t nat -A PREROUTING -p tcp --dport "$LOCAL_PORT" -j DNAT --to-destination "$REMOTE"
# Traffic generated locally in this network namespace.
iptables -t nat -A OUTPUT     -p tcp --dport "$LOCAL_PORT" -j DNAT --to-destination "$REMOTE"
# Give the redirected packets the tunnel's source address on the way out.
iptables -t nat -A POSTROUTING -o "$TUN" -j MASQUERADE

# Tip: to redirect traffic aimed at 127.0.0.1, also run:
#   echo 1 > /proc/sys/net/ipv4/conf/all/route_localnet
