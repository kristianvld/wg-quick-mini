# Minimal, automatic shell script for wg-quick
A minimal shell script to create a wg-quick config, generate clients (with qr-codes), from user input with minimal fuzz or extra files. It will simply create a new config at `/etc/wireguard/wg0.conf`, prompt you for some settings (subnet, listen port & dns server), then create the config. Client configs and qr-codes are stored at `/etc/wireguard/clients/` with the names `<name>.conf` and `<name>_qr.txt`. IPs are automatically incremented from `wg0.conf`, no extra files needed, and adaptive to if you want to modify `wg0.conf` yourself.

# Features
* Small single bash script
* Few dependencies (wg-quick/wireguard, curl, qrencode, iptables)
* Generate a small wg-quick config to easily get started
* No extra files, only `wg0.conf` and client configs stored on disk
* Sane defaults with auto-fetch of network interface & public ip
* Auto increment clients from existing `wg0.conf`
* Add new clients by subsequent runs and auto-reload to apply changes
* Supports overriding listening ports
* Full IPv4 and IPv6 support

## Get started
```bash
wget '<url-to-wg.sh>' # TODO: fix url
chmod +x wg.sh
./wg.sh
```
See the ascii cinema below for example execution.
*TODO: fix recording*

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