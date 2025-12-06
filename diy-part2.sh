#!/usr/bin/env bash
#============================================================
# DIY script part 2 (After Update feeds) - Optimized Edition
#============================================================

set -euo pipefail

# -----------------------------
# 可配置项
# -----------------------------
TARGET_HOSTNAME=${TARGET_HOSTNAME:-"YOUFAK"}
TARGET_DIST=${TARGET_DIST:-"YOUFAK"}
TARGET_LAN_IP=${TARGET_LAN_IP:-"192.168.99.1"}
DEFAULT_THEME=${DEFAULT_THEME:-"luci-theme-argon"}
TARGET_HOSTNAME="${TARGET_HOSTNAME:-OpenWrt}"
BUILD_DATE=$(TZ=UTC-8 date "+%Y.%m.%d")

# -----------------------------
# 彩色日志输出
# -----------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------
# 安全 sed
# -----------------------------
safe_sed() {
    local file="$1" expr="$2" desc="$3"
    if [[ -f "$file" ]]; then
        if sed -i "$expr" "$file" 2>/dev/null; then
            [[ -n "$desc" ]] && log_info "$desc"
        else
            log_warn "sed 失败: $file"
        fi
    else
        log_warn "文件不存在: $file"
    fi
}

# 仅追加一次
append_once() {
    local file="$1" line="$2" desc="$3"
    mkdir -p "$(dirname "$file")"
    touch "$file"

    if ! grep -Fqx "$line" "$file"; then
        echo "$line" >> "$file"
        log_info "$desc"
    else
        log_warn "已存在：$desc"
    fi
}

log_info "开始执行增强版 DIY 脚本 ..."

# ============================================================
# 0. OpenClash po2lmo
# ============================================================
PO2LMO_DIR="package/luci-app-openclash/tools/po2lmo"
if [[ -d "$PO2LMO_DIR" ]]; then
    pushd "$PO2LMO_DIR" >/dev/null
    if ! command -v po2lmo >/dev/null 2>&1; then
        log_info "编译 po2lmo ..."
        make >/dev/null 2>&1 && (make install >/dev/null 2>&1 || true)
    else
        log_info "po2lmo 已存在"
    fi
    popd >/dev/null
fi

# ============================================================
# 1. 修改 LAN IP
# ============================================================
CFG_GEN="package/base-files/files/bin/config_generate"
if [[ -f "$CFG_GEN" ]]; then
    safe_sed "$CFG_GEN" \
        "s/192.168.1.1/${TARGET_LAN_IP}/g" \
        "默认 LAN IP → ${TARGET_LAN_IP}"
fi

# ============================================================
# 2. 修改主机名
# ============================================================
ZZZ="package/lean/default-settings/files/zzz-default-settings"
safe_sed "$ZZZ" \
    "/uci commit system/i\uci set system.@system[0].hostname='${TARGET_HOSTNAME}'" \
    "主机名设置为 ${TARGET_HOSTNAME}"

# ============================================================
# 3. 清空默认密码
# ============================================================
safe_sed "$ZZZ" \
    "s@.*CYXluq4wUazHjmCDBCqXF*@#&@" \
    "默认密码已清空"

# ============================================================
# 4. 修改时区
# ============================================================
if grep -q "timezone" "$CFG_GEN"; then
    safe_sed "$CFG_GEN" \
        "s/option timezone.*/option timezone 'CST-8'/" \
        "时区修改为 CST-8"

    safe_sed "$CFG_GEN" \
        "s/option zonename.*/option zonename 'Asia\\/Shanghai'/" \
        "地区修改为 Asia/Shanghai"
fi

# ============================================================
# 5. 版本号添加构建信息
# ============================================================
BUILD_DATE=$(TZ=UTC-8 date "+%Y.%m.%d")
safe_sed "$ZZZ" \
    "s/OpenWrt /${TARGET_HOSTNAME} build ${BUILD_DATE} @ ${TARGET_DIST} /" \
    "s/LEDE /${TARGET_DIST} build ${BUILD_DATE} @ ${TARGET_HOSTNAME} /" \
    "版本号已加入 build 信息"

# ============================================================
# 6. sysctl 性能优化
# ============================================================
SYSCTL="package/base-files/files/etc/sysctl.conf"
touch "$SYSCTL"

append_once "$SYSCTL" "net.netfilter.nf_conntrack_max=165535" "优化连接跟踪表"
append_once "$SYSCTL" "net.core.somaxconn = 1024" "优化监听队列"
append_once "$SYSCTL" "fs.file-max = 65535" "文件句柄数优化"

# 一次性追加优化块
if ! grep -q "===== TCP OPTIMIZE =====" "$SYSCTL"; then
cat >> "$SYSCTL" <<'EOF'

# ===== TCP OPTIMIZE =====
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fastopen = 3

# ===== 文件句柄 =====
vm.swappiness = 10

# ===== 可选：禁用 IPv6 =====
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1
EOF
    log_info "追加 TCP/FS 优化配置"
fi

# ============================================================
# 7. 默认主题
# ============================================================
#更换lede源码中自带argon主题
LUCIMK="./feeds/luci/collections/luci/Makefile"
if [[ -f "$LUCIMK" ]]; then
    safe_sed "$LUCIMK" \
        "s/luci-theme-bootstrap/${DEFAULT_THEME}/g" \
        "默认主题替换为 ${DEFAULT_THEME}"
fi

log_info "DIY Part 2 执行完成！"
