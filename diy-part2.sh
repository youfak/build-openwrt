#!/usr/bin/env bash
#============================================================
# DIY script part 2 (After Update feeds)
# Enhanced: add more automated optimizations + auto hostname/dist
#============================================================

set -euo pipefail

# -----------------------------
# 可配置项（按需修改）
# -----------------------------
TARGET_HOSTNAME=${TARGET_HOSTNAME:-"YOUFAK"}
TARGET_DIST=${TARGET_DIST:-"YOUFAK"}
TARGET_LAN_IP=${TARGET_LAN_IP:-"192.168.99.1"}
DEFAULT_THEME=${DEFAULT_THEME:-"luci-theme-argon"}

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
# 安全 sed wrapper (in-place for GNU sed)
# -----------------------------
safe_sed() {
    local file="$1"
    local expr="$2"
    local desc="$3"
    if [[ -f "$file" ]]; then
        if sed -i "$expr" "$file" 2>/dev/null; then
            log_info "$desc"
        else
            log_warn "sed 执行失败: $file"
        fi
    else
        log_warn "文件不存在: $file"
    fi
}

ensure_append_once() {
    local file="$1"
    local line="$2"
    local desc="$3"
    if [[ -f "$file" ]]; then
        if ! grep -Fqx "$line" "$file"; then
            echo "$line" >> "$file"
            log_info "$desc"
        else
            log_warn "已存在，跳过：$desc"
        fi
    else
        log_warn "文件不存在，无法追加：$file"
    fi
}

log_info "开始执行增强版 DIY 脚本 Part 2 ..."

# ============================================================
# 0. 编译 po2lmo（OpenClash 需要）
# ============================================================
PO2LMO_DIR="package/luci-app-openclash/tools/po2lmo"

if [[ -d "$PO2LMO_DIR" ]]; then
    log_info "检测到 OpenClash，检查 po2lmo ..."
    pushd "$PO2LMO_DIR" >/dev/null
    if [[ ! -f po2lmo ]] && ! command -v po2lmo >/dev/null 2>&1; then
        log_info "正在编译 po2lmo ..."
        if make >/dev/null 2>&1; then
            if make install >/dev/null 2>&1 || sudo make install >/dev/null 2>&1; then
                log_info "po2lmo 编译并安装成功"
            else
                log_warn "po2lmo 编译成功，但安装失败（构建系统会自动处理）"
            fi
        else
            log_warn "po2lmo 编译失败（可能会在最终构建时自动编译）"
        fi
    else
        log_info "po2lmo 已存在，跳过"
    fi
    popd >/dev/null
else
    log_warn "未找到 luci-app-openclash 工具目录，跳过 po2lmo"
fi

# ============================================================
# 1. 修改默认 LAN IP（config_generate）
# ============================================================
FILE_CONFIG_GENERATE="package/base-files/files/bin/config_generate"
if [[ -f "$FILE_CONFIG_GENERATE" ]]; then
    if grep -q "192.168.1.1" "$FILE_CONFIG_GENERATE"; then
        sed -i "s/192.168.1.1/${TARGET_LAN_IP}/g" "$FILE_CONFIG_GENERATE"
        log_info "默认 LAN IP 修改为：${TARGET_LAN_IP}"
    else
        log_warn "config_generate 中未找到 192.168.1.1，跳过 IP 修改"
    fi
else
    log_warn "未找到 $FILE_CONFIG_GENERATE，跳过 IP 修改"
fi

# ============================================================
# 2. 自动修改默认主机名（config_generate）
# ============================================================
if [[ -f "$FILE_CONFIG_GENERATE" ]]; then
    # 如果文件包含 ImmortalWrt 则替换；否则检查是否已设置为目标名，若不同则替换默认赋值位置
    if grep -q "set system.@system\[-1\].hostname=" "$FILE_CONFIG_GENERATE"; then
        # 替换任意已有默认（包括 ImmortalWrt 或以前的自定义）
        safe_sed "$FILE_CONFIG_GENERATE" "s/set system.@system\\[-1\\]\\.hostname='[^']*'/set system.@system[-1].hostname='${TARGET_HOSTNAME}'/g" "已将 config_generate 中默认主机名改为：${TARGET_HOSTNAME}"
        
    else
        log_warn "config_generate 未找到 hostname 设置，跳过主机名修改"
    fi
fi

# ============================================================
# 2.1 自动修改默认时区（CST-8 & Asia/Shanghai）
# ============================================================
if [[ -f "$FILE_CONFIG_GENERATE" ]]; then
    # 修改 timezone 默认值
    if grep -q "set system.@system\\[-1\\]\\.timezone=" "$FILE_CONFIG_GENERATE"; then
        safe_sed "$FILE_CONFIG_GENERATE" \
            "s/set system.@system\\[-1\\]\\.timezone='[^']*'/set system.@system[-1].timezone='CST-8'/g" \
            "已将默认 timezone 修改为 CST-8"
    else
        log_warn "config_generate 中找不到 timezone 配置，可能版本不同，未修改"
    fi

    # 修改 zonename 默认值
    if grep -q "set system.@system\\[-1\\]\\.zonename=" "$FILE_CONFIG_GENERATE"; then
        safe_sed "$FILE_CONFIG_GENERATE" \
            "s/set system.@system\\[-1\\]\\.zonename='[^']*'/set system.@system[-1].zonename='Asia\\/Shanghai'/g" \
            "已将默认 zonename 修改为 Asia/Shanghai"
    else
        # 如果不存在，则追加
        safe_sed "$FILE_CONFIG_GENERATE" \
            "/set system.@system\\[-1\\]\\.timezone=.*/a\\\tset system.@system[-1].zonename='Asia/Shanghai'" \
            "已追加默认 zonename=Asia/Shanghai"
    fi
fi


# ============================================================
# 3. 在 include/version.mk 或 .config 中设置发行名（VERSION_DIST）
#    - 优先修改 .config（更干净）；若没有 .config 再修改 include/version.mk 的默认常量
# ============================================================
ROOT_CONFIG=".config"
VERSION_MK_CANDIDATES=("include/version.mk" "immortalwrt/include/version.mk")

# 写入 .config 的辅助函数（只写一次）
ensure_config_option() {
    local opt="$1"
    local val="$2"
    if [[ -f "$ROOT_CONFIG" ]]; then
        if grep -Eq "^${opt}=" "$ROOT_CONFIG"; then
            log_warn ".config 已存在 ${opt}，跳过写入"
        else
            echo "${opt}=\"${val}\"" >> "$ROOT_CONFIG"
            log_info "写入到 .config: ${opt}=\"${val}\""
        fi
    else
        # 若没有 .config，创建一个最小 .config 追加项（注意：这可能不是最终的完整 .config）
        echo "${opt}=\"${val}\"" >> "$ROOT_CONFIG"
        log_info "创建 .config 并写入: ${opt}=\"${val}\""
    fi
}

# 设置 VERSION_DIST 与 VERSION_MANUFACTURER 到 .config（更推荐）
ensure_config_option "CONFIG_VERSION_DIST" "${TARGET_DIST}"
ensure_config_option "CONFIG_VERSION_MANUFACTURER" "${TARGET_DIST}"

# 若仍需修改 version.mk 默认值（安全替补）
for mk in "${VERSION_MK_CANDIDATES[@]}"; do
    if [[ -f "$mk" ]]; then
        if grep -q "VERSION_DIST:=.*ImmortalWrt" "$mk" || grep -q "ImmortalWrt" "$mk"; then
            safe_sed "$mk" "s/ImmortalWrt/${TARGET_DIST}/g" "修改 $mk 中的默认发行名为：${TARGET_DIST}"
        fi
    fi
done

# ============================================================
# 4. 替换 package/base-files/etc 下的 'ImmortalWrt' 文案（banner / os-release 等）
#    - 通过查找并替换实现（仅在出现 ImmortalWrt 时替换）
# ============================================================
BASE_FILES_DIR="package/base-files/files"
if [[ -d "$BASE_FILES_DIR" ]]; then
    matches=$(grep -RIl "ImmortalWrt" "$BASE_FILES_DIR" || true)
    if [[ -n "$matches" ]]; then
        while IFS= read -r file; do
            safe_sed "$file" "s/ImmortalWrt/${TARGET_DIST}/g" "替换 ${file} 中的 ImmortalWrt -> ${TARGET_DIST}"
        done <<< "$matches"
    else
        log_warn "package/base-files/files 下未发现 'ImmortalWrt' 文案，跳过替换"
    fi
else
    log_warn "未找到 $BASE_FILES_DIR，跳过文案替换"
fi

# ============================================================
# 5. 优化连接数（sysctl.conf）
# ============================================================
SYSCTL_FILE="package/base-files/files/etc/sysctl.conf"
if [[ -f "$SYSCTL_FILE" ]]; then
    ensure_append_once "$SYSCTL_FILE" "net.netfilter.nf_conntrack_max=165535" "连接数优化: nf_conntrack_max=165535"

    ensure_append_once "$SYSCTL_FILE" "net.core.somaxconn = 1024" "提高监听队列: somaxconn = 1024"
    ensure_append_once "$SYSCTL_FILE" "fs.file-max = 65535" "提高系统文件描述符上限: fs.file-max = 65535"
else
    log_warn "未找到 $SYSCTL_FILE，跳过连接数优化"
fi

# ============================================================
# 6. TCP / FS / IPv6 优化（追加 block，确保只写一次）
# ============================================================
if [[ -f "$SYSCTL_FILE" ]]; then
    if ! grep -q "===== TCP 优化 =====" "$SYSCTL_FILE"; then
        cat >> "$SYSCTL_FILE" <<'EOF'

# ===== TCP 优化 =====
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 1024

# ===== 文件句柄与内核优化 =====
fs.file-max = 65535
vm.swappiness = 10

# ===== 可选: 禁用 IPv6（如果你希望禁用） =====
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
        log_info "追加 TCP/FS/IPv6 优化到 $SYSCTL_FILE"
    else
        log_warn "sysctl 优化段已存在，跳过追加"
    fi
fi

# ============================================================
# 7. 设置默认主题（feeds 的 luci Makefile）
# ============================================================
LUCIMK="feeds/luci/collections/luci/Makefile"
if [[ -f "$LUCIMK" ]]; then
    if grep -q "luci-theme-bootstrap" "$LUCIMK"; then
        sed -i "s/luci-theme-bootstrap/${DEFAULT_THEME}/g" "$LUCIMK" \
            && log_info "默认主题已替换为 ${DEFAULT_THEME}" || log_warn "替换主题时出错"
    else
        log_warn "luci Makefile 未包含 luci-theme-bootstrap，可能已被替换或不存在"
    fi
else
    log_warn "未找到 $LUCIMK，跳过主题设置"
fi

# ============================================================
# 8. 额外建议性优化（可选：注释示例，默认未启用）
#    - 如果你想开启下面任意项，把对应行前的 'false' 改为 'true'
# ============================================================
ENABLE_EXTRA_FIREWALL_TWEAKS=${ENABLE_EXTRA_FIREWALL_TWEAKS:-false}
if [[ "${ENABLE_EXTRA_FIREWALL_TWEAKS}" == "true" ]]; then
    # 仅作示例：增加 conntrack timeout/limits 等（谨慎开启）
    if [[ -f "$SYSCTL_FILE" ]]; then
        ensure_append_once "$SYSCTL_FILE" "net.netfilter.nf_conntrack_tcp_timeout_established = 86400" "conntrack 已设置超时示例"
    fi
fi

# ============================================================
# 9. 清理 & 提示
# ============================================================
log_info "DIY 脚本 Part 2 执行完成！"
log_info "注意：如果你希望把发行名写入其他位置（如源码中多处出现），可以再运行一次脚本或手动检查 package/*/files 中的文案。"

# 友情提示（不进行任何自动化操作，仅提示）
log_info "建议：运行 'make menuconfig' 检查 Global build settings -> Custom distribution configuration 是否按需设置了 CONFIG_VERSION_*"
exit 0
