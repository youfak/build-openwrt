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
#

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

log_info "开始配置内核版本 6.6..."

# 切换固件版本
if check_file ./target/linux/x86/Makefile; then
    sed -i 's/KERNEL_PATCHVER:=\([0-9]\+\)\.\([0-9]\+\)/KERNEL_PATCHVER:=6.6/g' ./target/linux/x86/Makefile
    sed -i 's/KERNEL_TESTING_PATCHVER:=\([0-9]\+\)\.\([0-9]\+\)/KERNEL_TESTING_PATCHVER:=6.6/g' ./target/linux/x86/Makefile
    log_info "内核版本已切换为 6.6"
    
    # 添加默认包（网卡驱动、存储设备、工具等）
    if grep -q "DEFAULT_PACKAGES +=" ./target/linux/x86/Makefile; then
        sed -i 's/DEFAULT_PACKAGES +=/DEFAULT_PACKAGES += autocore automount base-files block-mount ca-bundle default-settings-chn dnsmasq-full dnsmasq_full_dhcpv6 dropbear fdisk firewall4 fstools grub2-bios-setup i915-firmware-dmc kmod-8139cp kmod-8139too kmod-button-hotplug kmod-e1000e kmod-fs-f2fs kmod-i40e kmod-igb kmod-igbvf kmod-igc kmod-ixgbe kmod-ixgbevf kmod-mmc kmod-nf-nathelper kmod-nf-nathelper-extra kmod-nft-offload kmod-pcnet32 kmod-r8101 kmod-r8125 kmod-r8126 kmod-r8168 kmod-sdhci kmod-tulip kmod-usb-hid kmod-usb-net kmod-usb-net-asix kmod-usb-net-asix-ax88179 kmod-usb-net-rtl8150 kmod-atlantic kmod-vmxnet3 kmod-iavf kmod-bnx2x kmod-drm-amdgpu kmod-mlx4-core kmod-mlx5-core lsblk kmod-phy-broadcom usbutils pciutils lm-sensors-detect kmod-ip6tables kmod-nf-ipt6 kmod-nf-nat6 kmod-iptunnel6 kmod-sit kmof-usb-storage open-vm-tools open-vm-tools-fuse/' ./target/linux/x86/Makefile
        log_info "已添加默认包（系统基础、网卡驱动、存储设备、工具、IPv6支持、VMware工具等）"
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

# 使用自定义openclash
log_info "下载 OpenClash..."
if [ -d "package/luci-app-openclash" ]; then
    log_warn "OpenClash 目录已存在，跳过下载"
else
    # 使用 git sparse checkout 下载 OpenClash（官方推荐方法）
    mkdir -p package/luci-app-openclash
    cd package/luci-app-openclash
    git init || {
        log_error "Git 初始化失败"
        cd -
        exit 1
    }
    git remote add -f origin https://github.com/vernesong/OpenClash.git || {
        log_error "添加远程仓库失败"
        cd -
        rm -rf package/luci-app-openclash
        exit 1
    }
    git config core.sparsecheckout true
    echo "luci-app-openclash" >> .git/info/sparse-checkout
    git pull --depth 1 origin master || {
        log_error "OpenClash 下载失败"
        cd -
        rm -rf package/luci-app-openclash
        exit 1
    }
    # 移动 luci-app-openclash 目录内容到当前目录（package/luci-app-openclash）
    if [ -d "luci-app-openclash" ]; then
        mv luci-app-openclash/* . 2>/dev/null || true
        mv luci-app-openclash/.* . 2>/dev/null || true
        rmdir luci-app-openclash 2>/dev/null || true
        # 清理 git 相关文件
        rm -rf .git .gitignore
        log_info "OpenClash 下载完成"
    else
        log_error "OpenClash 目录未找到"
        cd -
        rm -rf package/luci-app-openclash
        exit 1
    fi
    cd -
fi

# 配置 feeds
log_info "配置 feed 源..."
if check_file feeds.conf.default; then
    add_feed() {
        local name="$1"
        local url="$2"
        if ! grep -q "$url" feeds.conf.default; then
            echo "src-git $name $url" >> feeds.conf.default
            log_info "已添加 feed 源: $name"
        else
            log_warn "feed 源已存在: $name"
        fi
    }

    # 第三方源
    add_feed "kenzo" "https://github.com/kenzok8/openwrt-packages"
    add_feed "small" "https://github.com/kenzok8/small"

    echo -e "\n=== [3] 删除冲突 luci/mosdns ==="
    rm -rf feeds/luci/applications/luci-app-mosdns 2>/dev/null || true
    echo -e "\n=== [4] 删除重复/冲突网络代理插件 ==="
    rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,sing*,smartdns}
    rm -rf feeds/packages/utils/v2dat
    echo -e "\n=== [5] 替换 Golang → 1.25（支持 sing-box & hysteria2） ==="
    rm -rf feeds/packages/lang/golang
    git clone https://github.com/kenzok8/golang -b 1.25 feeds/packages/lang/golang
else
    log_error "feeds.conf.default 文件不存在"
    exit 1
fi

# 使用自定义主题（已注释，按需启用）
git clone https://github.com/jerrykuku/luci-theme-argon.git  package/luci-theme-argon

log_info "DIY 脚本 part 1 执行完成！"
