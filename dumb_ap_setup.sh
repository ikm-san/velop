#!/bin/bash

# Prompt user for input
echo ""
echo "Please enter the SSID (e.g., Linksys00000):"
echo "SSIDを入力してください (e.g., Linksys00000):"
read SSID

echo ""
echo "Please enter the SSID pass (e.g., 0hWx3qceu@):"
echo "SSIDパスワードを入力してください (e.g., 0hWx3qceu@):"
read SSIDkey

echo ""
echo "Please enter the gateway IP address (e.g., 192.168.10.1):"
echo "ゲートウェイのIPアドレスを入力してください (e.g., 192.168.10.1):"
read GatewayIPaddr

echo ""
echo "Please enter the Dumb AP IP address (e.g., 192.168.10.2):"
echo "Dumb APのIPアドレスを入力してください (e.g., 192.168.10.2):"
read DumbAPIPaddr

# Display the entered values for checking
echo ""
echo "You have entered the following values for verification:"
echo "あなたが入力した値は以下の通りです、念のため確認してください。:"
echo "-----------------------------------"
echo "SSID            : $SSID"
echo "SSID pass       : $SSIDkey"
echo "Gateway IP      : $GatewayIPaddr"
echo "Dumb AP IP      : $DumbAPIPaddr"
echo "-----------------------------------"

# Ask for confirmation before proceeding
echo ""
echo "Are these values correct? (y/n):"
echo "これらの値で間違いないでしょうか？ (y/n):"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo "Configuration aborted. Please run the script again."
    echo "設定作業を中止しました。再度スクリプトを実行してください。"
    exit 1
fi

# Apply UCI settings with user input
uci set wireless.mld0.ml_ssid="$SSID"
uci set wireless.mld1.ml_ssid="$SSID"
uci del network.globals.ula_prefix
uci set system.@system[0].zonename='Asia/Tokyo'
uci set system.@system[0].timezone='JST-9'
uci set network.lan.stp='1'
uci set network.lan.igmp_snooping='1'
uci del dhcp.lan.start
uci del dhcp.lan.limit
uci del dhcp.lan.leasetime
uci del dhcp.lan.force
uci set dhcp.lan.ndp='relay'
uci set dhcp.lan.ra='relay'
uci del dhcp.lan.ra_management
uci set dhcp.lan.dhcpv6='relay'
uci set dhcp.lan.ignore='1'
uci set network.lan.ipaddr="$DumbAPIPaddr"
uci set network.lan.gateway="$GatewayIPaddr"
uci del network.lan.ip6assign
uci del wireless.wifi2.disabled
uci set wireless.ath20.ssid="$SSID"
uci set wireless.ath20.key="$SSIDkey"
uci del wireless.ath20.sae_password
uci add_list wireless.ath20.sae_password="$SSIDkey"
uci set wireless.ath10.ssid="$SSID"
uci set wireless.ath10.key="$SSIDkey"
uci del wireless.ath10.sae_password
uci add_list wireless.ath10.sae_password="$SSIDkey"
uci set wireless.ath00.ssid="$SSID"
uci set wireless.ath00.key="$SSIDkey"
uci del wireless.ath00.sae_password
uci add_list wireless.ath00.sae_password="$SSIDkey"

# Additional settings to delete network and DHCP interfaces
uci delete dhcp.wan
uci delete network.wan
uci delete network.wan6

# Update the LAN interface to include eth4 in the bridge
uci set network.lan.ifname='eth0 eth1 eth2 eth3 eth4'

# Disable and stop unnecessary services
/etc/init.d/firewall disable && /etc/init.d/firewall stop
/etc/init.d/dnsmasq disable && /etc/init.d/dnsmasq stop
/etc/init.d/odhcpd disable && /etc/init.d/odhcpd stop

# Commit changes
uci commit

echo "Dumb AP Configuration applied successfully. Please reboot the router."
echo "Dumb APの設定が完了しました。再起動を実行してください。"

# Prompt the user for confirmation to reboot
read -p "再起動を実行しますか？(N/y): " choice

# Handle the user's input for reboot
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "Rebooting the system..."
    /sbin/reboot
else
    echo "Reboot canceled."
fi
