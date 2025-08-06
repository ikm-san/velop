# wireguard for Velop WRT Pro 7 LN6001

## 手順
opkg update  
opkg install kmod-wireguard_5.4.213+1.0.20220627-2_arm_cortex-a7_neon-vfpv4.ipk  
opkg install wireguard_1.0.20220627-2_arm_cortex-a7_neon-vfpv4.ipk  
opkg install libqrencode qrencode luci-proto-wireguard luci-app-wireguard  
※ kmodとwireguardはこのレポジトリからDLして利用。他はopkgのリストでOK。


## Wireguard_setup.sh  
いい感じにサクッと設定してQRコードを表示してくれます。  
例えばiPhoneで読み取って、WireguardアプリのVPN設定に流し込んでください。
