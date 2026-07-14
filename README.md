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
