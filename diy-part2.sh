#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# 设置错误时退出（但允许某些命令失败）
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

# 安全执行 sed 命令
safe_sed() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local desc="$4"
    
    if [ -f "$file" ]; then
        if sed -i "$pattern" "$file" 2>/dev/null; then
            log_info "$desc"
        else
            log_warn "$desc 失败，文件可能不存在或格式不匹配: $file"
        fi
    else
        log_warn "文件不存在，跳过: $file"
    fi
}

log_info "开始执行 DIY 脚本 part 2..."

# 修改默认IP
log_info "修改默认IP为 192.168.99.1..."
safe_sed "package/base-files/files/bin/config_generate" \
    's/192.168.1.1/192.168.99.1/g' \
    "" \
    "默认IP已修改为 192.168.99.1"

# 路由器设置密码为空
log_info "设置默认密码为空..."
safe_sed "package/lean/default-settings/files/zzz-default-settings" \
    's@.*CYXluq4wUazHjmCDBCqXF*@#&@g' \
    "" \
    "默认密码已设置为空"

# 修改主机名字
log_info "设置主机名为 OpenWrt..."
safe_sed "package/lean/default-settings/files/zzz-default-settings" \
    '/uci commit system/i\uci set system.@system[0].hostname='\''OpenWrt'\''' \
    "" \
    "主机名已设置为 OpenWrt"

# 内核版本号里显示构建信息
log_info "添加构建信息到版本号..."
BUILD_DATE=$(TZ=UTC-8 date "+%Y.%m.%d")
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    sed -i "s/OpenWrt /Child build ${BUILD_DATE} @ OpenWrt /g" package/lean/default-settings/files/zzz-default-settings && \
    log_info "构建信息已添加: Child build ${BUILD_DATE}" || \
    log_warn "添加构建信息失败"
fi

# 修正连接数（优化：检查是否已存在）
log_info "优化连接数设置..."
if [ -f "package/base-files/files/etc/sysctl.conf" ]; then
    if ! grep -q "net.netfilter.nf_conntrack_max=165535" package/base-files/files/etc/sysctl.conf; then
        sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf
        log_info "连接数已优化为 165535"
    else
        log_warn "连接数设置已存在，跳过"
    fi
else
    log_warn "sysctl.conf 文件不存在，跳过连接数优化"
fi

# 更换lede源码中自带argon主题
log_info "配置 Argon 主题..."
if [ -f "./feeds/luci/collections/luci/Makefile" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' ./feeds/luci/collections/luci/Makefile
    log_info "默认主题已切换为 Argon"
else
    log_warn "luci Makefile 不存在，跳过主题切换"
fi

# 清理不需要的主题（如果存在）
if [ -d "./feeds/luci/luci-theme-argon" ]; then
    rm -rf ./feeds/luci/luci-theme-argon
    log_info "已删除 feeds 中的 luci-theme-argon"
fi

if [ -d "./feeds/luci-theme-neobird" ]; then
    rm -rf ./feeds/luci-theme-neobird
    log_info "已删除 feeds 中的 luci-theme-neobird"
fi

# 系统优化：添加更多性能优化配置
log_info "添加系统性能优化..."

# 优化 TCP 参数
if [ -f "package/base-files/files/etc/sysctl.conf" ]; then
    # 检查并添加 TCP 优化参数
    if ! grep -q "net.core.rmem_max" package/base-files/files/etc/sysctl.conf; then
        cat >> package/base-files/files/etc/sysctl.conf << 'EOF'

# TCP 性能优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fastopen = 3
EOF
        log_info "TCP 性能优化参数已添加"
    fi
fi

# 优化文件系统
log_info "优化文件系统配置..."
if [ -f "package/base-files/files/etc/sysctl.conf" ]; then
    if ! grep -q "vm.swappiness" package/base-files/files/etc/sysctl.conf; then
        echo "vm.swappiness = 10" >> package/base-files/files/etc/sysctl.conf
        log_info "已优化 swap 使用策略"
    fi
fi

# LuCI 插件配置说明
# 所有 LuCI 插件已在 .config 文件中配置，编译系统会自动处理依赖和安装
# 无需在此处手动安装，只需确保 feed 源已正确配置（在 diy-part1.sh 中完成）

log_info "DIY 脚本 part 2 执行完成！"

# ============================================================
# 可选配置（按需取消注释使用）
# ============================================================

# 删除自带的adguardhome
# rm -rf ./feeds/packages/net/adguardhome
# rm -rf ./package/feeds/kenzo/luci-app-adguardhome

# 禁止Turbo ACC 网络加速修改net.bridge.bridge-nf-call-iptables的值为1
# (修改为1后旁路由需开启ip动态伪装，影响下行带宽)
# sed -i '/exit 0/i sed -i "s/\\[ -d \\/sys\\/kernel\\/debug\\/ecm\\/ecm_nss_ipv4 \\] \\&\\& return 0/\\[ -d \\/sys\\/kernel\\/debug\\/ecm\\/ecm_nss_ipv4 \\] \\&\\& return 1/g" /etc/init.d/qca-nss-ecm' package/lean/default-settings/files/zzz-default-settings
# sed -i '/exit 0/i sed -i "s/\\[ -d \\/sys\\/kernel\\/debug\\/ecm\\/ecm_nss_ipv4 \\] \\&\\& sysctl -w dev.nss.general.redirect=1/\\#[ -d \\/sys\\/kernel\\/debug\\/ecm\\/ecm_nss_ipv4 \\] \\&\\& sysctl -w dev.nss.general.redirect=1/g" /etc/init.d/qca-nss-ecm' package/lean/default-settings/files/zzz-default-settings
# sed -i '/exit 0/i /etc/init.d/qca-nss-ecm disable' package/lean/default-settings/files/zzz-default-settings

# 添加指定 adguardhome
# svn co https://github.com/kiddin9/openwrt-packages/trunk/adguardhome feeds/packages/net/adguardhome
# svn co https://github.com/kiddin9/openwrt-packages/trunk/luci-app-adguardhome package/feeds/kenzo/luci-app-adguardhome



