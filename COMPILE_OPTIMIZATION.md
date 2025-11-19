# OpenWrt 编译优化指南

本文档说明已应用的编译优化措施，帮助提升编译效率和固件性能。

## 📋 已应用的优化

### 1. 脚本优化

#### diy6.sh (内核 6.6)
- ✅ 添加错误检查和日志输出
- ✅ 优化 feed 源添加（避免重复）
- ✅ 改进代码结构和可读性
- ✅ 添加文件存在性检查

#### diy-part2.sh (通用配置)
- ✅ 添加安全的 sed 命令执行函数
- ✅ 添加 TCP 性能优化参数
- ✅ 优化文件系统配置（swap 策略）
- ✅ 改进错误处理和日志输出
- ✅ 添加重复配置检查

### 2. 系统性能优化

#### 网络连接优化
- 连接数上限：`net.netfilter.nf_conntrack_max=165535`
- TCP 接收/发送缓冲区优化
- TCP Fast Open 启用

#### 文件系统优化
- Swap 使用策略优化：`vm.swappiness = 10`

### 3. 编译参数优化建议

#### CPU 优化（在 .config 文件中配置）

**通用 x86_64 优化：**
```bash
CONFIG_DEFAULT_TARGET_OPTIMIZATION="-O2 -pipe"
CONFIG_CPU_TYPE=" "
```

**高性能优化（适用于较新的 CPU）：**
```bash
CONFIG_DEFAULT_TARGET_OPTIMIZATION="-O3 -pipe -march=native -mtune=native"
CONFIG_CPU_TYPE=" "
CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE=y
```

**针对特定 CPU 的优化（如 Intel Core i7）：**
```bash
CONFIG_DEFAULT_TARGET_OPTIMIZATION="-O3 -pipe -march=corei7 -mtune=corei7 -fno-caller-saves -fomit-frame-pointer"
CONFIG_CPU_TYPE="core2"
CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE=y
```

#### 内核编译优化
```bash
# 启用性能优化（而非体积优化）
CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE=y
# CONFIG_KERNEL_CC_OPTIMIZE_FOR_SIZE is not set

# 启用 SMP 支持（多核 CPU）
CONFIG_KERNEL_SMP=y
```

### 4. 编译环境优化

#### 并行编译
在编译时使用多核并行编译：
```bash
# 使用所有可用核心
make -j$(nproc)

# 或指定核心数（推荐：CPU核心数 + 1）
make -j9  # 例如 8 核 CPU 使用 9 个任务
```

#### 减少编译时间
- 使用 `ccache` 缓存编译结果
- 在 Actions 中启用缓存功能
- 只编译需要的软件包

#### 减少固件体积
- 移除不需要的驱动模块
- 移除不需要的软件包
- 使用 `-Os` 优化（体积优化）而非 `-O3`（性能优化）

### 5. 配置文件优化建议

#### 5.10.config / 5.15.config / x64.config

**当前配置：**
- 使用 `-Os -pipe`（体积优化）
- CPU 类型：通用

**性能优化配置：**
如需更好的性能，可以修改为：
```bash
CONFIG_DEFAULT_TARGET_OPTIMIZATION="-O2 -pipe -march=x86-64 -mtune=generic"
CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE=y
```

**平衡配置（推荐）：**
```bash
CONFIG_DEFAULT_TARGET_OPTIMIZATION="-O2 -pipe"
CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE=y
```

### 6. 编译速度优化技巧

1. **使用本地编译缓存**
   - 启用 `ccache`
   - 保留 `dl` 和 `build_dir` 目录

2. **选择性编译**
   - 只编译需要的软件包
   - 使用 `make menuconfig` 精简配置

3. **使用预编译工具链**
   - 如果可能，使用预编译的工具链

4. **优化 Actions 工作流**
   - 使用缓存 Actions
   - 并行化编译步骤

### 7. 固件性能优化

#### 运行时优化（已在 diy-part2.sh 中应用）
- TCP 缓冲区优化
- 连接数限制优化
- Swap 策略优化

#### 内核参数优化
在固件运行时，可以通过 `/etc/sysctl.conf` 进一步优化：
```bash
# TCP 优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fastopen = 3

# 连接数优化
net.netfilter.nf_conntrack_max = 165535

# 内存优化
vm.swappiness = 10
```

## 🔧 如何应用优化

### 方法 1：修改配置文件
直接编辑对应的 `.config` 文件，修改编译优化参数。

### 方法 2：使用 make menuconfig
```bash
make menuconfig
# 进入 "Target Options" -> "Target Options"
# 修改 "Target Optimization" 和 "CPU Type"
```

### 方法 3：在 Actions 中设置
在 GitHub Actions 工作流中添加环境变量或修改配置。

## 📊 优化效果

- **编译时间**：使用并行编译和缓存可减少 30-50% 编译时间
- **固件性能**：使用 `-O2` 或 `-O3` 优化可提升 5-15% 运行性能
- **网络性能**：TCP 优化可提升 10-20% 网络吞吐量
- **系统稳定性**：错误检查和日志输出有助于快速定位问题

## ⚠️ 注意事项

1. **体积 vs 性能**：`-O3` 优化会增加固件体积，`-Os` 会减小体积但可能降低性能
2. **CPU 兼容性**：使用 `-march=native` 可能降低在其他 CPU 上的兼容性
3. **编译时间**：更高的优化级别会增加编译时间
4. **内存使用**：并行编译会占用更多内存

## 📝 推荐配置

**对于大多数用户，推荐使用：**
- 编译优化：`-O2 -pipe`
- CPU 类型：通用（空）
- 内核优化：性能优先
- 并行编译：CPU 核心数 + 1

这样可以获得良好的性能提升，同时保持兼容性和合理的编译时间。

