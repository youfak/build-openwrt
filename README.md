# OpenWrt 23.05 X86-64 云编译项目

## 固件来源：

- **KEDE源码**：[源码]( https://github.com/coolsnowwolf/lede)
- **P3TERX 云编译脚本**：[https://github.com/P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)

## 插件来源：

- **LuCI 主题**：[luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon.git)
- **第三方插件源**：[kenzok8/openwrt-packages](https://github.com/kenzok8/openwrt-packages)

由衷感谢所有为 OpenWrt 无私奉献的开发者们。

## 自定义源

#### 自定义源要放在feeds.conf.default文件最顶部
#### 自定义源要放在feeds.conf.default文件最顶部
#### 自定义源要放在feeds.conf.default文件最顶部

## 固件说明：

基于 **OpenWrt 23.05** 官方稳定版本编译，内核版本支持：
- **5.10** - 稳定版本
- **5.15** - 稳定版本  
- **6.1/6.6** - 较新版本

### 特性：
- ✅ 基于LEDE版本
- ✅ 支持 IPv6
- ✅ 包含常用第三方插件（通过 feeds 添加）
- ✅ 软件包可用空间约 800MB+
- ✅ 自动检查源码更新并触发编译

> `管理ip：192.168.99.1 密码：为空`

### 固件分区默认256M+2048mb,分区一致可直接web升级，否则请使用DD写盘或重新写盘，首次刷入不建议保留配置，以免发生BUG。

### esxi构架中安装的全部建议重新写入，不建议在线升级

![image](https://user-images.githubusercontent.com/27138744/218228804-a7a128ce-671a-4abd-a97e-8a33b90fd5bd.png)
![image](https://user-images.githubusercontent.com/27138744/209439304-c3004851-c360-4695-a5c6-930618902122.png)
![image](https://user-images.githubusercontent.com/27138744/209439320-04f2a7f3-d084-4c98-97b5-518ae6aa41ca.png)
## 5.10只有如下插件
![image](https://user-images.githubusercontent.com/27138744/221386973-56c176f5-6672-4dca-88b4-e9de21627a36.png)

# OpenWrt 编译环境设置指南

## 系统要求

首先装好 Linux 系统，推荐 **Debian** 或 **Ubuntu LTS 22/24**

## 安装编译依赖

### 更新系统并安装依赖

```bash
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
bzip2 ccache clang cmake cpio curl device-tree-compiler flex gawk gcc-multilib g++-multilib gettext \
genisoimage git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev \
libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev \
libreadline-dev libssl-dev libtool llvm lrzsz libnsl-dev ninja-build p7zip p7zip-full patch pkgconf \
python3 python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion \
swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
```

## 下载源代码，更新 feeds 并选择配置

### 1. 克隆 OpenWrt 源码

```bash
git clone https://github.com/coolsnowwolf/lede
cd lede
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
```

### 2. 更新 feeds

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

### 3. 配置编译选项

```bash
make menuconfig
```

或者使用现有的配置文件：

```bash
cp ../x64.config .config
make defconfig
```

### 4. 开始编译

```bash
make -j$(nproc) V=s
```

## 依赖包说明

### 核心编译工具
- `build-essential` - 基本编译工具集
- `gcc-multilib` / `g++-multilib` - 多架构编译支持
- `clang` / `llvm` - 可选编译器
- `ccache` - 编译缓存加速

### 构建工具
- `cmake` - CMake 构建系统
- `ninja-build` - Ninja 构建系统
- `scons` - SCons 构建工具
- `autoconf` / `automake` - 自动配置工具

### 开发库
- `libssl-dev` - OpenSSL 开发库
- `libncurses5-dev` / `libncursesw5-dev` - 终端界面库
- `libpython3-dev` - Python 3 开发库
- `libglib2.0-dev` - GLib 库
- `libelf-dev` - ELF 文件处理库
- `zlib1g-dev` - 压缩库

### 工具和实用程序
- `git` - 版本控制
- `curl` / `wget` - 下载工具
- `rsync` - 文件同步
- `subversion` - SVN 版本控制
- `p7zip` / `p7zip-full` - 7z 压缩工具
- `squashfs-tools` - SquashFS 文件系统工具
- `qemu-utils` - QEMU 虚拟机工具

### 文档和格式化工具
- `asciidoc` - 文档生成
- `texinfo` - Texinfo 文档系统
- `xmlto` - XML 转换工具

## 常见问题

### 1. 内存不足

如果编译时内存不足，可以减少并行编译线程数：

```bash
make -j2 V=s  # 使用 2 个线程
```

### 2. 磁盘空间不足

编译 OpenWrt 需要至少 **20GB** 可用磁盘空间，建议预留 **30GB+**

### 3. 网络问题

如果下载源码或依赖包时遇到网络问题，可以：

- 使用代理
- 使用镜像源
- 手动下载并放置到 `dl/` 目录

### 4. 依赖缺失

如果编译过程中提示缺少依赖，可以：

```bash
# 查找缺失的包
apt search <package-name>

# 安装缺失的包
sudo apt install <package-name>
```

## 快速开始脚本

也可以使用项目中的 `build.sh` 脚本进行一键编译：

```bash
./build.sh 5.15    # 编译内核 5.15 版本
./build.sh 6.1     # 编译内核 6.1 版本
./build.sh 5.15 nomenu  # 不进入 menuconfig，直接编译
```

## 参考资源

- [OpenWrt 官方文档](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem)
- [OpenWrt 官方源码](https://github.com/openwrt/openwrt)
- [OpenWrt 23.05 发布说明](https://openwrt.org/releases/23.05/start)
- [P3TERX Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)
- [第三方插件源 (kenzok8)](https://github.com/kenzok8/openwrt-packages)





