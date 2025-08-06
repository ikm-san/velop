#!/bin/sh
set -e

# Help function for usage information
show_help() {
  echo "WireGuard VPN Setup Script"
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help    Show this help message"
  exit 0
}

# Check for help flag
[ "$1" = "-h" ] || [ "$1" = "--help" ] && show_help

# Check if WireGuard is installed
if ! command -v wg >/dev/null 2>&1; then
  echo "[!] Error: WireGuard is not installed."
  echo "[!] Please install WireGuard first and try again."
  exit 1
fi

###############################################################################
# 1) Attempt to detect public IP and prompt operator for parameters           #
###############################################################################
# Try to detect public IP
AUTO_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "")
if [ -z "$AUTO_IP" ]; then
  # Fallback to another service if the first one fails
  AUTO_IP=$(curl -s https://ifconfig.me 2>/dev/null || echo "")
fi

echo "[*] WireGuard VPN Setup"
echo "[*] ------------------------------------------------------"

# Check for existing clients to determine next available IP
WG_DIR="/etc/wireguard"
mkdir -p "${WG_DIR}/clients" 
chmod 700 "${WG_DIR}"

# Get the next available client number
NEXT_CLIENT_NUM=2
if [ -d "${WG_DIR}/clients" ]; then
  for CLIENT_FILE in "${WG_DIR}/clients"/*_privatekey; do
    [ -f "$CLIENT_FILE" ] || continue
    CLIENT_NUM=$(echo "$CLIENT_FILE" | grep -o '[0-9]\+' | sort -n | tail -1)
    [ -n "$CLIENT_NUM" ] && [ "$CLIENT_NUM" -ge "$NEXT_CLIENT_NUM" ] && NEXT_CLIENT_NUM=$((CLIENT_NUM + 1))
  done
fi

read -r -p "Client name [Client$NEXT_CLIENT_NUM]: " WG_CLIENT
WG_CLIENT=${WG_CLIENT:-Client$NEXT_CLIENT_NUM}

# Validate and prompt for port number
while true; do
  read -r -p "UDP port [51820]: " WG_PORT
  WG_PORT=${WG_PORT:-51820}
  if ! echo "$WG_PORT" | grep -q '^[0-9]\+$' || [ "$WG_PORT" -lt 1 ] || [ "$WG_PORT" -gt 65535 ]; then
    echo "[!] Invalid port number. Please enter a number between 1-65535."
  else
    break
  fi
done

# Prompt for endpoint IP with detected public IP as default
read -r -p "Endpoint IP [${AUTO_IP:-Enter your public IP}]: " ENDPOINT_IP
if [ -z "$ENDPOINT_IP" ] && [ -n "$AUTO_IP" ]; then
  ENDPOINT_IP=$AUTO_IP
elif [ -z "$ENDPOINT_IP" ]; then
  echo "[!] Warning: No endpoint IP specified. Clients won't be able to connect automatically."
  echo "[!] You'll need to manually edit the client config with your public IP."
  ENDPOINT_IP="0.0.0.0"  # Placeholder that will need to be changed later
fi

# Prompt for DNS settings
read -r -p "DNS servers (comma separated) [1.1.1.1,1.0.0.1]: " DNS_SERVERS
DNS_SERVERS=${DNS_SERVERS:-1.1.1.1,1.0.0.1}

###############################################################################
# 2) Constant values and client IP assignment                                 #
###############################################################################
WG_IF="wg0"
WG_SUBNET="10.0.0"
WG_SERVER_IP="${WG_SUBNET}.1/24"

# Find the next available client IP
WG_CLIENT_NUM=$NEXT_CLIENT_NUM
WG_CLIENT_IP="${WG_SUBNET}.${WG_CLIENT_NUM}/32"

echo "[*] Setting up WireGuard interface ${WG_IF}"
echo "[*] Server IP: ${WG_SERVER_IP}"
echo "[*] Client IP: ${WG_CLIENT_IP}"

###############################################################################
# 3) Keys (generate if missing)                                               #
###############################################################################
echo "[*] Setting up encryption keys"

# Generate server keys if they don't exist
if [ ! -f "${WG_DIR}/privatekey" ]; then
  echo "[*] Generating server keys"
  umask 077
  wg genkey | tee "${WG_DIR}/privatekey" | wg pubkey > "${WG_DIR}/publickey"
fi

# Generate client keys
echo "[*] Generating keys for client ${WG_CLIENT}"
umask 077
wg genkey | tee "${WG_DIR}/clients/${WG_CLIENT}_privatekey" | wg pubkey > "${WG_DIR}/clients/${WG_CLIENT}_publickey"

SERVER_PRIVKEY=$(cat "${WG_DIR}/privatekey")
SERVER_PUBKEY=$(cat  "${WG_DIR}/publickey")
CLIENT_PRIVKEY=$(cat "${WG_DIR}/clients/${WG_CLIENT}_privatekey")
CLIENT_PUBKEY=$(cat  "${WG_DIR}/clients/${WG_CLIENT}_publickey")

###############################################################################
# 4) Network / peer sections                                                  #
###############################################################################
echo "[*] Configuring network interface"

# Check if the interface already exists
INTERFACE_EXISTS=$(uci show network | grep "network.${WG_IF}=" || echo "")

if [ -z "$INTERFACE_EXISTS" ]; then
  echo "[*] Creating WireGuard interface ${WG_IF}"
  uci set network.${WG_IF}=interface
  uci set network.${WG_IF}.proto='wireguard'
  uci set network.${WG_IF}.private_key="${SERVER_PRIVKEY}"
  uci set network.${WG_IF}.listen_port="${WG_PORT}"
  uci set network.${WG_IF}.mtu='1420'
  uci add_list network.${WG_IF}.addresses="${WG_SERVER_IP}"
else
  echo "[*] Updating WireGuard interface ${WG_IF}"
  uci set network.${WG_IF}.private_key="${SERVER_PRIVKEY}"
  uci set network.${WG_IF}.listen_port="${WG_PORT}"
fi

# Add the new client as a peer
echo "[*] Adding client ${WG_CLIENT} as peer"
PEER=$(uci add network wireguard_${WG_IF})
uci set network.${PEER}.public_key="${CLIENT_PUBKEY}"
uci set network.${PEER}.description="${WG_CLIENT}"
uci set network.${PEER}.allowed_ips="${WG_CLIENT_IP}"
uci set network.${PEER}.persistent_keepalive="25"
uci commit network

###############################################################################
# 5) Firewall: attach wg0 to lan + open port                                 #
###############################################################################
echo "[*] Configuring firewall rules"

# Check if WireGuard interface is already in the LAN zone
if ! uci get firewall.@zone[0].network 2>/dev/null | grep -q "${WG_IF}"; then
  echo "[*] Adding ${WG_IF} to LAN zone"
  uci add_list firewall.@zone[0].network="${WG_IF}"
  uci commit firewall
fi

# Check for existing WireGuard rule and create if missing
if ! uci show firewall | grep -q "name='Allow-WireGuard-In'"; then
  echo "[*] Adding firewall rule to allow WireGuard traffic"
  uci add firewall rule
  uci set firewall.@rule[-1].name='Allow-WireGuard-In'
  uci set firewall.@rule[-1].src='wan'
  uci set firewall.@rule[-1].proto='udp'
  uci set firewall.@rule[-1].dest_port="${WG_PORT}"
  uci set firewall.@rule[-1].target='ACCEPT'
  uci commit firewall
fi

###############################################################################
# 6) Restart services                                                         #
###############################################################################
echo "[*] Applying configuration changes"
echo "[*] Restarting network services"
/etc/init.d/network restart
echo "[*] Restarting firewall"
/etc/init.d/firewall restart

###############################################################################
# 7) Write client configuration + QR                                          #
###############################################################################
echo "[*] Creating client configuration"

# Format DNS entries
DNS_FORMATTED=$(echo "$DNS_SERVERS" | tr ',' '\n' | sed 's/^/DNS = /' | tr '\n' ',' | sed 's/,$/\n/')

CFG="${WG_DIR}/clients/${WG_CLIENT}.conf"
cat > "$CFG" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVKEY}
Address    = ${WG_CLIENT_IP}
${DNS_FORMATTED}

[Peer]
PublicKey           = ${SERVER_PUBKEY}
Endpoint            = ${ENDPOINT_IP}:${WG_PORT}
AllowedIPs          = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

echo
echo "[*] Client configuration written to: $CFG"
if command -v qrencode >/dev/null; then
  echo "[*] Generating QR code for easy mobile setup:"
  qrencode -t ansiutf8 < "$CFG"
else
  echo "[*] Client configuration (install qrencode for QR code generation):"
  cat "$CFG"
  echo "[!] Note: qrencode not installed - can't generate QR code"
fi

echo "[*] Endpoint IP: ${ENDPOINT_IP}:${WG_PORT}"
if [ "$ENDPOINT_IP" = "0.0.0.0" ]; then
  echo "[!] Warning: You need to manually edit the client config and replace 0.0.0.0 with your public IP."
fi

echo "[*] Setup complete! Client can now connect using the configuration above."
