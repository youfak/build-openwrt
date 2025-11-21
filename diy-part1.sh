#!/bin/bash
#============================================================
# DIY Part 1: Before Update Feeds
# OpenWrt build environment pre-configuration
#============================================================

set -e

KERNEL_VER="${KERNEL_VER:-5.15}" 
echo "Selected Kernel Version: $KERNEL_VER"

echo -e "\n=== [1] 切换 X86 内核版本为：$KERNEL_VER ==="
if [ -f target/linux/x86/Makefile ]; then
    sed -i "s/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=$KERNEL_VER/g" target/linux/x86/Makefile
    sed -i "s/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=$KERNEL_VER/g" target/linux/x86/Makefile
fi

echo -e "\n=== [2] 添加 kenzok8 源 ==="
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default

echo -e "\n=== [3] 删除冲突 luci/mosdns ==="
rm -rf feeds/luci/applications/luci-app-mosdns 2>/dev/null || true

echo -e "\n=== [4] 删除重复/冲突网络代理插件 ==="
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat

echo -e "\n=== [5] 替换 Golang → 1.25（支持 sing-box & hysteria2） ==="
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang -b 1.25 feeds/packages/lang/golang

echo -e "\n=== [6] 下载 OpenClash（浅克隆）==="

if [ ! -d "package/luci-app-openclash" ]; then
    mkdir -p package/luci-app-openclash
    cd package/luci-app-openclash
    git init
    git remote add -f origin https://github.com/vernesong/OpenClash
    git config core.sparsecheckout true
    echo "luci-app-openclash" > .git/info/sparse-checkout
    git pull --depth 1 origin master
    mv luci-app-openclash/* . 2>/dev/null || true
    mv luci-app-openclash/.* . 2>/dev/null || true
    rm -rf luci-app-openclash .git
    cd -
fi

echo -e "\n=== DIY Part 1 Completed ==="
