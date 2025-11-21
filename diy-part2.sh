#!/bin/bash
#============================================================
# DIY script part 2 (After Update feeds)
#============================================================

set -e

# -----------------------------
# 彩色输出
# -----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error(){ echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------
# 安全 sed
# -----------------------------
safe_sed() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if [ -f "$file" ]; then
        if sed -i "$pattern" "$file" 2>/dev/null; then
            log_info "$desc"
        else
            log_warn "执行 sed 失败: $file"
        fi
    else
        log_warn "文件不存在: $file"
    fi
}

log_info "开始执行 DIY 脚本 part 2 ..."

# ============================================================
# 1. 修改默认 LAN IP（如不存在才修改）
# ============================================================
TARGET_IP="192.168.99.1"
FILE_IP="package/base-files/files/bin/config_generate"

if [ -f "$FILE_IP" ]; then
    if grep -q "192.168.1.1" "$FILE_IP"; then
        sed -i "s/192.168.1.1/$TARGET_IP/g" "$FILE_IP"
        log_info "默认 LAN IP 修改为：$TARGET_IP"
    else
        log_warn "默认 IP 已经被修改过，跳过"
    fi
else
    log_warn "未找到 config_generate，跳过 IP 修改"
fi

# ============================================================
# 2. 默认密码为空
# ============================================================
PASS_FILE="package/lean/default-settings/files/zzz-default-settings"

if [ -f "$PASS_FILE" ]; then
    sed -i "s@.*CYXluq4wUazHjmCDBCqXF*@#&@" "$PASS_FILE"
    log_info "默认密码已设置为空"
else
    log_warn "找不到默认设置文件，跳过密码设置"
fi

# ============================================================
# 3. 修改主机名
# ============================================================
if [ -f "$PASS_FILE" ]; then
    if ! grep -q "uci set system.@system\[0\].hostname='OpenWrt'" "$PASS_FILE"; then
        sed -i "/uci commit system/i\uci set system.@system[0].hostname='OpenWrt'" "$PASS_FILE"
        log_info "主机名已设置为 OpenWrt"
    else
        log_warn "主机名已存在配置，跳过"
    fi
fi

# ============================================================
# 4. Kernel Version 显示构建日期
# ============================================================
BUILD_DATE=$(TZ=UTC-8 date "+%Y.%m.%d")

if [ -f "$PASS_FILE" ]; then
    sed -i "s/OpenWrt /Child build ${BUILD_DATE} @ OpenWrt /g" "$PASS_FILE" \
        && log_info "版本号构建信息已更新" \
        || log_warn "版本号替换失败"
fi

# ============================================================
# 5. 优化连接数
# ============================================================
SYSCTL_FILE="package/base-files/files/etc/sysctl.conf"

if [ -f "$SYSCTL_FILE" ]; then
    if ! grep -q "nf_conntrack_max" "$SYSCTL_FILE"; then
        echo "net.netfilter.nf_conntrack_max=165535" >> "$SYSCTL_FILE"
        log_info "连接数优化完成: 165535"
    else
        log_warn "连接数已存在，跳过"
    fi
fi

# ============================================================
# 6. 设置 Argon 为默认主题
# ============================================================
LUCIMK="./feeds/luci/collections/luci/Makefile"

if [ -f "$LUCIMK" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' "$LUCIMK"
    log_info "默认主题已切换为 Argon"
else
    log_warn "未找到 luci Makefile，跳过主题设置"
fi

# ============================================================
# 7. 系统性能优化（TCP / FS）
# ============================================================
if [ -f "$SYSCTL_FILE" ]; then
    if ! grep -q "tcp_fastopen" "$SYSCTL_FILE"; then
        cat >> "$SYSCTL_FILE" << 'EOF'

# ===== TCP 优化 =====
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fastopen = 3

EOF
        log_info "TCP 优化参数已添加"
    fi

    if ! grep -q "vm.swappiness" "$SYSCTL_FILE"; then
        echo "vm.swappiness = 10" >> "$SYSCTL_FILE"
        log_info "添加文件系统优化: vm.swappiness=10"
    fi
fi

# ============================================================
# 完成
# ============================================================
log_info "DIY 脚本 part 2 执行完成！"
exit 0

# ============================================================
# 可选扩展（保留）
# ============================================================
# 删除自带 adguardhome
# rm -rf ./feeds/packages/net/adguardhome
# rm -rf ./package/feeds/kenzo/luci-app-adguardhome

# 添加指定 adguardhome
# svn co https://github.com/kiddin9/openwrt-packages/trunk/adguardhome feeds/packages/net/adguardhome
# svn co https://github.com/kiddin9/openwrt-packages/trunk/luci-app-adguardhome package/feeds/kenzo/luci-app-adguardhome

