# huawei-vpn

Headless Docker image for the **Huawei SSL VPN** (official **UniVPN** client).
No X11/VNC — the client runs from the CLI, the profile is generated from
environment variables, and credentials are never written to the image.

Use it as a network stack for other containers (`network_mode: "service:huawei-vpn"`);
with split tunnelling only the routes the gateway pushes go through the VPN.

## docker run

```sh
docker run -d --name huawei-vpn \
  --cap-add NET_ADMIN --device /dev/net/tun \
  -e USER=root \
  -e TZ=Europe/Madrid \
  -e VPN_GATEWAY=vpn.example.com \
  -e VPN_USERNAME=my-user \
  -e VPN_PASSWORD=my-password \
  jesusdf/huawei-vpn
```

## docker compose

```yaml
services:
  huawei-vpn:
    image: jesusdf/huawei-vpn
    cap_add: [NET_ADMIN]
    devices: [/dev/net/tun]
    environment:
      - USER=root
      - TZ=Europe/Madrid
      - VPN_GATEWAY=vpn.example.com
      - VPN_USERNAME=my-user
      - VPN_PASSWORD=my-password
    restart: unless-stopped
```

## Environment variables

| Variable       | Required | Default     | Description                                        |
| -------------- | :------: | ----------- | -------------------------------------------------- |
| `VPN_GATEWAY`  |   yes    | —           | Gateway address (IP or hostname).                  |
| `VPN_USERNAME` |   yes    | —           | Login user name.                                   |
| `VPN_PASSWORD` |   yes    | —           | Login password.                                    |
| `USER`         |   yes    | `root`      | Must be set; the client segfaults without it.      |
| `VPN_PORT`     |    no    | `443`       | Gateway HTTPS port.                                |
| `TUN_DEVICE`   |    no    | `cnem_vnic` | VPN interface name (max 9 chars, e.g. `tun17`).    |
| `TZ`           |    no    | —           | Time zone, e.g. `Europe/Madrid`.                   |
| `IF_UP`        |    no    | `/etc/vpn/if-up.sh`   | Hook run when the tunnel comes up.        |
| `IF_DOWN`      |    no    | `/etc/vpn/if-down.sh` | Hook run when the tunnel goes down.       |

## Firewall hooks

Mount a script at `/etc/vpn/if-up.sh` (runs when the tunnel comes up) and/or
`/etc/vpn/if-down.sh` (runs when it drops or on shutdown) to install your own
`iptables` rules — typically port redirections. `iptables` is included in the image.

Each hook gets the interface name and tunnel IP as `$1`/`$2`, and via the
`TUN_DEVICE`, `VPN_IP`, `VPN_GATEWAY` and `VPN_PORT` environment variables. See
[`examples/`](examples/).

```sh
docker run -d --name huawei-vpn \
  --cap-add NET_ADMIN --device /dev/net/tun \
  -e USER=root -e VPN_GATEWAY=vpn.example.com \
  -e VPN_USERNAME=my-user -e VPN_PASSWORD=my-password \
  -v ./if-up.sh:/etc/vpn/if-up.sh:ro \
  -v ./if-down.sh:/etc/vpn/if-down.sh:ro \
  jesusdf/huawei-vpn
```

`/proc/sys` is read-only by default, so if a rule needs a sysctl (e.g.
`net.ipv4.conf.all.route_localnet=1` for `127.0.0.1` redirects) pass it with
`--sysctl` / compose `sysctls:`.
