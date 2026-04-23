# NEWIFI3 ImmortalWrt 24.10

这是一个用于自动编译 `NEWIFI3 / Newifi-D2` 固件的自定义构建项目。

项目不保存完整 ImmortalWrt 源码，只保存构建配置、自定义脚本和覆盖文件。GitHub Actions 运行时会自动拉取上游源码并完成编译。

## 基本信息

- 上游源码：`https://github.com/immortalwrt/immortalwrt`
- 上游分支：`openwrt-24.10`
- 目标平台：`ramips/mt7621`
- 目标设备：`d-team_newifi-d2`
- 默认地址：`192.168.123.1`
- 默认时区：`Asia/Shanghai`
- 构建方式：GitHub Actions 手动触发

## 目录结构

```text
.
├─ .github/workflows/build-NEWIFI3-immortalwrt.yml
├─ NEWIFI3-IMMORTALWRT/
│  ├─ .config
│  ├─ diy.sh
│  └─ files/
│     └─ etc/
│        ├─ config/system
│        └─ uci-defaults/
│           ├─ 99-newifi3-luci-theme
│           └─ 99-newifi3-usb-tether
└─ README.md
```

## 主要功能

- 使用 `ImmortalWrt 24.10` 构建 NEWIFI3 固件
- 默认 LAN 地址为 `192.168.123.1`
- 自动配置 USB 共享网络
- 支持安卓手机、苹果手机、USB 网卡等 USB 网络接入
- 集成 `Passwall`
- 显式内置 `xray-core`
- 使用 `Aurora` LuCI 主题
- 启用 `luci-app-aurora-config`
- 保留 NEWIFI3 所需的 `mt76` 无线驱动栈
- 显式禁用 `vlmcsd` / `luci-app-vlmcsd`

## 构建流程

工作流文件为：

```text
.github/workflows/build-NEWIFI3-immortalwrt.yml
```

大致流程：

1. 拉取当前仓库
2. 安装编译依赖
3. 克隆 `ImmortalWrt openwrt-24.10`
4. 更新并安装 feeds
5. 拷贝 `.config` 和 `files`
6. 执行 `NEWIFI3-IMMORTALWRT/diy.sh`
7. 执行 `make defconfig`
8. 下载源码包
9. 编译固件
10. 上传固件到 GitHub Release

## 自定义脚本

`NEWIFI3-IMMORTALWRT/diy.sh` 主要做这些事：

- 替换 `feeds/packages/lang/golang`
- 引入 Passwall 官方软件包仓库
- 引入 Aurora 主题和配置插件
- 修改默认 LAN 地址为 `192.168.123.1`
- 在 `rc.local` 中启动 `usbmuxd`
- 如果存在 autocore 页面，则调整时间显示格式

## USB 共享网络

项目通过 `99-newifi3-usb-tether` 在首次启动时自动创建：

- `usbv4`
- `usbv6`

并将它们绑定到 `usb0`，加入防火墙 `wan` 区域。

相关用途：

- 安卓手机 USB 共享网络
- 苹果手机 USB 共享网络
- 部分 USB 网卡或随身 WiFi

## WiFi 配置

NEWIFI3 使用 MT7621 平台，当前显式保留以下无线相关包：

```config
CONFIG_PACKAGE_kmod-cfg80211=y
CONFIG_PACKAGE_kmod-mac80211=y
CONFIG_PACKAGE_kmod-mt76-core=y
CONFIG_PACKAGE_kmod-mt7603=y
CONFIG_PACKAGE_kmod-mt76x02-common=y
CONFIG_PACKAGE_kmod-mt76x2=y
CONFIG_PACKAGE_kmod-mt76x2-common=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y
CONFIG_PACKAGE_wpad-openssl=y
```

其中：

- `mt7603` 用于 2.4G WiFi
- `mt76x2` 用于 5G WiFi
- `wpad-openssl` 用于无线认证与加密

## Passwall 与 Xray

当前配置为：

```config
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_xray-core=y
```

这里显式启用 `xray-core`，目的是确保固件内置 `/usr/bin/xray`，而不是只依赖 Passwall 的组件更新页面。

## 关于 Turbo ACC

当前项目不启用 `luci-app-turboacc`。

相关配置已显式关闭：

```config
CONFIG_PACKAGE_luci-app-turboacc=n
CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_OFFLOADING=n
CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_BBR_CCA=n
CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_NFT_FULLCONE=n
```

原因：

- 当前工作流没有引入 `luci-app-turboacc` 的包源
- 仅在 `.config` 中写 `CONFIG_PACKAGE_luci-app-turboacc=y` 不会生效
- 之前尝试接入外部 `add_turboacc.sh` 会修改内核补丁链
- 该脚本与当前 `ImmortalWrt 24.10 / Linux 6.6.x` 存在补丁冲突，导致内核 headers 阶段编译失败

如果需要加速功能，建议优先使用 ImmortalWrt 原生的防火墙流量分载、FullCone NAT、BBR 等能力，而不是强行接入外部 Turbo ACC 脚本。

## Aurora 主题

项目使用：

- `luci-theme-aurora`
- `luci-app-aurora-config`

并通过 `99-newifi3-luci-theme` 在首次启动时设置默认主题：

```sh
uci -q set luci.main.mediaurlbase='/luci-static/aurora'
uci commit luci
```

## 不需要的组件

项目显式禁用了 KMS 相关组件：

```config
CONFIG_PACKAGE_vlmcsd=n
CONFIG_PACKAGE_luci-app-vlmcsd=n
```

也显式禁用了默认 Bootstrap 主题：

```config
CONFIG_PACKAGE_luci-theme-bootstrap=n
```

## 使用方式

1. 打开 GitHub Actions
2. 选择 `Build ImmortalWrt for NEWIFI3`
3. 点击 `Run workflow`
4. 等待构建完成
5. 在 Release 页面下载固件

## 输出产物

工作流会收集：

```text
openwrt/bin/targets/*/*/*newifi-d2*bin
```

通常使用 `sysupgrade.bin` 进行升级。

首次从其他固件迁移时，请根据自己的刷机环境确认是否需要使用 Breed、uboot 或其他刷机方式。

## 维护提示

后续如果构建失败，优先检查：

- `ImmortalWrt openwrt-24.10` 上游是否更新
- Passwall 编译方式是否变化
- `xray-core` 在 `mipsel_24kc` 下是否仍可构建
- Aurora 主题仓库是否调整结构
- USB 共享网络相关包名是否变化

## 致谢

本项目使用或参考了以下项目：

- `ImmortalWrt`
- `OpenWrt-Passwall`
- `sbwml/packages_lang_golang`
- `eamonxg/luci-theme-aurora`
- `eamonxg/luci-app-aurora-config`
