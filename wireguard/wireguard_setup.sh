#!/bin/sh
set -e

###############################################################################
# 1) Prompt the operator for parameters (with sane defaults)                  #
###############################################################################
read -r -p "Client name  [WG_CLIENT]  : " WG_CLIENT
WG_CLIENT=${WG_CLIENT:-WG_CLIENT}

read -r -p "UDP port     [51820]      : " WG_PORT
WG_PORT=${WG_PORT:-51820}

read -r -p "Endpoint IP  [0.0.0.0]    : " ENDPOINT_IP
ENDPOINT_IP=${ENDPOINT_IP:-0.0.0.0}

###############################################################################
# 2) Constant values                                                          #
###############################################################################
WG_IF="wg0"
WG_SUBNET="10.0.0"
WG_SERVER_IP="${WG_SUBNET}.1/24"
WG_CLIENT_IP="${WG_SUBNET}.2/32"
WG_DIR="/etc/wireguard"

echo "[*] Create /etc/wireguard"
mkdir -p "${WG_DIR}/clients";  chmod 700 "${WG_DIR}"

###############################################################################
# 3) Keys (generate if missing)                                               #
###############################################################################
[ -f "${WG_DIR}/privatekey" ] || umask 077 && \
  wg genkey | tee "${WG_DIR}/privatekey" | wg pubkey > "${WG_DIR}/publickey"

[ -f "${WG_DIR}/clients/${WG_CLIENT}_privatekey" ] || umask 077 && \
  wg genkey | tee "${WG_DIR}/clients/${WG_CLIENT}_privatekey" \
  | wg pubkey > "${WG_DIR}/clients/${WG_CLIENT}_publickey"

SERVER_PRIVKEY=$(cat "${WG_DIR}/privatekey")
SERVER_PUBKEY=$(cat  "${WG_DIR}/publickey")
CLIENT_PRIVKEY=$(cat "${WG_DIR}/clients/${WG_CLIENT}_privatekey")
CLIENT_PUBKEY=$(cat  "${WG_DIR}/clients/${WG_CLIENT}_publickey")

###############################################################################
# 4) Network / peer sections                                                  #
###############################################################################
uci batch <<EOF
set network.${WG_IF}=interface
set network.${WG_IF}.proto='wireguard'
set network.${WG_IF}.private_key='${SERVER_PRIVKEY}'
set network.${WG_IF}.listen_port='${WG_PORT}'
set network.${WG_IF}.mtu='1280'
del_list network.${WG_IF}.addresses
add_list network.${WG_IF}.addresses='${WG_SERVER_IP}'
EOF

# remove existing peers for this interface
for P in $(uci show network | grep "=wireguard_${WG_IF}" | cut -d. -f2 | cut -d= -f1); do
  uci delete network.$P
done

PEER=$(uci add network wireguard_${WG_IF})
uci set network.${PEER}.public_key="${CLIENT_PUBKEY}"
uci set network.${PEER}.description="${WG_CLIENT}"
uci set network.${PEER}.allowed_ips="${WG_CLIENT_IP}"
uci set network.${PEER}.persistent_keepalive="25"
uci commit network

###############################################################################
# 5) Firewall: attach wg0 to lan + open port                                  #
###############################################################################
if ! uci get firewall.@zone[0].network 2>/dev/null | grep -q "${WG_IF}"; then
  uci add_list firewall.@zone[0].network="${WG_IF}"
  uci commit firewall
fi

if ! uci show firewall | grep -q "name='Allow-WireGuard-In'"; then
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
/etc/init.d/network  restart
/etc/init.d/firewall restart

###############################################################################
# 7) Write client configuration + QR                                          #
###############################################################################
CFG="${WG_DIR}/clients/${WG_CLIENT}.conf"
cat > "$CFG" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVKEY}
Address    = ${WG_CLIENT_IP}
DNS        = 1.1.1.1

[Peer]
PublicKey           = ${SERVER_PUBKEY}
Endpoint            = ${ENDPOINT_IP}:${WG_PORT}
AllowedIPs          = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

echo
echo "Client configuration written to: $CFG"
if command -v qrencode >/dev/null; then
  qrencode -t ansiutf8 < "$CFG"
else
  cat "$CFG"
  echo "[qrencode not installed]"
fi
echo "[*] All done"
