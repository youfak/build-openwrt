#!/bin/bash
#============================================================
# OpenWrt 一键编译脚本
# 支持内核 5.4 / 5.15 / 6.1 自动切换
#============================================================

set -e

# 内核版本选择（默认 5.15）
KERNEL_VER="${1:-5.15}"

echo -e "\n============================="
echo "  🚀 OpenWrt 一键编译脚本"
echo "  🌐 内核版本: $KERNEL_VER"
echo "=============================\n"

# 下载 OpenWrt 源码
if [ ! -d "openwrt" ]; then
    git clone https://github.com/openwrt/openwrt --depth 1
fi

cd openwrt

# 执行自定义 DIY1 脚本
echo -e "\n=== 执行 diy-part1.sh ==="
export KERNEL_VER=$KERNEL_VER
bash ../diy-part1.sh

echo -e "\n=== [Feed 更新] ==="
./scripts/feeds update -a

echo -e "\n=== [Feed 安装] ==="
./scripts/feeds install -a

# 是否需要交互 menuconfig？
if [ "$2" != "nomenu" ]; then
    make menuconfig
fi

echo -e "\n=== 开始编译（多线程） ==="
make -j$(nproc) || make -j1 V=s

echo -e "\n🎉 编译完成，固件位于：openwrt/bin/"
