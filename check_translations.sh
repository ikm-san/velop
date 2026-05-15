#!/bin/bash
INSTALLED_PACKAGES=(
    "luci-app-ddns" "luci-app-firewall" "luci-app-openvpn" "luci-app-opkg" "luci-app-upnp"
    "luci-base" "luci-compat" "luci-hyfi" "luci-hyfi-advanced" "luci-lib-ip"
    "luci-lib-ipkg" "luci-lib-jsonc" "luci-lib-nixio" "luci-mod-admin-full" "luci-mod-network"
    "luci-mod-status" "luci-mod-system" "luci-proto-ipv6" "luci-proto-ppp" "luci-theme-bootstrap"
    "luci-whc" "luci-whc-lbd" "luci-whc-lbd-advanced" "luci-whc-lbd-diaglog" "luci-whc-repacd"
    "luci-whc-repacd-advanced" "luci-wsplc" "luci-wsplc-advanced"
)

echo "### Found Japanese Translation Packages ###"
FOUND_COUNT=0
for PKG in "${INSTALLED_PACKAGES[@]}"; do
    # Map package names to expected translation package names
    # Base/Mod/Proto usually have i18n names corresponding to the component
    # e.g. luci-base -> luci-i18n-base-ja
    # e.g. luci-app-ddns -> luci-i18n-ddns-ja
    
    TRANS_PKG=""
    if [[ \$PKG == luci-app-* ]]; then
        TRANS_PKG="luci-i18n-\${PKG#luci-app-}-ja"
    elif [[ \$PKG == luci-mod-* ]]; then
        TRANS_PKG="luci-i18n-\${PKG#luci-mod-}-ja"
    elif [[ \$PKG == luci-proto-* ]]; then
        TRANS_PKG="luci-i18n-\${PKG#luci-proto-}-ja"
    elif [[ \$PKG == luci-base ]]; then
        TRANS_PKG="luci-i18n-base-ja"
    elif [[ \$PKG == luci-lib-* ]]; then
        TRANS_PKG="luci-i18n-\${PKG#luci-lib-}-ja"
    elif [[ \$PKG == luci-theme-* ]]; then
        TRANS_PKG="luci-i18n-\${PKG#luci-theme-}-ja"
    else
        TRANS_PKG="luci-i18n-\${PKG#luci-}-ja"
    fi

    if grep -q "^\${TRANS_PKG}$" ja_translations.txt; then
        echo "\$TRANS_PKG"
        FOUND_COUNT=\$((FOUND_COUNT+1))
    fi
done

echo ""
echo "### Vendor-specific / Misc packages with no translation in 19.07 index ###"
for PKG in "${INSTALLED_PACKAGES[@]}"; do
    TRANS_PKG=""
    if [[ \$PKG == luci-app-* ]]; then TRANS_PKG="luci-i18n-\${PKG#luci-app-}-ja"
    elif [[ \$PKG == luci-mod-* ]]; then TRANS_PKG="luci-i18n-\${PKG#luci-mod-}-ja"
    elif [[ \$PKG == luci-proto-* ]]; then TRANS_PKG="luci-i18n-\${PKG#luci-proto-}-ja"
    elif [[ \$PKG == luci-base ]]; then TRANS_PKG="luci-i18n-base-ja"
    elif [[ \$PKG == luci-lib-* ]]; then TRANS_PKG="luci-i18n-\${PKG#luci-lib-}-ja"
    elif [[ \$PKG == luci-theme-* ]]; then TRANS_PKG="luci-i18n-\${PKG#luci-theme-}-ja"
    else TRANS_PKG="luci-i18n-\${PKG#luci-}-ja"
    fi

    if ! grep -q "^\${TRANS_PKG}$" ja_translations.txt; then
        echo "\$PKG"
    fi
done
