#!/bin/bash

for cmd in wg wg-quick curl qrencode ip iptables ip6tables sed grep tail sort cat tee xargs printf mkdir tee cut awk paste; do
    if ! which $cmd >/dev/null; then
        echo "Command '$cmd' not found! Please make sure it is installed before running this script again."
        FAIL=1
    fi
done
[ "$FAIL" == "1" ] && exit 1

prompt() {
    local prompt="$1" var_name="$2" default="$3" valid_values=("${@:4}")
    [ -n "$default" ] && prompt="$prompt (default: $default)"
    [ -n "$default" ] && [ ${#valid_values[@]} -gt 0 ] && valid_values=("$default" "${valid_values[@]}")
    [ ${#valid_values[@]} -gt 0 ] && IFS="/" && prompt="$prompt [${valid_values[*]}]" && IFS=$' \t\n'
    while true; do
        read -rep "$prompt: " user_input
        [ -z "$user_input" ] && [ -n "$default" ] && user_input="$default"
        if [ ${#valid_values[@]} -eq 0 ] || [[ " ${valid_values[*]} " == *" $user_input "* ]]; then
            [ -n "$user_input" ] && declare -g "$var_name"="$user_input" && break
        else
            echo "Invalid value '$user_input'"
        fi
    done
}

option() {
    grep "$1" "$SERVER_CONFIG" | cut -d '=' -f 2- | sed -E 's/^\s+|\s+$//g'
}

port_in_use() {
    ss -H -uln sport = ":$1" | grep -q .
}

first_available_port() {
    local port="$1"
    while port_in_use "$port"; do
        port=$((port + 1))
    done
    echo "$port"
}

warn_if_default_port_busy() {
    local port="$1" label="$2" first_free
    if port_in_use "$port"; then
        first_free=$(first_available_port "$port")
        echo "Default $label port $port is currently in use."
        echo "You can still use it by mapping incoming traffic to a separate real listen port (fake port mode)."
        [ "$first_free" != "$port" ] && echo "First available port appears to be $first_free."
    fi
}

expand_ipv6() {
    IFS=:
    read -ra blocks <<< "$1"
    for ((i=0; i < 8; i++)); do
        while [[ -z ${blocks[i]} ]] && [[ ${#blocks[@]} -lt 8 ]]; do
            blocks=( "${blocks[@]:0:i}" "0" "${blocks[@]:i}" )
        done
        blocks[i]=$(printf "%04x" "0x0${blocks[i]}")
    done
    echo "${blocks[*]}"
}

compress_ipv6() {
    local ip=""; ip=$(echo "$1" | sed -E 's/(^|:)0+([0-9])/\1\2/g')
    echo "${ip//$(echo "$ip" | grep -oE '(^|:)[0:]*(:|$)' | awk 'length > max { max=length; longest=$0 } END { print longest }')/::}"
}

increment_blocks() {
    local base="$1" format="$2" delim="$3" max="$4" ip="$5"
    IFS=$delim
    read -ra blocks <<< "$ip"
    local -i carry=1
    for ((i=${#blocks[@]}-1; i>=0 && carry; i--)); do
        local value=$(($base#${blocks[i]} + carry))
        (( "$value" > max )) && value=0 || carry=0
        blocks[i]=$(printf "$format" "$value")
    done
    echo "${blocks[*]}"
}

increment_ip() {
    if [[ "$1" =~ : ]]; then
        compress_ipv6 "$(increment_blocks 16 "%04x" ':' 65535 "$(expand_ipv6 "$1")")"
    else 
        increment_blocks 10 "%d" '.' 255 "$1"
    fi
}


CONFIG_DIR=${CONFIG_DIR:-"/etc/wireguard"}
CLIENT_DIR=${CLIENT_DIR:-"$CONFIG_DIR/clients"}
WG_NAME=${WG_NAME:-"wg0"}
SERVER_CONFIG="$CONFIG_DIR/$WG_NAME.conf"

# Check if the WireGuard server config exists, create if not
if [ ! -f "$SERVER_CONFIG" ]; then
    echo "WireGuard server config not found. Creating..."
    prompt "Enter internal CIDR mask" INTERNAL_CIDR "10.100.10.1/24, fd00:100::1/64"
    DEFAULT_PORT=51820
    warn_if_default_port_busy "$DEFAULT_PORT" "listen"
    while true; do
        prompt "Enter port to listen to " PORT "$DEFAULT_PORT"
        if ! port_in_use "$PORT"; then
            break
        fi

        echo "Port $PORT is currently in use."
        prompt "Use this as the fake/public port and pick a different real listen port?" USE_FAKE_MODE "yes" "no"
        if [ "$USE_FAKE_MODE" == "yes" ]; then
            FAKE_PORT="$PORT"
            DEFAULT_REAL_PORT=51820
            warn_if_default_port_busy "$DEFAULT_REAL_PORT" "real listen"
            while true; do
                prompt "Enter the real port to listen to" PORT "$DEFAULT_REAL_PORT"
                if port_in_use "$PORT"; then
                    NEXT_REAL_PORT=$(first_available_port "$PORT")
                    echo "Real listen port $PORT is currently in use."
                    [ "$NEXT_REAL_PORT" != "$PORT" ] && echo "Try port $NEXT_REAL_PORT."
                    DEFAULT_REAL_PORT="$NEXT_REAL_PORT"
                    continue
                fi
                break
            done
            break
        fi

        NEXT_PORT=$(first_available_port "$PORT")
        [ "$NEXT_PORT" != "$PORT" ] && echo "Try port $NEXT_PORT."
        DEFAULT_PORT="$NEXT_PORT"
    done
    prompt "DNS server(s) for clients to use" DNS "1.1.1.1, 2606:4700:4700::1111"
    prompt "Main incoming network interface" INTERFACE "$(ip route | awk '/^default/ {print $5}' | head -n 1)"
    prompt "Allow internal traffic between clients" ALLOW_INTERNAL_TRAFFIC "Yes" "no"


    CONFIG="[Interface]
Address = $INTERNAL_CIDR
ListenPort = $PORT
PrivateKey = $(wg genkey)
# DNS = $DNS"
    [ -n "$FAKE_PORT" ] && CONFIG="$CONFIG
# FakePort = $FAKE_PORT"
    CONFIG="$CONFIG

# Allow packets towards wireguard to be forwareded
PostUp = iptables -A FORWARD -i %i -o $INTERFACE -j ACCEPT
PostUp = ip6tables -A FORWARD -i %i -o $INTERFACE -j ACCEPT
PostDown = iptables -D FORWARD -i %i -o $INTERFACE -j ACCEPT
PostDown = ip6tables -D FORWARD -i %i -o $INTERFACE -j ACCEPT

# NAT traffic from wireguard
PostUp = iptables -t nat -I POSTROUTING -o $INTERFACE -j MASQUERADE
PostUp = ip6tables -t nat -I POSTROUTING -o $INTERFACE -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE
PostDown = ip6tables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE

# Configure linux to forward packets
PostUp = sysctl -q -w net.ipv4.ip_forward=1
PostUp = sysctl -q -w net.ipv6.conf.all.forwarding=1
PostDown = sysctl -q -w net.ipv4.ip_forward=0
PostDown = sysctl -q -w net.ipv6.conf.all.forwarding=0
"

    if [ "$ALLOW_INTERNAL_TRAFFIC" == "no" ]; then
        CONFIG="$CONFIG
# Block traffic between clients
PostUp = iptables -A FORWARD -i %i -o %i -j DROP
PostUp = ip6tables -A FORWARD -i %i -o %i -j DROP
PostDown = iptables -D FORWARD -i %i -o %i -j DROP
PostDown = ip6tables -D FORWARD -i %i -o %i -j DROP
"
    fi

    if [ -n "$FAKE_PORT" ]; then
        CONFIG="$CONFIG
# Fake server port. Forward incoming traffic on port $FAKE_PORT -> $PORT
PostUp = iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport $FAKE_PORT -j REDIRECT --to-port $PORT
PostUp = ip6tables -t nat -A PREROUTING -i $INTERFACE -p udp --dport $FAKE_PORT -j REDIRECT --to-port $PORT
PostDown = iptables -t nat -D PREROUTING -i $INTERFACE -p udp --dport $FAKE_PORT -j REDIRECT --to-port $PORT
PostDown = ip6tables -t nat -D PREROUTING -i $INTERFACE -p udp --dport $FAKE_PORT -j REDIRECT --to-port $PORT

# Fake server port responce. Make it look like responces from $PORT are coming from $FAKE_PORT
PostUp = iptables -t nat -A POSTROUTING -o $INTERFACE -p udp --sport $PORT -j SNAT --to-source :$FAKE_PORT
PostUp = ip6tables -t nat -A POSTROUTING -o $INTERFACE -p udp --sport $PORT -j SNAT --to-source :$FAKE_PORT
PostDown = iptables -t nat -D POSTROUTING -o $INTERFACE -p udp --sport $PORT -j SNAT --to-source :$FAKE_PORT
PostDown = ip6tables -t nat -D POSTROUTING -o $INTERFACE -p udp --sport $PORT -j SNAT --to-source :$FAKE_PORT
"
    fi

    echo "$CONFIG
" > "$SERVER_CONFIG"

    echo "Created WireGuard server config at $SERVER_CONFIG"

    wg-quick up "$WG_NAME"
fi

PUBLIC_IP=""
prompt "Allow this script to query icanhazip.com (Cloudflair owned) to determin the servers public ipv4 & ipv6 address?" ALLOW_ICANHAZIP "yes"
if [ "$ALLOW_ICANHAZIP" == "yes" ]; then
    PUBLIC_IP=$(curl -s https://ipv{4,6}.icanhazip.com/ | paste -s -d ',' - | sed 's/,/, /g')
fi
echo "The client can only recieve one endpoint. If you want to use both ipv4 and ipv6, you need to specify a domain name that resolves to both ipv4 and ipv6."
prompt "Enter your server public ip or domain (detected $PUBLIC_IP)" PUBLIC_IP "$(cut -d "," -f 1 <<< "$PUBLIC_IP")"
PORT=$(option FAKE_PORT)
[ -z "$PORT" ] && PORT=$(option "FakePort")
[ -z "$PORT" ] && PORT=$(option "ListenPort")
SERVER_PUBKEY=$(option PrivateKey | wg pubkey)
DNS=$(option DNS)

# Function to generate a new client config
generate_client_config() {
    local CLIENT_NAME="$1"
    local CLIENT_IP

    # Get the highest client IP from the server config
    CLIENT_IP=$(option AllowedIPs)
    [ -z "$CLIENT_IP" ] && CLIENT_IP=$(option Address)
    CLIENT_IPV4=$(increment_ip "$(echo "$CLIENT_IP" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1)")
    [ -n "$CLIENT_IPV4" ] && CLIENT_IPV4="$CLIENT_IPV4/32"
    CLIENT_IPV6=$(increment_ip "$(
    for ipv6 in $(echo "$CLIENT_IP" | grep -ioE '([0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}'); do 
        expand_ipv6 "$ipv6"
    done | sort | tail -1)")
    [ -n "$CLIENT_IPV6" ] && CLIENT_IPV6="$CLIENT_IPV6/128"
    CLIENT_IP=$(echo "$CLIENT_IPV4" "$CLIENT_IPV6" | xargs | sed 's/ /, /g')
    echo "Assigning new client ip(s): $CLIENT_IP"

    # Generate client keys and config
    CLIENT_PRIVKEY=$(wg genkey)
    CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)
    CLIENT_PSK=$(wg genpsk)
    mkdir -p "$CLIENT_DIR"
    CLIENT_CONFIG="$CLIENT_DIR/$CLIENT_NAME.conf"
    CLIENT_CONFIF_QR="$CLIENT_DIR/$CLIENT_NAME"_qr.txt

    echo "# $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUBKEY
PresharedKey = $CLIENT_PSK
AllowedIPs = $CLIENT_IP
" >> "$SERVER_CONFIG"

    echo "Restarting wireguard server to add client..."
    wg-quick down "$WG_NAME"
    wg-quick up "$WG_NAME"

    mkdir -p "$CLIENT_DIR"
    echo "[Interface]
PrivateKey = $CLIENT_PRIVKEY
DNS = $DNS
Address = $CLIENT_IP

[Peer]
PublicKey = $SERVER_PUBKEY
PresharedKey = $CLIENT_PSK
Endpoint = $PUBLIC_IP:$PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
" > "$CLIENT_CONFIG"

    # Display QR code
    qrencode -t ansiutf8 < "$CLIENT_CONFIG" | tee "$CLIENT_CONFIF_QR"

    echo "Client config saved to $CLIENT_CONFIG"
}

# Main menu
while true; do
    prompt "Enter a name for the new client" CLIENT_NAME
    generate_client_config "$CLIENT_NAME"
done
