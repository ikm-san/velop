#!/bin/bash

# Prompt user for input
echo ""
echo "Please enter the Parent SSID (e.g., Linksys00000):"
echo "親機のSSIDを入力してください (e.g., Linksys00000):"
read ParentSSID

echo ""
echo "Please enter the Parent SSID pass (e.g., 0hWx3qceu@):"
echo "親機のSSIDパスワードを入力してください (e.g., 0hWx3qceu@):"
read ParentSSIDkey

echo ""
echo "Please enter the Parent IP address (e.g., 192.168.10.1):"
echo "親機のIPアドレスを入力してください (e.g., 192.168.10.1):"
read ParentIPaddr

echo ""
echo "Please enter the Child IP address (e.g., 192.168.10.2):"
echo "子機のIPアドレスを入力してください (e.g., 192.168.10.2):"
read ChildIPaddr

# Display the entered values for checking
echo ""
echo "You have entered the following values for verification:"
echo "あなたが入力した値は以下の通りです、念のため確認してください。:"
echo "-----------------------------------"
echo "Parent SSID       : $ParentSSID"
echo "Parent SSID pass  : $ParentSSIDkey"
echo "Parent IP address : $ParentIPaddr"
echo "Child IP address  : $ChildIPaddr"
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
uci set wireless.mld0.ml_ssid="$ParentSSID"
uci set wireless.mld1.ml_ssid="$ParentSSID"
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
uci del network.wan
uci del network.wan6
uci set network.lan.ipaddr="$ChildIPaddr"
uci set network.lan.gateway="$ParentIPaddr"
uci del network.lan.ip6assign
uci del wireless.wifi2.disabled
uci set wireless.ath20.ssid="$ParentSSID"
uci set wireless.ath20.key="$ParentSSIDkey"
uci del wireless.ath20.sae_password
uci add_list wireless.ath20.sae_password="$ParentSSIDkey"
uci set wireless.ath10.ssid="$ParentSSID"
uci set wireless.ath10.key="$ParentSSIDkey"
uci del wireless.ath10.sae_password
uci add_list wireless.ath10.sae_password="$ParentSSIDkey"
uci set wireless.ath00.ssid="$ParentSSID"
uci set wireless.ath00.key="$ParentSSIDkey"
uci del wireless.ath00.sae_password
uci add_list wireless.ath00.sae_password="$ParentSSIDkey"
uci del wireless.ath00.wds='1'
uci del wireless.ath10.wds='1'
uci del wireless.ath20.wds='1'
uci set wireless.ath10.mld='mld0'
uci set wireless.ath20.mld='mld0'
uci set wireless.ath00.disassoc_low_ack='0'
uci set wireless.ath10.disassoc_low_ack='0'
uci set wireless.ath20.disassoc_low_ack='0'

# Disable and stop unnecessary services
/etc/init.d/firewall disable && /etc/init.d/firewall stop
/etc/init.d/dnsmasq disable && /etc/init.d/dnsmasq stop
/etc/init.d/odhcpd disable && /etc/init.d/odhcpd stop

# Additional wireless settings
uci set wireless.ath21=wifi-iface
uci set wireless.ath21.ifname='ath21'
uci set wireless.ath21.ssid="$ParentSSID"
uci add_list wireless.ath21.sae_password="$ParentSSIDkey"
uci set wireless.ath21.key="$ParentSSIDkey"
uci set wireless.ath21.device='wifi2'
uci set wireless.ath21.en_6g_sec_comp='0'
uci set wireless.ath21.wds='1'
uci set wireless.ath21.ieee80211w='2'
uci set wireless.ath21.sae='1'
uci set wireless.ath21.mode='sta'
uci set wireless.ath21.encryption='ccmp'
uci set wireless.ath21.network='lan'

# Commit changes
uci commit

echo "WDS Child Configuration applied successfully. Please reboot the router."
echo "WDSの子機設定が完了しました。再起動を実行してください。"

# Prompt the user for confirmation to reboot
read -p "再起動を実行しますか？(N/y): " choice

# Handle the user's input for reboot
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "Rebooting the system..."
    /sbin/reboot
else
    echo "Reboot canceled."
fi
