# OpenWRT 编译 make menuconfig 配置及 LUCI 插件说明

**源码说明：** 本项目使用 Lean's LEDE 源码

- **源码地址**：https://github.com/coolsnowwolf/lede
- **分支**：master
- **说明**：Lean's LEDE 是基于 OpenWrt 的优秀分支，包含丰富的中文插件和优化

*本文档由 OpenWRT编译make menuconfig配置及LUCI插件说明.xlsx 自动转换生成*

---

## make menuconfig配置

| 1级菜单 | 2级菜单 | 3级菜单(or子选项) | 子选项(or说明) |
| --- | --- | --- | --- |
| Target System | 选择处理器类型 |  |  |
| Subtarget | 选择处理器型号 |  |  |
| Target Profile | 选择路由版型 |  |  |
| Target Images | ext4（可读写文件系统，不支持恢复出厂设置，软件包可完全卸载） |  |  |
|  | squashfs（只读文件系统，支持恢复出厂设置和web升级固件，软件包无法完全卸载） | Block size （压缩比） | 默认256(可调为512、1024或更高减小固件体积)数值越高占用运行内存越高，运行速度越慢 |
|  | Build EFI GRUB images(编译支持UEFI启动固件) |  |  |
|  | Build PVE/KVM image files(编译PVE镜像固件) |  |  |
|  | GZip images（固件打包压缩）（*） |  |  |
|  | Kernel partition size (内核分区大小) | 默认16或30 （即：软件包安装区域的大小） | 两个分区大小总和为固件大小 |
|  | Root filesystem partition size (系统分区大小) | 默认160或90 |  |
| Base system(系统程序) | <span style="color: #FFD700;">**blockd**</span> |  |  |
|  | dnsmasq-full | <span style="color: #0066FF;">**build with dhcpv6 support(支持IPv6）(*)**</span> |  |
| Administration(系统监控程序) | htop(进程浏览器) |  |  |
|  | <span style="color: #999999;">netdata(实时监控)</span> |  |  |
| Extra packages | autocore |  |  |
|  | automount |  |  |
|  | <span style="color: #FF0000;">**autosamba(只支持samba3,选择samba4时去掉)**</span> |  |  |
|  | <span style="color: #0066FF;">ipv6helper(支持IPv6）(*)</span> |  |  |
| Kernel modules(内核模块) | Block Devices（块设备支持） | <span style="color: #FFD700;">**kmod-ata-core（串行ATA总线支持，即SATA硬盘支持)**</span> | <span style="color: #FFD700;">**kmod-ata-ahci**</span> |
|  |  | <span style="color: #FFD700;">**kmod-block2mtd**</span> |  |
|  |  | kmod-scsi-core |  |
|  |  | <span style="color: #FFD700;">**kmod-scsi-generic（usb转IDE,SATA)**</span> |  |
|  | Filesystems（文件系统支持） | <span style="color: #FFD700;">**kmod-fs-cifs（选择该项可能要在编译过程中手动按Y）**</span> |  |
|  |  | kmod-fs-ext4 |  |
|  |  | <span style="color: #FFD700;">**kmod-fs-nfs**</span> |  |
|  |  | <span style="color: #FFD700;">**kmod-fs-nfs-common**</span> |  |
|  |  | <span style="color: #999999;">kmod-fs-nfs-v3</span> |  |
|  |  | <span style="color: #999999;">kmod-fs-nfs-v4</span> |  |
|  |  | kmod-fs-vfat |  |
|  |  | kmod-fuse |  |
|  |  | kmod-fs-ntfs (不选，只有只读模式) |  |
|  |  | <span style="color: #999999;">kmod-fs-squashfs</span> |  |
|  |  | kmod-fs-f2fs |  |
|  | Native Language Support（语言编码支持） | kmod-nls-cp437 |  |
|  |  | kmod-nls-iso8859-1 |  |
|  |  | <span style="color: #FFD700;">**kmod-nls-cp936 (中文字符支持)**</span> |  |
|  |  | kmod-nls-utf8 |  |
|  | Network Devices（有线网卡支持） | kmod-vmxnet3(esxi虚拟网卡) |  |
|  |  | <span style="color: #999999;">I350</span> |  |
|  |  | <span style="color: #999999;">killer 1535A</span> |  |
|  |  | <span style="color: #999999;">kmod-sky2</span> |  |
|  |  | 按需选择 |  |
|  | USB Support（USB设备支持） | kmod-usb-core |  |
|  |  | kmod-usb-hid |  |
|  |  | <span style="color: #FFD700;">**kmod-usb-ohci**</span> |  |
|  |  | <span style="color: #999999;">kmod-usb-printer</span> |  |
|  |  | <span style="color: #FFD700;">**kmod-usb-storage**</span> |  |
|  |  | <span style="color: #FFD700;">**kmod-usb-storage-extras**</span> |  |
|  |  | <span style="color: #FFD700;">**kmod-usb-storage-uas**</span> |  |
|  |  | <span style="color: #FFD700;">**kmod-usb-uhci(usb1.1驱动)**</span> |  |
|  |  | <span style="color: #FFD700;">**kmod-usb2**</span> |  |
|  |  | <span style="color: #FFD700;">**kmod-usb3**</span> |  |
|  | Video Support（摄像头与外接显示器支持) | <span style="color: #999999;">kmod-video-core</span> |  |
|  |  | <span style="color: #999999;">kmod-video-uvc</span> |  |
|  |  | <span style="color: #999999;">kmod-video-videobuf2</span> |  |
|  |  | <span style="color: #999999;">按需选择驱动</span> |  |
|  | Virtualization（虚拟化） | kmod-kvm-amd (amd处理器) |  |
|  |  | kmod-kvm-intel (intel处理器) |  |
|  |  | <span style="color: #FFD700;">**kmod-kvm-x86**</span> |  |
|  | Wireless Drivers（无线网卡选择） | 按需选择 |  |
| LuCI | Application | luci-app-turboacc | Turbo ACC 网络加速(支持 Fast Path 或者 硬件 NAT) |
|  |  | Include Flow Offload | Flow Offload加速(提高路由转发效率) |
|  |  | Include Shortcut-FE | Shortcut-FE 流量分载 |
|  |  | Include Shortcut-FE CM | Shortcut-FE CM流量分载(高通芯片版) |
|  |  | Include BBR CCA | BBR拥塞控制算法提升TCP网络性能 |
|  |  | Include Pdnsd | DNS防污染 Pdnsd |
|  |  | Include DNSForwarder | DNS防污染 Forwarder |
|  |  | Include DNSProxy | DNS防污染 Proxy |
|  |  | 其余见表2 |  |
|  |  | <span style="color: #FF0000;">**luci-app-samba与luci-app-samba4不共存**</span> |  |
|  | Themes | 省略 |  |
| Network | BitTorrent | qBittorrent (luci-qBt选中时自动选取) |  |
|  |  | transmission-cli (luci-transmission选中时选取) |  |
|  |  | transmission-daemo (luci-transmission选中时选取) |  |
|  |  | transmission-remote (luci-transmission选中时选取) |  |
|  |  | transmission-web （不选，与transmission-web-control冲突） |  |
|  |  | transmission-web-control (luci-transmission选中时自动选取) |  |
|  | Download manager | ariang(luci-aria选中时自动选取) |  |
|  | File transfer | aria2 (luci-aria选中时自动选取) |  |
|  |  | curl（aria依赖） |  |
|  | Firewall | <span style="color: #0066FF;">**ip6tables (支持IPv6）(*)**</span> | <span style="color: #0066FF;">**ip6tables-extra**</span> |
|  |  |  | <span style="color: #0066FF;">**ip6tables-mod-nat（IPv6-NAT扩展）**</span> |
|  | IP Addresses and Names | <span style="color: #999999;">ddns-scripts_no_ip_com (DDNS服务提供商, 其他服务商按需选择)</span> |  |
|  | SSH（*） | <span style="color: #999999;">openssh-sftp-server（支持xftp使用sftp协议登录）</span> |  |
|  | <span style="color: #999999;">iperf3（网络速度测试工具）（*）</span> |  |  |
|  | samba4-server | Avahi support |  |
|  |  | common VFS modules |  |
|  |  | <span style="color: #FFD700;">**NetBiOS support (在网络里显示共享文件)**</span> |  |
|  | samba4-libs |  |  |
|  | <span style="color: #FF0000;">**samba36-server(不和samba4组件共存)**</span> |  |  |
| Utilities（实用工具） | Compression | <span style="color: #999999;">gzip</span> |  |
|  |  | <span style="color: #999999;">unzip</span> |  |
|  |  | <span style="color: #999999;">zip</span> |  |
|  | Disc | blkid（列出分区类型卷标） |  |
|  |  | fdisk（分区工具） |  |
|  |  | lsblk（列出块设备） |  |
|  |  | hdparm（硬盘管理工具） |  |
|  | Editor | nano（跟vi差不多，但好用） |  |
|  | Filesystem | <span style="color: #FFD700;">**ntfs-3g（ntfs文件系统）**</span> |  |
|  |  | <span style="color: #999999;">badblocks（支持ext2文件系统坏块）</span> |  |
|  |  | <span style="color: #999999;">e2fsprogs（ext2文件系统实用程序 e2fsck，mke2fs）</span> |  |
|  | Virtualization（PVE虚拟化） | qemu-bridge-helper（QEMU桥接助手） |  |
|  |  | qemu-firmware-efi（QEMU iPXE-UEFI网络启动） |  |
|  |  | qemu-firmware-pxe（QEMU iPXE-传统网络启动） |  |
|  |  | qemu-firmware-seabios（QEMU build of SeaBIOS for x86 guest） |  |
|  |  | qemu-firmware-seavgabios（QEMU build of SeaVGABIOS） |  |
|  |  | qemu-ga（QEMU代理） |  |
|  |  | qemu-keymaps（QEMU reverse keymaps for use with -k argument） |  |
|  |  | qemu-x86_64-softmmu（QEMU target x86_64-softmmu ） |  |
|  |  | QEMU VNC support | <span style="color: #999999;">QEMU VNC jpeg tight encoding support</span> |
|  |  |  | <span style="color: #999999;">QEMU VNC png tight encoding support</span> |
|  |  |  | <span style="color: #999999;">QEMU VNC SASL auth support</span> |
|  |  | <span style="color: #999999;">QEMU SPICE ui support</span> |  |
|  |  | virtio-console-helper（vportNpn virtio控制台设备的帮助程序脚本） |  |
|  | open-vm-tools（ESXI虚拟化） |  |  |
|  | <span style="color: #999999;">usbutils（lsusb命令）</span> | <span style="color: #999999;">依赖：Libraries->libusb-1.0</span> |  |
|  | lm-sensors（硬件监控） |  |  |
|  | <span style="color: #999999;">lm-sensors-detect（硬件传感器查找）</span> |  |  |

**注：**

- **浅灰色字体**：不重要可选
- **黄色字体**：必须
- **红色字体**：注意（samba与samba4不能共存，取消samba需要先取消autosamba）
- **蓝色字体**：为IPv6支持
- **红色框体**：不选
- **(\*)**：为最新改动

---