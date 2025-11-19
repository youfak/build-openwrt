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

log_info "开始配置内核版本 5.15..."

# 指定编译版本
if check_file ./target/linux/x86/Makefile; then
    sed -i 's/KERNEL_PATCHVER:=\([0-9]\+\)\.\([0-9]\+\)/KERNEL_PATCHVER:=5.15/g' ./target/linux/x86/Makefile
    log_info "内核版本已切换为 5.15"
else
    log_warn "未找到 Makefile，跳过内核版本设置"
fi

# 使用自定义openclash
log_info "下载 OpenClash..."
if [ -d "package/luci-app-openclash" ]; then
    log_warn "OpenClash 目录已存在，跳过下载"
else
    svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/luci-app-openclash || {
        log_error "OpenClash 下载失败"
        exit 1
    }
    log_info "OpenClash 下载完成"
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
    if ! grep -q "fw876/helloworld" feeds.conf.default; then
        echo 'src-git fw876 https://github.com/fw876/helloworld' >> feeds.conf.default
        log_info "已添加 helloworld feed 源"
    else
        log_warn "helloworld feed 源已存在，跳过"
    fi
else
    log_error "feeds.conf.default 文件不存在"
    exit 1
fi

log_info "Feed 源配置完成"

# 使用自定义主题（已注释，按需启用）
# log_info "下载自定义主题..."
# git clone https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom package/luci-theme-infinityfreedom #该主题有问题，不要使用(不支持商店)
# git clone https://github.com/kenzok78/luci-theme-argonne package/luci-theme-argonne
# git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git  package/luci-theme-argon-18.06
# git clone -b 18.06 https://github.com/garypang13/luci-theme-edge.git package/luci-theme-edge

log_info "DIY 脚本 part 1 执行完成！"
