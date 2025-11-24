# OpenWrt X86-64 云编译项目

## 固件来源：

- **LEDE源码**：[源码](https://github.com/coolsnowwolf/lede)
- **P3TERX 云编译脚本**：[P3TERX 云编译脚本](https://github.com/P3TERX/Actions-OpenWrt)

## 插件来源：

- **LuCI 主题**：[luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon.git)
- **TurboACC 加速**：[TurboACC](https://github.com/chenmozhijin/turboacc) - 包含 Shortcut-FE、nft-fullcone 等加速组件
- **OpenClash**：[OpenClash](https://github.com/vernesong/OpenClash)

由衷感谢所有为 OpenWrt 无私奉献的开发者们。

## 自定义源

#### 自定义源要放在feeds.conf.default文件最顶部
#### 自定义源要放在feeds.conf.default文件最顶部
#### 自定义源要放在feeds.conf.default文件最顶部

## 固件说明：

基于 **LEDE源码**编译，内核版本支持：
- **5.15** - 稳定版本（基于 master 分支）
- **6.6** - 最新版本（基于 master 分支）

### 特性：
- ✅ 基于 LEDE源码（包含丰富的中文插件和优化）
- ✅ 支持 IPv6
- ✅ 集成 TurboACC 网络加速（Flow Offload + Shortcut-FE）
- ✅ 集成 nft-fullcone NAT 加速
- ✅ 包含常用第三方插件（OpenClash、iStore 等）
- ✅ 软件包可用空间约 800MB+
- ✅ 自动检查源码更新并触发编译
- ✅ 默认时区：Asia/Shanghai (CST-8)

> `管理ip：192.168.99.1 密码：为空`

### 固件分区默认256M+2048mb,分区一致可直接web升级，否则请使用DD写盘或重新写盘，首次刷入不建议保留配置，以免发生BUG。

### esxi构架中安装的全部建议重新写入，不建议在线升级
