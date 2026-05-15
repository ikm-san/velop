#!/bin/sh

# Japanese LuCI setup for OpenWrt 19.07 on LN6001-JP

retry_update_opkg() {
    local max_retries=3
    local count=0
    local success=0

    while [ "$count" -lt "$max_retries" ]; do
        echo "Updating opkg (attempt $(($count + 1))/$max_retries)"
        opkg update && success=1 && break
        count=$(($count + 1))
        echo "opkg update failed. Retrying..."
    done

    if [ "$success" -eq 0 ]; then
        echo "Failed to update opkg after $max_retries attempts."
        return 1
    fi
}

retry_install() {
    local package=$1
    local max_retries=3
    local count=0
    local success=0

    while [ "$count" -lt "$max_retries" ]; do
        echo "Installing $package (attempt $(($count + 1))/$max_retries)"
        opkg install "$package" && success=1 && break
        count=$(($count + 1))
        echo "$package installation failed. Retrying..."
    done

    if [ "$success" -eq 0 ]; then
        echo "Failed to install $package after $max_retries attempts."
        return 1
    fi
}

OS_VERSION=$(awk -F"'" '/DISTRIB_RELEASE/{print substr($2,1,2)}' /etc/openwrt_release 2>/dev/null | grep -oE '[0-9]+')

if [ "$OS_VERSION" != "19" ]; then
    echo "This script is intended for OpenWrt 19.07 on LN6001-JP."
    echo "OpenWrt 19.07 / LN6001-JP向けのスクリプトです。"
    echo "Detected version: ${OS_VERSION:-unknown}"
    exit 1
fi

LUCi_JP_PACKAGES='
luci-i18n-base-ja
luci-i18n-ddns-ja
luci-i18n-firewall-ja
luci-i18n-openvpn-ja
luci-i18n-opkg-ja
luci-i18n-upnp-ja
'

retry_update_opkg || exit 1

failed_packages=""

for package in $LUCi_JP_PACKAGES; do
    if ! retry_install "$package"; then
        failed_packages="$failed_packages $package"
    fi
done

if [ -n "$failed_packages" ]; then
    echo "Some Japanese translation packages could not be installed:$failed_packages"
    echo "日本語化パッケージの一部をインストールできませんでした:$failed_packages"
    exit 1
fi

uci set system.@system[0].zonename='Asia/Tokyo'
uci set system.@system[0].timezone='JST-9'
uci set luci.main.lang='ja'
uci commit system
uci commit luci

/etc/init.d/uhttpd restart >/dev/null 2>&1
/etc/init.d/rpcd restart >/dev/null 2>&1

echo ""
echo "Japanese LuCI packages installed successfully."
echo "LuCIの日本語化パッケージを導入しました。"
echo "The default LuCI language is now set to Japanese."
echo "LuCI UIメニューの既定言語を日本語に設定しました。"
echo "The system timezone is now set to Asia/Tokyo."
echo "システムのタイムゾーンを Asia/Tokyo に設定しました。"
echo "Some vendor-specific LuCI pages may stay in English because no Japanese translation package is published for OpenWrt 19.07."
echo "OpenWrt 19.07 で日本語パッケージが公開されていない独自LuCI画面は、英語表示のままです。"

printf "再起動を実行しますか？(N/y): "
read choice

case "$choice" in
    y|Y)
        echo "Rebooting the system..."
        /sbin/reboot
        ;;
    *)
        echo "Reboot canceled."
        ;;
esac