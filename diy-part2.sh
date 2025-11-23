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
# 1.1. 修改时区配置
# ============================================================
if [ -f "$FILE_IP" ]; then
    # 查找并修改 timezone 配置（通常在 315 行附近）
    # 匹配各种可能的格式：timezone='UTC' 或 timezone="UTC" 等
    if grep -qE "set system\.@system\[-1\]\.timezone=" "$FILE_IP"; then
        # 如果已存在 timezone 配置，则替换
        sed -i "s|set system\.@system\[-1\]\.timezone=.*|set system.@system[-1].timezone='CST-8'|g" "$FILE_IP"
        log_info "时区已修改为 CST-8"
    else
        # 如果不存在，查找 system 配置区域并在合适位置添加
        # 查找包含 system.@system[-1] 的配置行，在其后添加时区设置
        TIMEZONE_LINE=$(grep -n "set system\.@system\[-1\]" "$FILE_IP" | tail -1 | cut -d: -f1)
        if [ -n "$TIMEZONE_LINE" ]; then
            # 在找到的行后插入时区配置（使用 sed 的 a 命令，保持原有缩进格式）
            sed -i "${TIMEZONE_LINE}a\		set system.@system[-1].timezone='CST-8'" "$FILE_IP"
            log_info "时区配置已添加为 CST-8"
        else
            log_warn "未找到 system 配置区域，跳过时区配置"
        fi
    fi
    
    # 添加或修改 zonename 配置
    if grep -qE "set system\.@system\[-1\]\.zonename=" "$FILE_IP"; then
        sed -i "s|set system\.@system\[-1\]\.zonename=.*|set system.@system[-1].zonename='Asia/Shanghai'|g" "$FILE_IP"
        log_info "时区名称已修改为 Asia/Shanghai"
    else
        # 在 timezone 配置后添加 zonename
        ZONENAME_LINE=$(grep -n "set system\.@system\[-1\]\.timezone=" "$FILE_IP" | tail -1 | cut -d: -f1)
        if [ -n "$ZONENAME_LINE" ]; then
            sed -i "${ZONENAME_LINE}a\		set system.@system[-1].zonename='Asia/Shanghai'" "$FILE_IP"
            log_info "时区名称已添加为 Asia/Shanghai"
        else
            log_warn "未找到 timezone 配置，跳过 zonename 配置"
        fi
    fi
else
    log_warn "未找到 config_generate，跳过时区修改"
fi

# ============================================================
# 2. 默认密码为空
# ============================================================
# PASS_FILE="package/base-files/files/etc/shadow"

# if [ -f "$PASS_FILE" ]; then
#     sed -i "s@.*CYXluq4wUazHjmCDBCqXF*@#&@" "$PASS_FILE"
#     log_info "默认密码已设置为空"
# else
#     log_warn "找不到默认设置文件，跳过密码设置"
# fi


# ============================================================
# 修改发行人信息
# ============================================================
FILE="include/version.mk"
# 检查文件是否存在
if [ -f "$FILE" ]; then
    log_info "正在修改 version.mk …"

    # 修改 VERSION_DIST 默认值
    sed -i "s/VERSION_DIST:=\$(if \$(CONFIG_VERSION_DIST),\$(CONFIG_VERSION_DIST),ImmortalWrt)/VERSION_DIST:=\$(if \$(CONFIG_VERSION_DIST),\$(CONFIG_VERSION_DIST),YOUFAK)/" $FILE

    # 修改 VERSION_MANUFACTURER 默认值
    sed -i "s/VERSION_MANUFACTURER:=\$(if \$(CONFIG_VERSION_MANUFACTURER),\$(CONFIG_VERSION_MANUFACTURER),ImmortalWrt)/VERSION_MANUFACTURER:=\$(if \$(CONFIG_VERSION_MANUFACTURER),\$(CONFIG_VERSION_MANUFACTURER),YOUFAK)/" $FILE

    log_info "修改完成！"
else
    log_warn "找不到文件：$FILE"
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