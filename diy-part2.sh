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
# 0. 编译 po2lmo 工具（OpenClash 需要）
# ============================================================
PO2LMO_DIR="package/luci-app-openclash/tools/po2lmo"
if [ -d "$PO2LMO_DIR" ]; then
    log_info "检查并编译 po2lmo 工具..."
    cd "$PO2LMO_DIR"
    # 检查 po2lmo 是否已存在
    if [ ! -f "po2lmo" ] && ! command -v po2lmo >/dev/null 2>&1; then
        log_info "编译 po2lmo..."
        if make >/dev/null 2>&1; then
            # 尝试安装（在 GitHub Actions 中可能不需要 sudo）
            if make install >/dev/null 2>&1 || sudo make install >/dev/null 2>&1; then
                log_info "po2lmo 编译并安装成功"
            else
                log_warn "po2lmo 编译成功但安装失败（构建系统会自动处理）"
            fi
        else
            log_warn "po2lmo 编译失败（可能已包含在构建系统中，将自动编译）"
        fi
    else
        log_info "po2lmo 已存在，跳过编译"
    fi
    cd - >/dev/null
else
    log_warn "未找到 po2lmo 目录，跳过（OpenClash 可能使用其他方式）"
fi

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
# 2. 优化连接数
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
# 3. 设置 Argon 为默认主题
# ============================================================
LUCIMK="./feeds/luci/collections/luci/Makefile"

if [ -f "$LUCIMK" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' "$LUCIMK"
    log_info "默认主题已切换为 Argon"
else
    log_warn "未找到 luci Makefile，跳过主题设置"
fi

# ============================================================
# 4. 系统性能优化（TCP / FS）
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