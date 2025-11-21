#!/bin/bash
#
# revert_e790799.sh
# 用于撤销 OpenWrt 内核提交 e790799（BRCM Fullcone NAT1 支持）
#

set -e

# 配置：OpenWrt 源码目录（根据实际修改）
OPENWRT_DIR="${1:-.}"  # 默认当前目录，也可以传入路径

COMMIT_HASH="e790799"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查目录是否存在
if [ ! -d "$OPENWRT_DIR/.git" ]; then
    log_error "目录 $OPENWRT_DIR 不是 Git 仓库，请确认路径"
    exit 1
fi

cd "$OPENWRT_DIR"

# 检查提交是否存在
if git cat-file -e "${COMMIT_HASH}^{commit}" 2>/dev/null; then
    log_info "找到提交 $COMMIT_HASH，开始撤销..."
else
    log_error "提交 $COMMIT_HASH 不存在，请确认源代码是否包含该提交"
    exit 1
fi

# 执行 revert
if git revert --no-commit "$COMMIT_HASH"; then
    log_info "提交已成功反向应用，生成新的 commit..."
    git commit -m "Revert commit $COMMIT_HASH: BRCM Fullcone NAT1 支持"
    log_info "完成撤销提交 $COMMIT_HASH"
else
    log_warn "撤销过程中可能出现冲突，请手动解决冲突后执行：git commit"
fi

log_info "脚本执行完成！"
