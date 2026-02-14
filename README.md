# Minimal, automatic shell script for wg-quick
A minimal shell script to create a wg-quick config, generate clients (with optional qr-codes), from user input with minimal fuzz or extra files. It will simply create a new config at `/etc/wireguard/wg0.conf`, prompt you for some settings (subnet, listen port & dns server), then create the config. Client configs and qr-codes are stored in a per-config folder such as `/etc/wireguard/wg0_clients/` with the names `<name>.conf` and `<name>_qr.txt`. IPs are automatically incremented from `wg0.conf`, no extra files needed, and adaptive to if you want to modify `wg0.conf` yourself.

# Features
* Small single bash script
* Few dependencies (wg-quick/wireguard, curl, iptables, qrencode)
    * qrencode is optional, only required for generating the QR code files and printing the QR code to the terminal
* Generate a small wg-quick config to easily get started
* No extra files, only `wg0.conf` and client configs stored on disk
* Sane defaults with auto-fetch of network interface & public ip
* Auto increment clients from existing `wg0.conf`
* Add new clients by subsequent runs and auto-reload to apply changes
* Supports overriding listening ports
* Full IPv4 and IPv6 support

## Install dependencies
Debian/Ubuntu:
```bash
apt update
apt install -y wireguard-tools curl iproute2 iptables qrencode
```

Fedora:
```bash
dnf install -y wireguard-tools curl iproute iptables qrencode
```

Arch:
```bash
pacman -Sy --noconfirm wireguard-tools curl iproute2 iptables qrencode
```

Alpine:
```bash
apk add --no-cache wireguard-tools curl iproute2 iptables libqrencode-tools
```

Only `qrencode` is optional. Remove just `qrencode` from the install command if you do not need terminal QR output and `_qr.txt` files.

## Get started
```bash
cd /etc/wireguard
wget 'https://raw.githubusercontent.com/kristianvld/wg-quick-mini/main/wg.sh'
chmod +x wg.sh
./wg.sh
```

## Example:
Example first time execution:
```
root@amazing-dragonfly:/etc/wireguard# ./wg.sh
WireGuard server config not found. Creating...
Enter internal CIDR mask (default: 10.100.10.1/24, fd00:100::1/64):
Enter port to listen to  (default: 51820): 53
DNS server(s) for clients to use (default: 1.1.1.1, 2606:4700:4700::1111):
Main incoming network interface (default: ens2):
Allow internal traffic between clients (default: Yes) [Yes/no]:
Port 53 is already in use. We can however map incoming traffic using iptables rules.
Enter the real port to listen to (default: 51820):
Created WireGuard server config at /etc/wireguard/wg0.conf
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.100.10.1/24 dev wg0
[#] ip -6 address add fd00:100::1/64 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] iptables -A FORWARD -i wg0 -o ens2 -j ACCEPT
[#] ip6tables -A FORWARD -i wg0 -o ens2 -j ACCEPT
[#] iptables -t nat -I POSTROUTING -o ens2 -j MASQUERADE
[#] ip6tables -t nat -I POSTROUTING -o ens2 -j MASQUERADE
[#] sysctl -q -w net.ipv4.ip_forward=1
[#] sysctl -q -w net.ipv6.conf.all.forwarding=1
[#] iptables -t nat -A PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] ip6tables -t nat -A PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] iptables -t nat -A POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
[#] ip6tables -t nat -A POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
Allow this script to query icanhazip.com (Cloudflair owned) to determin the servers public ipv4 & ipv6 address? (default: yes):
The client can only recieve one endpoint. If you want to use both ipv4 and ipv6, you need to specify a domain name that resolves to both ipv4 and ipv6.
Enter your server public ip or domain (detected 13.37.13.37, 2001:1337:1337::1) (default: 13.37.13.37):
Enter a name for the new client: my laptop
Assigning new client ip(s): 10.100.10.2/32, fd00:100::2/128
Restarting wireguard server to add client...
[#] ip link delete dev wg0
[#] iptables -D FORWARD -i wg0 -o ens2 -j ACCEPT
[#] ip6tables -D FORWARD -i wg0 -o ens2 -j ACCEPT
[#] iptables -t nat -D POSTROUTING -o ens2 -j MASQUERADE
[#] ip6tables -t nat -D POSTROUTING -o ens2 -j MASQUERADE
[#] sysctl -q -w net.ipv4.ip_forward=0
[#] sysctl -q -w net.ipv6.conf.all.forwarding=0
[#] iptables -t nat -D PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] ip6tables -t nat -D PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] iptables -t nat -D POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
[#] ip6tables -t nat -D POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.100.10.1/24 dev wg0
[#] ip -6 address add fd00:100::1/64 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] iptables -A FORWARD -i wg0 -o ens2 -j ACCEPT
[#] ip6tables -A FORWARD -i wg0 -o ens2 -j ACCEPT
[#] iptables -t nat -I POSTROUTING -o ens2 -j MASQUERADE
[#] ip6tables -t nat -I POSTROUTING -o ens2 -j MASQUERADE
[#] sysctl -q -w net.ipv4.ip_forward=1
[#] sysctl -q -w net.ipv6.conf.all.forwarding=1
[#] iptables -t nat -A PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] ip6tables -t nat -A PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] iptables -t nat -A POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
[#] ip6tables -t nat -A POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
█████████████████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████████████████
████ ▄▄▄▄▄ █▄█▄ █ ▀ ▀ ██▄▀██▀▄▀ ▀▄▄█▄█▄▄▄█ ▄█ ███▄▀ ▄██▄█ █▄▀█ ▄▄▄▄▄ ████
████ █   █ █ ▄█ ▀▀██▀▄▀ ▀▀▄▀▄█▀▀▄▀▄█ ████ ▀ ▀ █▀█▄ ▄█ ▄  ▀ ▀▄█ █   █ ████
████ █▄▄▄█ █▄  ▄▀ ▄▄ ▀▀▄▄█  ▄█▀ ██ ▄▄▄ █▄  ▄▀▀█▀█▄▀█▄▀ █▄█▀█▄█ █▄▄▄█ ████
████▄▄▄▄▄▄▄█▄█▄▀ ▀ █ ▀▄█ █▄▀▄▀ █▄▀ █▄█ ▀▄█ █▄▀▄█ ▀ ▀ █ █▄▀ █ █▄▄▄▄▄▄▄████
████ ▄ ▄█▀▄█ ▄▀ ▀██▄▄██▄▄█ █  ▀█▄▄  ▄▄▄▄▀▄█▀ ▄  █▄█ ▀▄█  ▀█▀▀ ▀█ ▄▄▀ ████
████ ▄▄▀ ▄▄ ▀█▀▄▄   ▀   ▄█▄▀▀█▀ ▀ ▄▄▄█▀▀█ ▀█ █ █▄█ ▄▀ █▀▄▄▀▀█▄ █ ██ ▄████
████▀▄▄███▄ ███▄▄▀▄▄▀█ ▀█▀▀▄ ▀▀█ ▀ ▄█ █▄ █ ██ █ ██▄  ▄█▀█▄█ ▀▀█▀ ▄▄▄█████
████▄███ ▄▄ ▀  ▄▄█▄ ▄▀█  █ ██ ▄▄▄ █▄▀   ▀▄▄▄ █  ▀██  █    ▄▄ ▀█▀▄▀▄▄ ████
██████  ▀ ▄█ █▄▀██  ▄█▀▄ ▀▄ ▀ █▀ ▀██ ▀  ▄█ █ ▄▀▀█ ▀ ▄ ▄▄ █▀█ █▀▀█ ▀█ ████
████▀ ▀▄▄▄▄██ ▀███▀█▀ ▀█▄▄▄ ▄ ▀▄▄▄▄▀▄█ ▀▄▀▄ ▀ ███ ▀ ▄█▀▄█▀ █ ▄▄▀  ▀▀▀████
████ ▄█▀  ▄▀  ▄▀▀  █ ▄ ▄ ▀ █▀▀▄██▄ ▀▀▄ ▀▄▀█▀  ▀ ▀███▄▄█   ▀▀▄█▀▄█▄▄▀▀████
████▀▄▀█▄▀▄▄█ ▀█ █▄▀▄▄█▀▀▀▀█▀▄█▄   █▄▀▀▄█▄ ▀▄▄█▀▀ ▀▄█▄▀▀▄█ ▀▄█▀▀█▀▄ █████
████▀█ ▀  ▄▄▄ ▄▄█▀ ▄▄▀ ▄ ▄▀ ██▀▀█▀▀▀ ██▀▄  ▀▀ █ ▀ ▀▀▀▄ ███ █ ▄▄█▄▄▀▄█████
█████ ▀█▀ ▄  █▄▀▀▄█ ███  ▀▀█▀▄ ▄▄█▄ ▀ █▀▀▄█▄▀█▄ █ ▀█▄▄▄▀ █ ▄▄ ▄▀▀█ ▀▄████
████  ▄ ▄▀▄▄  ▄▀ █ ▄▀█▀ ▄▄  ▀▄▄██▄█▄ ▀▀█▀ █▀▀▀  ▄▄▄▀▀   █▄▄▀▄  ▀▀ █▀▀████
████▄ ▀▄ ▄▄▄ ▀▄█ ▀███▀ ▄▀ ▄▀▄▀████ ▄▄▄ ▀█▄▄█▄▀ █ ████ ▀▄▄▄▀  ▄▄▄ ▄▄██████
████▀  ▀ █▄█  █▄ █ ▄█▄▀█▀█▀▄▄▀▄█ █ █▄█  ▀ ▀ █▀██▄▄ ▀ █▀▀▄██▄ █▄█   ▄ ████
████▀     ▄▄ ▀█▄ ▀ ▄▄ █ ▄█ █▀██▄▀▀▄     ▄██ ▄▄█▀ ▀▀▀▄▄▀▀█ █▀▄▄▄▄ ██ █████
████ █▄ ▄▄▄▄▀▀▄▄█ ▀▀██▄▄█▄██▀▀ ██ ▄█ ▄▀▀▀▀▀ ▀▄█▀█▀▄ ▄▄▀▄▀██▄█▄▄█▄▄  █████
████▄  █ ▄▄█ ▀▀▄▀█   ▀▄█  ▀▄▀▄  ▀▀ █▄█ █████ ▄  ▀ ▄█ ▄ ▀▄▀ ▄ ▀▄ ▄█   ████
████ ▄▄█▄ ▄   ▀█▀▄█▄  ▄▀█▀█▄▄ ▄ ▀▄█▄▄  ▄█▀ █ █▀▀▄▀ ▄▀▀▀▄█ ▀█▄▀▀ ▄ ▀██████
████▄▀█▀▀█▄█▄▄▄▀██▄██▀ ▄▀▄▀ █▀▄▀▄█▀▄█▄ ▄ █▀▄█▀ ▀█▄▀▀▀████▀ ▄ ▄▄▀██ ▀▀████
████▀▄█▀▄█▄█▀▄█▄▀█ █ ▀▀ ▀█▀██▄▀█  █▀▀█ ▄▀▀▄ ▄▄▀ █▄██▀█▄▄▄  █▄▄▄█▀▄▄▄▄████
████▄▀▀ █▄▄█▄▄ ▄▀█▄▀▄ ▄█▀▀▄ █▀  ▀▀█▄ ██▄ ▀ ▀▄▄█▀▄▀█▀█ █ ▀▄▀▀ ▄ █▀ ▄▄▀████
████▀▀▀ ▀ ▄█ ██▀█▀ ▄▄ ▀▄▀█▄▄█ █▄▄█▀██▄▀▀▄██▄▄▀ █ ▄▀▄█▄██▄▄ ▀ ▀█▄█▀▀▄█████
█████▀ ▄▄█▄▀█▀▀▄▀ █▀█▄▄█▄ ▀█ ██ █▀██▀▄█▀██▄▀▄  ▀██▄▄▄█▄▀ ▄ ▄▄▄▄▄█ ██▀████
████ ▀ █▀▀▄█▀▀ ▄ ▄█▄ █▄██▄ ▄█▀██▄█ ▀ █▄ ▀▄▄▀▀ ▄█▀▀ ▀▄▀▄▀ ▀█▀ █▀  ▀██▀████
████▀█▄ █▄▄  ▀█  ▄ ▄▄▄▄█  █  ▄▀█▄▀██▄▀▀▀▀▀▀▄▄▀▄█ █▄██▄ ▄▀ ▀█▀ █  ▀▀▀▄████
█████▄▄█▄█▄█▀ ▀█  ▄▄██ █▄▀  ▀██▄▄▀ ▄▄▄   ███▄▄█▄█ ▄▄▀▄  ▀▀▄  ▄▄▄ ████████
████ ▄▄▄▄▄ ██▄▄▄▀ ███▄ █▀█▄  █▀ █  █▄█ ▀▀▀ ▀█▄█▀▄█ ▄█▀▀▄█▄ █ █▄█ ▄███████
████ █   █ █▀▀█▄▀█▄██▄█▄▀▄▀▄▀▄ █▀▀▄▄  ▄▄▄▄▄▄█▄  ▀█▄  █▄██▀█  ▄▄▄ █ ▄▄████
████ █▄▄▄█ █ ▀▄▄ ▀█ ▄█ █████▀▄▀▄▄▀▄▀▀▄ █  ▀▀██▄▀▀▀▄ █▄█▄▄▀▄ ▄▀▀ ▀▀▀▀▄████
████▄▄▄▄▄▄▄█▄█▄▄▄▄▄▄███▄██▄▄▄██▄▄██▄████▄█▄▄▄▄█▄███▄▄▄▄██▄██▄██████▄█████
█████████████████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████████████████
Client config saved to /etc/wireguard/clients/my laptop.conf
Enter a name for the new client: ^C
root@amazing-dragonfly:/etc/wireguard# cat ./clients/my\ laptop.conf
[Interface]
PrivateKey = 6D+ngNWVuA8SWQCvH8M4CmTQIxzWYE3/ISzUzOMWUUM=
DNS = 1.1.1.1, 2606:4700:4700::1111
Address = 10.100.10.2/32, fd00:100::2/128

[Peer]
PublicKey = 7OXWDMsT/fLCZG+8JlNwDm/kDX0PhaKnGiD4GIR63gQ=
PresharedKey = gF7DfiqfRpqNGO1nJIQund8Lc8zNTO69rw7y6b3ZVlI=
Endpoint = 13.37.13.37:53
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```
To add more clients, even after editing the `wg0.conf` file, simply run the script again:
```
root@amazing-dragonfly:/etc/wireguard# ./wg.sh
Allow this script to query icanhazip.com (Cloudflair owned) to determin the servers public ipv4 & ipv6 address? (default: yes):
The client can only recieve one endpoint. If you want to use both ipv4 and ipv6, you need to specify a domain name that resolves to both ipv4 and ipv6.
Enter your server public ip or domain (detected 13.37.13.37, 2001:1337:1337::1) (default: 13.37.13.37):
Enter a name for the new client: my phone
Assigning new client ip(s): 10.100.10.3/32, fd00:100::3/128
Restarting wireguard server to add client...
[#] ip link delete dev wg0
[#] iptables -D FORWARD -i wg0 -o ens2 -j ACCEPT
[#] ip6tables -D FORWARD -i wg0 -o ens2 -j ACCEPT
[#] iptables -t nat -D POSTROUTING -o ens2 -j MASQUERADE
[#] ip6tables -t nat -D POSTROUTING -o ens2 -j MASQUERADE
[#] sysctl -q -w net.ipv4.ip_forward=0
[#] sysctl -q -w net.ipv6.conf.all.forwarding=0
[#] iptables -t nat -D PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] ip6tables -t nat -D PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] iptables -t nat -D POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
[#] ip6tables -t nat -D POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.100.10.1/24 dev wg0
[#] ip -6 address add fd00:100::1/64 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] iptables -A FORWARD -i wg0 -o ens2 -j ACCEPT
[#] ip6tables -A FORWARD -i wg0 -o ens2 -j ACCEPT
[#] iptables -t nat -I POSTROUTING -o ens2 -j MASQUERADE
[#] ip6tables -t nat -I POSTROUTING -o ens2 -j MASQUERADE
[#] sysctl -q -w net.ipv4.ip_forward=1
[#] sysctl -q -w net.ipv6.conf.all.forwarding=1
[#] iptables -t nat -A PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] ip6tables -t nat -A PREROUTING -i ens2 -p udp --dport 53 -j REDIRECT --to-port 51820
[#] iptables -t nat -A POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
[#] ip6tables -t nat -A POSTROUTING -o ens2 -p udp --sport 51820 -j SNAT --to-source :53
█████████████████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████████████████
████ ▄▄▄▄▄ █▀ ▄█ ▄▀ ▀█ ▄▀█▄▀▀██▄▄▄ ▀▄▀▄  █▄ █▄▀█▀ ▀▄ █▀ █▄█▄▀█ ▄▄▄▄▄ ████
████ █   █ █▀▀ ▀ ▀▀▄ ▄ ▀  █▀█▄▀ █▀█▄ ██▄█▄█ ▄▀▄ █ █▄▄▀▄▀▀▀ ▀▄█ █   █ ████
████ █▄▄▄█ █▀▄ █▄ █▀▄ ▄ █ ▄▀▀█▄█▀▄ ▄▄▄ ▄▄ █▀ ▄▄█▄▀▀▄▀█▀  ▄▀█▄█ █▄▄▄█ ████
████▄▄▄▄▄▄▄█▄▀ █▄▀▄▀ █ █▄▀▄█ █▄▀▄█ █▄█ █ █▄▀▄█ █▄█ █▄█▄▀▄█▄█▄█▄▄▄▄▄▄▄████
████ ▄▄ ▄▀▄▄ ▀  ▄ ████▄█▄▄▀█▀▀▀▀▄▄  ▄▄▄▄ ██ ▀▄▀▀██▄  ██▀▀▀▄ ▀ ▀▄▀▄█ ▀████
████▄▄█  █▄ ▄ █▀▄▄▀▀▄▀█▄█   ▄▀ ▀█▄▄ █▀█ ▄▄▄ ▄▄█▀█ ▄▀▄▄▄▄ █▄█▄▀▄▄█▀▄█ ████
████▀█ ▀█ ▄▀▄▀█▄▀▀ ▀█▀▄▀▀█▀ ▄▀█▀ █▄▀▄▄█▀ ▄ ██▄▀▄█▀▄▄▄▄▀██ ▀ ████▄▄  █████
████  █▄▄ ▄▄█▄▄ ▀██▀▄▀█▀ ▄▀█▄█ ██ ▄█ ▀█  ▄██▀█▀ ▀▄▄ ▀▄ ▀▀ ██  ▄▀█ ▄█▀████
█████▄▄██▀▄▄█ ███▀▀▄█▄ █▀▄ ▄█▀▀▀ ▄▄▀▀▀ ▀▀▀▀ ▄█▄█▄██▀▀▄█▀▄▄▄▀▀ █  ▄  ▄████
█████ █ ██▄▄ ▄▄▀▄█▄▄ ▄██▄ ▄██ █▀   ▀▄  ▀ ▀▄▄▀ ██▀▄▀▄ ██ ██▄█▄ ▄█▄ ██▀████
████▀██ ▄█▄▀█▀▄▀ ▄▄▄▀▄▀█  ▀█  ▄▄▄▄  ██▀█▄▀█ ▀ ▀▀▀██████▀▀   ▄▄ ▄▄█▄  ████
████▀▀    ▄▀█  ▄██▀▄ █ █ ▄█▄▄ ▄▀▄▀█ █▄██▀  ▄▀█ █ ▄██   ▄ ▄███ █  ███▀████
████▄▀▀▄ ▄▄▄  ▄██▀  ▄█▄▄▄ ▀▄▀██▀▄██▀▄▄██  ▄█▀▄▀ ██▀██▄▄▀█▀▄█▄ ▄▀ ▄█ █████
████▀█▀█▄▄▄▀ ▄██ ██▀▄█▄▀   █ █ █ █▀█▀ ▄█ █▀▀▄██▀█▀ █▀█▄ ▀█▀█▄▀█▀ ▄  █████
█████▄██▄▀▄█▀█ ▄█▀▀▀█▄▄▄█▀▄▀▄ █ ▀█▀█▀▄█ ▄  █▀ █▄█▀   ▄▀█▀█▀███▄ ▄▄▄▄█████
████▀ █  ▄▄▄ ▀▀  ▀▄▀█▀ ▄█  █ █ ▀█▀ ▄▄▄ █ ▄▀▀▄█▄▄█▀█▀▀ █ ▄ █  ▄▄▄ ▄ ▀█████
████▀█ █ █▄█ ▄▄▀████▄▄▀█  ▄▀  ▀▀██ █▄█   ▀▀▀▄▀▄▄▄█▀▀▀▄▀ ██▄█ █▄█ ▀ █▀████
████▄▄█  ▄▄ ▄▄ █ ▄▄▀ ▀ ▄▄ ▄█▀▀▄ ▄▄ ▄ ▄▄██▀▄█ █▄█▀ ▀ ▀  ▄▀▀ █▄  ▄▄▀▄█▀████
████▄█ █▀▄▄█▀▀█ ▀▄ ██▀ ▄▀ █▀█▀▄▀█▄▀█▄  ▄▄ █▄▀  ▀▀ ▄▄ ▄█ ▀▀▀▄▀ ▄▀ ▄▄▄█████
████ ▀▄▄█▄▄ ▀▀█▄ ▄█▀▀▀█▄ ▀ ▄ █ ▀ ▀▀▄▄▄ █▄▄█▄▀█▀▀▀ ▄█▀█  █▀▀█  █ █▄ ▀▀████
████▀▀▄ ██▄▄█▄ ▀ █▀▀▄▀▀█▄▄▀█▀▄█▄▄█ ▀▄█▄█ █▀ ▄▄▄██▄▄█▄█ ▀▀▀▄▀█▄█▀▀▄  ▀████
████▀ ▄ ▀▄▄██ ▄█ █ ▀██▄▄█ ▀▄▀▀ ▀▀▀█▀   ▄▄▄▄ ▀█▄▀▀ ▀▀▀█▀▀██▄▄▄ ▄█▀█▄█▀████
████▀▀█ ██▄▄▀█▄  ▄ ▄▀▀ ▀▀▄ █▄█▀▄▀▄▄ ▀▄▀▄  █▀▀▄ ▄██▄▄ ▄▄██ ▀▄▄███ █▄██████
██████ █▀█▄▀█▀ █  ▀▄ ▀ ▀ ▄ ▀ ▀▀██▀  ▀█▀██▄ ▄▀█ ▄█▄▀  ▄▄███▄█▀▀▄▄▄▄█▀█████
████▀ ▄ █▄▄▀ ▀▄▀▀▀  ▄▄█▄ █▄▄█▀   ▀█▄▀ ▀█ █▀ ▄█▄█▄ ▀ ▀▄▀▀▄ ▄▀▄██ ▀▀█ █████
████▄ ▀  ▀▄▀█▀██▄█▄ ▄▄█▄ ▀ ▄▄▄█▀▀█▄▄ █▄▀▄ ▄ █ █ █▄▀▄█▄▄ ▀▄▀█▄██▄▄▀█▄ ████
██████▀█  ▄▄▀█ ██ █▀▄▄▀▀▄▀▄█ █▄  ▄▄█▀▄▀▀▀▀█▄█▀▀▀ █▄ ▀▀█▄▄  █▀ █▀██▄ █████
████▀█▄ █▄▄▄█▀ ▄▄█▀ ▄  █▄▄█▄▄▄█▀▄▄▀█  ██▄█▄ ▄█ █▄ ▄▀▀▄▄ ▀▄███▄█▄▄▀██▄████
█████▄▄█▄█▄█ █▀ ▄▀ █▄█▀▄▄ ▀  ▄██▄▀ ▄▄▄  ▀█▄▄█▄▄██▀█▄ █ ▀ ▀█▀ ▄▄▄ ▄█▄▄████
████ ▄▄▄▄▄ █▄▀ ██▄▄ ▀██▀   ▀█▀ █ ▀ █▄█  ▄█▀▄▀█ ██ ▄█ █ ▀▀██▀ █▄█  ▄ ▀████
████ █   █ █ ██▄▄█ ▀█ ▀▄█ ▀ █▄▄▀▀█ ▄ ▄▄▀▄ ▄▄▀ ▄▄█▀▄  █ ▀██▀ ▄ ▄ ▄█▄ ▄████
████ █▄▄▄█ █ ██▀▄▄▀▀██▀▄█▄▀█ █▀████▄██▀▄  ▀▀███▀  █ ▄████▀█▀▄     ▀ █████
████▄▄▄▄▄▄▄█▄▄███████▄▄███▄█▄▄██▄██▄█▄█▄████▄█▄▄▄▄███▄█▄██▄██▄█▄▄█▄██████
█████████████████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████████████████
Client config saved to /etc/wireguard/clients/my phone.conf
Enter a name for the new client: ^C
root@amazing-dragonfly:/etc/wireguard#
```

## Usage:
The only command for the script is `./wg.sh`. If the `/etc/wireguard/wg0.conf` config does not exists, it will prompt you for some inputs and create it for you. It will then ask you for client names, generate their configs and update the wireguard config.

To add new clients at a later point, simply execute `wg0.conf` again and it will usage the options from `wg0.conf` automatically to add new clients.

### Options
Some environment variables can be used to configure the script:
| Variable Name | Default Value | Description |
| --- | --- | --- |
| CONFIG_DIR | /etc/wireguard | The full path of the directory where the WireGuard server configuration files are stored. |
| CLIENT_DIR | $CONFIG_DIR/clients | The full path of the directory where the client configuration files are stored. |
| WG_NAME | wg0 | The name of the WireGuard interface. |

### Client config generation
When generating new client configs, it will add them to `/etc/wireguard/clients/<client name>.conf`. It will also generate a QR code in the terminal that you can scan with your phone or similar. The QR code will also be stored at `.../clients/<client name>_qr.txt`.

When generating new IP addresses, it will scan the current `wg0.conf`, then find the highest IP address currently in use by a client and increment it by one, e.g. (10.100.10.1 -> 10.100.10.2, 10.100.10.255 -> 10.100.11.1). For the initial client, the specified subnet in the server config will be used and incremented by one.

## Overriding listening ports
Say you want to setup your proxy server to listen on port `53`, but you are also running a local system DNS server like `resolved-systemd` and want to keep that running for localhost only? In this case, you can specify port `53` to the script during inital config generation and the script will add iptables rulles to redirect all incoming traffic on port `53` to the real port instead. This way, any local services that want to connect to DNS on localhost:53 still can do this, while from the internet port 53 is forwarded to wireguard.

## Notes on security
This script does not add any kill-switches to the client configs in case the connection dies.

This script stores full client configs, including public and private keys on the server.

This script stores the full server config, including public and private keys on the server.
