wireguard for Velop WRT Pro 7 LN6001

opkg update

#この２つはここからＤＬ
opkg install kmod-wireguard_5.4.213+1.0.20220627-2_arm_cortex-a7_neon-vfpv4.ipk
opkg install wireguard_1.0.20220627-2_arm_cortex-a7_neon-vfpv4.ipk

＃これらはlistからでＯＫ
opkg install libqrencode qrencode luci-proto-wireguard luci-app-wireguard
