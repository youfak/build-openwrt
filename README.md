# OpenWrt 23.05 X86-64 云编译项目

## 固件来源：

- **KEDE源码**：[源码]( https://github.com/coolsnowwolf/lede)
- **P3TERX 云编译脚本**：[P3TERX 云编译脚本](https://github.com/P3TERX/Actions-OpenWrt)

## 插件来源：

- **LuCI 主题**：[luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon.git)
- **第三方插件源**：[kenzok8插件源](https://github.com/kenzok8/openwrt-packages)

由衷感谢所有为 OpenWrt 无私奉献的开发者们。

## 自定义源

#### 自定义源要放在feeds.conf.default文件最顶部
#### 自定义源要放在feeds.conf.default文件最顶部
#### 自定义源要放在feeds.conf.default文件最顶部

## 固件说明：

基于 **OpenWrt 23.05** 官方稳定版本编译，内核版本支持：
- **5.10** - 稳定版本
- **5.15** - 稳定版本  
- **6.1** -  稳定版本

### 特性：
- ✅ 基于LEDE版本
- ✅ 支持 IPv6
- ✅ 包含常用第三方插件（通过 feeds 添加）
- ✅ 软件包可用空间约 800MB+
- ✅ 自动检查源码更新并触发编译

> `管理ip：192.168.99.1 密码：为空`

### 固件分区默认256M+2048mb,分区一致可直接web升级，否则请使用DD写盘或重新写盘，首次刷入不建议保留配置，以免发生BUG。

### esxi构架中安装的全部建议重新写入，不建议在线升级
