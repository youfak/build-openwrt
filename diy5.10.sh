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
    sed -i 's/KERNEL_TESTING_PATCHVER:=\([0-9]\+\)\.\([0-9]\+\)/KERNEL_TESTING_PATCHVER:=5.10/g' ./target/linux/x86/Makefile
    log_info "内核版本已切换为 5.10"
else
    log_warn "未找到 Makefile，跳过内核版本设置"
fi


# 下载 OpenClash
log_info "下载 OpenClash..."
if [ -d "package/luci-app-openclash" ]; then
    log_warn "OpenClash 目录已存在，跳过下载"
else
    mkdir -p package/luci-app-openclash
    cd package/luci-app-openclash
    git config --global advice.defaultBranchName false 2>/dev/null || true
    git init || { log_error "Git 初始化失败"; cd -; exit 1; }
    git remote add -f origin https://github.com/vernesong/OpenClash.git || { log_error "添加远程仓库失败"; cd -; rm -rf package/luci-app-openclash; exit 1; }
    git config core.sparsecheckout true
    echo "luci-app-openclash" >> .git/info/sparse-checkout
    git pull --depth 1 origin master || { log_error "OpenClash 下载失败"; cd -; rm -rf package/luci-app-openclash; exit 1; }
    mv luci-app-openclash/* . 2>/dev/null || true
    mv luci-app-openclash/.* . 2>/dev/null || true
    rmdir luci-app-openclash 2>/dev/null || true
    rm -rf .git .gitignore
    log_info "OpenClash 下载完成"
    cd -
fi

# 配置 feeds
log_info "配置 feed 源..."
if check_file feeds.conf.default; then
    add_feed() {
        local name="$1"
        local url="$2"
        if ! grep -q "$url" feeds.conf.default; then
            sed -i "1i src-git $name $url" feeds.conf.default
            log_info "已将自定义 feed 插入顶部: $name"
        else
            log_warn "feed 已存在: $name"
        fi
    }

    # 第三方源
    add_feed "kenzo" "https://github.com/kenzok8/openwrt-packages"
    add_feed "small" "https://github.com/kenzok8/small"
else
    log_error "feeds.conf.default 文件不存在"
    exit 1
fi

log_info "Feed 源配置完成"

log_info "下载自定义主题..."
if [ -d "package/luci-theme-argon" ]; then
    log_warn "自定义主题目录已存在，跳过下载"
else
    git clone https://github.com/jerrykuku/luci-theme-argon.git  package/luci-theme-argon
    log_info "自定义主题下载完成"
fi

log_info "DIY 脚本 part 1 执行完成！"
