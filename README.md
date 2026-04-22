# NEWIFI3 ImmortalWrt 24.10 固件构建项目

这是一个面向 `NEWIFI3 / Newifi-D2` 的 `ImmortalWrt 24.10` 自定义固件构建仓库。

项目目标很明确：

- 以 `ImmortalWrt 24.10` 为基础源码
- 面向 `ramips/mt7621` 平台下的 `d-team_newifi-d2`
- 保留并集成当前项目所需的核心功能
- 使用 `GitHub Actions` 自动完成在线编译和发布

这不是一个完整的 ImmortalWrt 源码仓库，而是一个“自定义构建层”仓库。仓库中只保存构建工作流、自定义配置、覆盖文件和编译前脚本；真正的上游源码会在 CI 运行时从官方仓库拉取。

## 项目定位

这个项目主要用于构建一套适合 NEWIFI3 使用的 ImmortalWrt 固件，并在尽量少改动项目结构的前提下，保留以下功能：

- 默认管理地址改为 `192.168.123.1`
- 默认时区设置为 `Asia/Shanghai`
- 自动启用 USB 共享网络
- 支持安卓手机、苹果手机、随身 WiFi 等 USB 网络接入方式
- 集成 `Passwall`
- 集成 `Turbo ACC`
- 使用 `Aurora` LuCI 主题，并启用其配置插件
- 保留 NEWIFI3 设备所需的无线驱动

## 仓库结构

当前仓库结构如下：

```text
.
├─ .github/
│  └─ workflows/
│     └─ build-NEWIFI3-immortalwrt.yml
├─ NEWIFI3-IMMORTALWRT/
│  ├─ .config
│  ├─ diy.sh
│  └─ files/
│     └─ etc/
│        ├─ config/
│        │  └─ system
│        └─ uci-defaults/
│           ├─ 99-newifi3-luci-theme
│           └─ 99-newifi3-usb-tether
└─ README.md
```

各文件职责如下：

- `.github/workflows/build-NEWIFI3-immortalwrt.yml`
  负责 GitHub Actions 自动构建、缓存、打包和发布。

- `NEWIFI3-IMMORTALWRT/.config`
  负责定义目标平台、设备、软件包选择以及部分显式关闭项。

- `NEWIFI3-IMMORTALWRT/diy.sh`
  负责在上游源码拉取并安装 feeds 后，对源码树进行额外定制，例如拉取 Passwall、Aurora 主题、替换 Golang 组件、修改默认 IP 等。

- `NEWIFI3-IMMORTALWRT/files/etc/config/system`
  负责写入系统默认配置，例如主机名、时区、NTP 服务器和 LED 行为。

- `NEWIFI3-IMMORTALWRT/files/etc/uci-defaults/99-newifi3-usb-tether`
  负责在系统首次启动时自动创建 USB 网络接口并加入 WAN 防火墙区域。

- `NEWIFI3-IMMORTALWRT/files/etc/uci-defaults/99-newifi3-luci-theme`
  负责在系统首次启动时将 LuCI 默认主题切换为 `Aurora`。

## 上游源码与构建方式

项目当前使用的上游源码为：

- 源码仓库：`https://github.com/immortalwrt/immortalwrt`
- 分支：`openwrt-24.10`

GitHub Actions 工作流会执行以下大致流程：

1. 检出当前仓库
2. 安装编译依赖
3. 克隆 `ImmortalWrt 24.10` 源码到 `openwrt/`
4. 更新并安装 feeds
5. 额外拉取 `Turbo ACC`
6. 删除与 Turbo ACC 冲突的 `fullconenat-nft`
7. 拷贝本仓库中的 `files`、`.config`
8. 执行 `diy.sh`
9. `make defconfig`
10. 下载源码包
11. 编译固件
12. 收集 `newifi-d2` 产物
13. 发布到 GitHub Release

## 当前集成的主要功能

### 1. 设备目标

当前固件构建目标为：

- 平台：`ramips`
- 子平台：`mt7621`
- 设备：`d-team_newifi-d2`

也就是 NEWIFI3 / Newifi-D2。

### 2. 默认网络设置

项目中已经将默认 LAN 地址修改为：

```text
192.168.123.1
```

这个修改通过两部分实现：

- 在 `diy.sh` 中修改上游默认生成逻辑
- 在 USB 共享网络初始化脚本中再次明确写入 LAN 地址

这样可以尽量避免首次启动时仍回落到 `192.168.1.1`。

### 3. USB 共享网络

项目针对 USB 共享网络做了专门处理，适合以下使用场景：

- 安卓手机 USB 共享
- 苹果手机 USB 共享
- 随身 WiFi / USB 网卡方式联网

当前启用了相关 USB 网络驱动和用户态组件，例如：

- `kmod-usb-core`
- `kmod-usb2`
- `kmod-usb3`
- `kmod-usb-net`
- `kmod-usb-net-rndis`
- `kmod-usb-net-ipheth`
- `usbmuxd`
- `libimobiledevice`

系统首次启动时，`99-newifi3-usb-tether` 会自动：

- 创建 `usbv4` 接口
- 创建 `usbv6` 接口
- 将接口绑定到 `usb0`
- 把它们加入防火墙 `wan` 区域

这样做的目的是尽可能让 USB 共享网络开箱即用。

### 4. 无线功能

为了保证 NEWIFI3 在 `ImmortalWrt 24.10` 下无线功能稳定，项目显式保留了与设备硬件对应的无线驱动栈：

- `kmod-cfg80211`
- `kmod-mac80211`
- `kmod-mt76-core`
- `kmod-mt7603`
- `kmod-mt76x02-common`
- `kmod-mt76x2`
- `kmod-mt76x2-common`
- `iw`
- `iwinfo`
- `wpad-openssl`

其中：

- `mt7603` 对应 2.4G
- `mt76x2` 对应 5G

之所以显式写出这些项，而不是完全依赖默认选择，是为了降低跨发行版迁移时由于依赖变化造成无线异常的风险。

### 5. Passwall

项目当前启用了：

- `luci-app-passwall`

Passwall 的源码接入方式参考其官方 README 的编译方法，并在 `diy.sh` 中完成以下操作：

- 删除与 Passwall 相关的上游冲突包
- 克隆 `openwrt-passwall-packages`
- 克隆 `openwrt-passwall`

同时项目保留了对 `feeds/packages/lang/golang` 的替换：

- 删除上游默认 `golang`
- 使用 `sbwml/packages_lang_golang` 的 `26.x` 分支替换

这样做的目的是提升部分 Go 语言软件包在当前构建环境下的兼容性。

### 6. Turbo ACC

项目已集成 `Turbo ACC`，方式参考你提供的可编译成功示例。

在 GitHub Actions 构建过程中会执行：

```bash
curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
rm -rf package/network/utils/fullconenat-nft
```

删除 `fullconenat-nft` 的原因是：

- `ImmortalWrt` 自带的某些 `nft fullcone` 组件
- 与 `Turbo ACC` 引入的组件存在冲突

### 7. Aurora 主题

项目当前不再使用旧的 `design` 主题，而是改为：

- `luci-theme-aurora`
- `luci-app-aurora-config`

这两个包会在 `diy.sh` 中分别从官方仓库拉取：

- `https://github.com/eamonxg/luci-theme-aurora`
- `https://github.com/eamonxg/luci-app-aurora-config`

并在系统首次启动时通过 `uci-defaults` 脚本将 LuCI 默认主题切换为：

```text
/luci-static/aurora
```

### 8. 中文与本地化

项目当前保留中文环境相关设置，例如：

- 系统时区：`Asia/Shanghai`
- NTP 服务器使用国内可用节点
- LuCI 使用简体中文

## 为什么不直接提交完整 ImmortalWrt 源码

因为这个项目的重点不是维护整个上游源码，而是维护“我的设备需要什么定制”。

这种做法的优点是：

- 仓库更小
- 更容易看清项目自身改了什么
- 上游更新时更容易切换分支
- CI 中每次都从干净源码开始，问题更容易定位

缺点也存在：

- 如果上游包名或依赖关系变化，`.config` 或 `diy.sh` 可能需要同步调整
- 第三方包和主题的兼容性需要跟着上游变化一起维护

## 当前工作流文件说明

主工作流文件：

- `.github/workflows/build-NEWIFI3-immortalwrt.yml`

它的主要特点有：

- 使用 `workflow_dispatch` 手动触发
- 启用了 `ccache` 与下载缓存
- 编译成功后自动上传到 GitHub Release
- 自动清理旧版本 Release，只保留最近若干版本

发布信息中会包含：

- 设备型号
- 默认 IP
- 默认账户信息
- USB 共享网络说明

## 使用方式

### 方式一：直接在 GitHub Actions 中构建

1. Fork 本仓库
2. 打开 GitHub Actions
3. 手动运行 `Build ImmortalWrt for NEWIFI3`
4. 等待构建完成
5. 到 Release 页面下载固件

### 方式二：本地编译

如果你希望本地编译，可以参考工作流中的流程：

1. 克隆本仓库
2. 手动克隆 `ImmortalWrt 24.10` 源码
3. 更新并安装 feeds
4. 拷贝 `NEWIFI3-IMMORTALWRT/files`
5. 拷贝 `NEWIFI3-IMMORTALWRT/.config`
6. 执行 `NEWIFI3-IMMORTALWRT/diy.sh`
7. 运行 `make defconfig`
8. 运行 `make download`
9. 运行 `make -j$(nproc)`

## 输出产物

编译完成后，工作流会从如下路径收集 NEWIFI3 固件：

```text
openwrt/bin/targets/*/*/*newifi-d2*bin
```

通常你最终使用的是：

- `sysupgrade.bin`

如果是首次从其他固件迁移，请务必根据自己的刷机方式判断是否需要先刷工厂镜像或 Breed/uboot 兼容镜像。

## 注意事项

### 1. 这不是官方原版固件

虽然上游使用的是 `ImmortalWrt 24.10`，但本项目额外引入了：

- Passwall
- Turbo ACC
- Aurora 主题
- 第三方 Golang 替换
- USB 共享网络初始化脚本

因此它属于“带自定义增强”的个人构建方案。

### 2. 第三方包可能随上游变化失效

以下部分都不是单纯依赖上游默认包：

- Passwall
- Turbo ACC
- Aurora 主题与配置插件
- Golang 替换

如果未来上游分支更新导致某个包无法编译，需要优先检查：

- 包仓库是否变更
- 分支是否兼容 `openwrt-24.10`
- 依赖包是否改名

### 3. `.config` 已显式关闭部分不需要的包

例如项目中已经明确关闭了：

- `vlmcsd`
- `luci-app-vlmcsd`
- `luci-theme-bootstrap`

这样做是为了避免某些上游默认包在 `make defconfig` 时被自动补回。

## 后续维护建议

如果你后续继续维护这个项目，建议重点关注以下几类变动：

- `ImmortalWrt openwrt-24.10` 上游是否调整包名
- `Passwall` 官方编译方式是否有变化
- `Turbo ACC` 脚本是否更新
- `Aurora` 主题与配置插件是否发生接口变化
- `NEWIFI3` 相关无线驱动是否有拆包或合包

## 致谢

本项目基于以下开源项目与社区成果构建：

- `ImmortalWrt`
- `OpenWrt-Passwall`
- `sbwml/packages_lang_golang`
- `chenmozhijin/turboacc`
- `eamonxg/luci-theme-aurora`
- `eamonxg/luci-app-aurora-config`

感谢这些项目作者和维护者的持续工作。
