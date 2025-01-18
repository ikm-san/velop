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

# We only need the first two digits to distinguish 19 from 21+
OS_VERSION=$(awk -F"'" '/DISTRIB_RELEASE/{print substr($2,1,2)}' /etc/openwrt_release 2>/dev/null | grep -oE '[0-9]+')

uci set system.@system[0].zonename='Asia/Tokyo'
uci set system.@system[0].timezone='JST-9'
uci set system.@system[0].hostname='WifiAP'
uci set network.lan.proto='static'

uci set network.lan.ipaddr="$ChildIPaddr"
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway="$ParentIPaddr"
uci delete network.lan.ip6assign 2>/dev/null
uci set network.lan.stp='1'
uci set network.lan.igmp_snooping='1'

uci set dhcp.lan.ignore='1'
uci delete dhcp.lan.start 2>/dev/null
uci delete dhcp.lan.limit 2>/dev/null
uci delete dhcp.lan.leasetime 2>/dev/null
uci delete dhcp.lan.force 2>/dev/null
uci delete dhcp.lan.ndp 2>/dev/null
uci delete dhcp.lan.ra 2>/dev/null
uci delete dhcp.lan.dhcpv6 2>/dev/null
uci delete dhcp.lan.ra_management 2>/dev/null
uci delete dhcp.lan.ra_slaac 2>/dev/null

uci delete network.wan 2>/dev/null
uci delete network.wan6 2>/dev/null
uci delete dhcp.wan 2>/dev/null

PORTS='eth0 eth1 eth2 eth3 eth4'

if [ "$OS_VERSION" = "19" ]; then
    uci set network.lan.ifname="$PORTS"
else
    uci set network.lan.device='br-lan' 2>/dev/null
    uci set network.lan.type='bridge'    2>/dev/null
    uci set network.br_lan='device'      2>/dev/null
    uci set network.br_lan.type='bridge' 2>/dev/null
    uci set network.br_lan.name='br-lan' 2>/dev/null
    uci set network.br_lan.ports="$PORTS"
fi

uci set wireless.mld0.ml_ssid="$ParentSSID"
uci set wireless.mld1.ml_ssid="$ParentSSID"
uci set wireless.ath00.ssid="$ParentSSID"
uci set wireless.ath00.key="$ParentSSIDkey"
uci delete wireless.ath00.sae_password 2>/dev/null
uci add_list wireless.ath00.sae_password="$ParentSSIDkey"
uci delete wireless.ath00.wds 2>/dev/null

uci set wireless.ath10.ssid="$ParentSSID"
uci set wireless.ath10.key="$ParentSSIDkey"
uci delete wireless.ath10.sae_password 2>/dev/null
uci add_list wireless.ath10.sae_password="$ParentSSIDkey"
uci delete wireless.ath10.wds 2>/dev/null

uci set wireless.ath20.ssid="$ParentSSID"
uci set wireless.ath20.key="$ParentSSIDkey"
uci delete wireless.ath20.sae_password 2>/dev/null
uci add_list wireless.ath20.sae_password="$ParentSSIDkey"
uci delete wireless.ath20.wds 2>/dev/null

# WDS interface (ath21)
uci set wireless.ath21=wifi-iface
uci set wireless.ath21.ifname='ath21'
uci set wireless.ath21.ssid="$ParentSSID"
uci delete wireless.ath21.sae_password 2>/dev/null
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

/etc/init.d/firewall disable 2>/dev/null && /etc/init.d/firewall stop 2>/dev/null
/etc/init.d/dnsmasq disable 2>/dev/null && /etc/init.d/dnsmasq stop 2>/dev/null
/etc/init.d/odhcpd disable 2>/dev/null && /etc/init.d/odhcpd stop 2>/dev/null

uci commit

echo "net.ipv6.conf.eth4.proxy_ndp=0" >> /etc/sysctl.conf 2>/dev/null
echo "net.ipv6.conf.br-lan.proxy_ndp=0" >> /etc/sysctl.conf 2>/dev/null
sysctl -p >/dev/null 2>&1

echo ""
echo "WDS Child Configuration applied successfully. Please reboot the router."
echo "WDSの子機設定が完了しました。再起動を実行してください。"

# Prompt the user for confirmation to reboot
read -p "再起動を実行しますか？(N/y): " choice
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "Rebooting the system..."
    /sbin/reboot
else
    echo "Reboot canceled."
fi