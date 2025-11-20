# OpenWrt R23-X86-64云编译项目

## 固件来源：

P3TERX云编译脚本地址：[https://github.com/P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)

lean固件源码地址：[https://github.com/coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)

插件引用：[luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon.git)、[istore](https://github.com/linkease/istore.git)。

由衷感谢所有为openwrt无私奉献的大佬们。

## 固件说明：

lean源码版本，内核为***5.10***版、***5.15***、***6.1***版

支持IPV6

该固件相对说是纯静的基乎没有任何的插件，软件包可用空间大约800MB左右

自动检查lede更新如果有就自动更新，手动不定时更新

> `管理ip：192.168.99.1 密码：为空`

### 固件分区默认256M+2048mb,分区一致可直接web升级，否则请使用DD写盘或重新写盘，首次刷入不建议保留配置，以免发生BUG。

### esxi构架中安装的全部建议重新写入，不建议在线升级

![image](https://user-images.githubusercontent.com/27138744/218228804-a7a128ce-671a-4abd-a97e-8a33b90fd5bd.png)
![image](https://user-images.githubusercontent.com/27138744/209439304-c3004851-c360-4695-a5c6-930618902122.png)
![image](https://user-images.githubusercontent.com/27138744/209439320-04f2a7f3-d084-4c98-97b5-518ae6aa41ca.png)
## 5.10只有如下插件
![image](https://user-images.githubusercontent.com/27138744/221386973-56c176f5-6672-4dca-88b4-e9de21627a36.png)




