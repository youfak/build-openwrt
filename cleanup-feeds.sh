#!/bin/bash
#
# 清理和配置 feeds
# 删除冲突的插件并替换 Golang 版本
#

# 设置错误时退出
set -e

# 删除冲突 luci/mosdns
echo -e "\n=== [3] 删除冲突 luci/mosdns ==="
rm -rf feeds/luci/applications/luci-app-mosdns 2>/dev/null || true

# 删除重复/冲突网络代理插件
echo -e "\n=== [4] 删除重复/冲突网络代理插件 ==="
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat

# 替换 Golang → 1.25（支持 sing-box & hysteria2）
echo -e "\n=== [5] 替换 Golang → 1.25（支持 sing-box & hysteria2） ==="
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang -b 1.25 feeds/packages/lang/golang

