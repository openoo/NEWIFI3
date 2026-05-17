#!/bin/bash

# 替换上游 Golang 组件，提升部分 Go 软件包的编译兼容性
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# 按官方推荐方式引入 Passwall 相关软件包和 LuCI 应用
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci

# 引入 luci-theme-argon 主题及其配置插件
rm -rf package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
rm -rf package/luci-app-argon-config
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 修改默认 LAN 地址，并确保系统启动时运行 usbmuxd
sed -i 's/192.168.1.1/192.168.123.1/g' package/base-files/files/bin/config_generate
sed -i '/exit 0/i usbmuxd' package/base-files/files/etc/rc.local

# 如果存在 autocore 页面，则把时间显示改为完整格式
autocore_index_files=$(find ./package/*/autocore/files/ -type f -name "index.htm" 2>/dev/null)
if [ -n "$autocore_index_files" ]; then
  sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S %A")/g' $autocore_index_files
fi
