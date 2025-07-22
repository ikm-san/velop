#!/bin/sh
# filepath: install_wireguard.sh

REPO_BASE="https://raw.githubusercontent.com/ikm-san/velop/main/wireguard"
TMP_DIR="/tmp/wireguard_install"
mkdir -p $TMP_DIR
cd $TMP_DIR

FILES=(
    "kmod-crypto-hash_5.4.213-1_arm_cortex-a7_neon-vfpv4.ipk"
    "kmod-crypto-kpp_5.4.213-1_arm_cortex-a7_neon-vfpv4.ipk"
    "kmod-crypto-lib-chacha20_5.4.213-1_arm_cortex-a7_neon-vfpv4.ipk"
    "kmod-crypto-lib-chacha20poly1305_5.4.213-1_arm_cortex-a7_neon-vfpv4.ipk"
    "kmod-crypto-lib-curve25519_5.4.213-1_arm_cortex-a7_neon-vfpv4.ipk"
    "kmod-crypto-lib-poly1305_5.4.213-1_arm_cortex-a7_neon-vfpv4.ipk"
    "kmod-wireguard_5.4.213-1_arm_cortex-a7_neon-vfpv4.ipk"
    "wireguard-tools_1.0.20191226-1_arm_cortex-a7_neon-vfpv4.ipk"
)

echo "Downloading WireGuard packages..."
for file in "${FILES[@]}"; do
    echo "Downloading: $file"
    wget "$REPO_BASE/$file" -O "$file"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to download $file"
        exit 1
    fi
done

echo "Installing packages..."
opkg install --force-downgrade --force-depends kmod-crypto-hash_*.ipk
opkg install --force-downgrade --force-depends kmod-crypto-kpp_*.ipk
opkg install --force-downgrade --force-depends kmod-crypto-lib-poly1305_*.ipk
opkg install --force-downgrade --force-depends kmod-crypto-lib-chacha20_*.ipk
opkg install --force-downgrade --force-depends kmod-crypto-lib-chacha20poly1305_*.ipk
opkg install --force-downgrade --force-depends kmod-crypto-lib-curve25519_*.ipk
opkg install --force-downgrade --force-depends kmod-wireguard_*.ipk
opkg install --force-downgrade wireguard-tools_*.ipk

echo "Installing LuCI WireGuard protocol support..."
opkg update
opkg install luci-proto-wireguard

cd /
rm -rf $TMP_DIR

echo "WireGuard installation completed"
echo "Configure via LuCI web interface or /etc/config/network"
