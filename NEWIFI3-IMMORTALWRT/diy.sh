#!/bin/bash

rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci

rm -rf package/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora package/luci-theme-aurora
rm -rf package/luci-app-aurora-config
git clone --depth=1 https://github.com/eamonxg/luci-app-aurora-config package/luci-app-aurora-config

sed -i 's/192.168.1.1/192.168.123.1/g' package/base-files/files/bin/config_generate
sed -i '/exit 0/i usbmuxd' package/base-files/files/etc/rc.local

autocore_index_files=$(find ./package/*/autocore/files/ -type f -name "index.htm" 2>/dev/null)
if [ -n "$autocore_index_files" ]; then
  sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S %A")/g' $autocore_index_files
fi
