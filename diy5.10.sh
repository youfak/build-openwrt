#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
# 5.10 完全纯净版 不包含任何插件

# 设置错误时退出
set -e

# 颜色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查文件是否存在
check_file() {
    if [ ! -f "$1" ]; then
        log_error "文件不存在: $1"
        return 1
    fi
    return 0
}

log_info "开始配置内核版本 5.10（纯净版）..."

# 指定编译版本
if check_file ./target/linux/x86/Makefile; then
    sed -i 's/KERNEL_PATCHVER:=\([0-9]\+\)\.\([0-9]\+\)/KERNEL_PATCHVER:=5.10/g' ./target/linux/x86/Makefile
    log_info "内核版本已切换为 5.10"
    
    # 添加默认包（网卡驱动、存储设备、工具等）
    if grep -q "DEFAULT_PACKAGES +=" ./target/linux/x86/Makefile; then
        sed -i 's/DEFAULT_PACKAGES +=/DEFAULT_PACKAGES += kmod-fs-f2fs kmod-mmc kmod-sdhci kmod-usb-hid usbutils pciutils lm-sensors-detect kmod-atlantic kmod-vmxnet3 kmod-igbvf kmod-iavf kmod-bnx2x kmod-pcnet32 kmod-tulip kmod-r8101 kmod-r8125 kmod-r8126 kmod-8139cp kmod-8139too kmod-i40e kmod-drm-amdgpu kmod-mlx4-core kmod-mlx5-core fdisk lsblk kmod-phy-broadcom kmod-ixgbevf kmod-ip6tables kmod-nf-ipt6 kmod-nf-nat6 kmod-iptunnel6 kmod-sit open-vm-tools open-vm-tools-fuse/' ./target/linux/x86/Makefile
        log_info "已添加默认包（网卡驱动、存储设备、工具、IPv6支持、VMware工具等）"
    else
        log_warn "未找到 DEFAULT_PACKAGES 配置，跳过默认包设置"
    fi
else
    log_warn "未找到 Makefile，跳过内核版本设置"
fi

# 修改固件分区大小（256MB -> 1024MB）
if check_file ./target/linux/x86/image/Makefile; then
    sed -i 's/256/1024/g' ./target/linux/x86/image/Makefile
    log_info "固件分区大小已修改为 1024MB"
else
    log_warn "未找到 image/Makefile，跳过分区大小设置"
fi

# 添加 feed 源（优化：检查是否已存在，避免重复添加）
log_info "配置 feed 源..."

if check_file feeds.conf.default; then
    # 检查并添加 kenzo feed
    if ! grep -q "kenzok8/openwrt-packages" feeds.conf.default; then
        sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
        log_info "已添加 kenzo feed 源"
    else
        log_warn "kenzo feed 源已存在，跳过"
    fi
    
    # 检查并添加 small feed
    if ! grep -q "kenzok8/small" feeds.conf.default; then
        sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
        log_info "已添加 small feed 源"
    else
        log_warn "small feed 源已存在，跳过"
    fi
    
    # 检查并添加 helloworld feed
    if ! grep -q "helloworld" feeds.conf.default; then
        sed -i "/helloworld/d" feeds.conf.default
        echo "src-git helloworld https://github.com/fw876/helloworld.git" >> feeds.conf.default
        log_info "已添加 helloworld feed 源"
    else
        log_warn "helloworld feed 源已存在，跳过"
    fi
else
    log_error "feeds.conf.default 文件不存在"
    exit 1
fi

log_info "Feed 源配置完成"

log_info "DIY 脚本 part 1 执行完成！"
