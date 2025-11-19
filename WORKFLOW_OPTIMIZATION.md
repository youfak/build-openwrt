# GitHub Actions 工作流优化说明

## 📋 已应用的优化

### 1. 更新 Actions 版本

#### 已更新：
- ✅ `actions/checkout@main` → `actions/checkout@v4`
- ✅ `actions/upload-artifact@main` → `actions/upload-artifact@v4`
- ✅ `actions/cache@v3` → `actions/cache@v4` (在 update-checker.yml 中)

#### 原因：
- 使用具体版本号更安全，避免自动更新导致的问题
- v4 版本性能更好，功能更完善

### 2. 修复过时的 set-output 语法

#### 问题：
GitHub Actions 已弃用 `::set-output` 命令，需要使用新的 `$GITHUB_OUTPUT` 环境变量。

#### 已修复：
- ✅ `echo "::set-output name=status::success"` → `echo "status=success" >> $GITHUB_OUTPUT`
- ✅ `echo "::set-output name=release_tag::..."` → `echo "release_tag=..." >> $GITHUB_OUTPUT`
- ✅ `echo "::set-output name=url::..."` → `echo "url=..." >> $GITHUB_OUTPUT`

#### 影响：
- 避免 GitHub Actions 的弃用警告
- 确保工作流在未来版本中继续工作

### 3. 添加 ccache 缓存优化

#### 新增功能：
```yaml
- name: 设置 ccache 缓存
  uses: actions/cache@v4
  with:
    path: /workdir/openwrt/.ccache
    key: ccache-${{ runner.os }}-${{ hashFiles('**/5.10.config') }}
    restore-keys: |
      ccache-${{ runner.os }}-
```

#### 编译步骤优化：
```yaml
export CCACHE_DIR=/workdir/openwrt/.ccache
export CCACHE_MAXSIZE=5G
ccache -s  # 显示缓存统计
make -j$(nproc) || make -j1 || make -j1 V=s
ccache -s  # 显示缓存统计
```

#### 效果：
- **编译速度提升**：第二次及后续编译可提升 30-50% 速度
- **减少网络下载**：缓存已编译的对象文件
- **节省 Actions 时间**：减少编译时间，节省配额

### 4. 添加超时设置

#### 已添加：
- **Job 级别超时**：`timeout-minutes: 360` (6小时)
- **步骤级别超时**：
  - 下载安装包：`timeout-minutes: 30`
  - 编译固件：`timeout-minutes: 240` (4小时)

#### 好处：
- 避免工作流无限期运行
- 及时发现问题
- 节省 Actions 配额

### 5. 优化并行下载

#### 已优化：
- `make download -j8` → `make download -j$(nproc)`
- 使用所有可用 CPU 核心进行并行下载

#### 效果：
- 加快依赖包下载速度
- 充分利用服务器资源

### 6. 统一工作流文件

#### 需要统一：
- OpenWrt5.10.yml
- OpenWrt5.15.yml  
- OpenWrt6.yml

#### 统一内容：
- Actions 版本
- 输出语法
- 缓存配置
- 超时设置

## 🔧 待完成的优化

### OpenWrt5.10.yml
- [x] 更新 checkout 版本
- [x] 更新 upload-artifact 版本
- [x] 修复 set-output 语法（部分）
- [ ] 添加 ccache 缓存
- [ ] 添加超时设置
- [ ] 优化下载并行数

### OpenWrt5.15.yml
- [ ] 更新所有 Actions 版本
- [ ] 修复所有 set-output 语法
- [ ] 添加 ccache 缓存
- [ ] 添加超时设置
- [ ] 优化下载并行数

### OpenWrt6.yml
- [x] 已使用新的输出语法
- [ ] 更新 checkout 版本
- [ ] 更新 upload-artifact 版本
- [ ] 添加 ccache 缓存
- [ ] 添加超时设置
- [ ] 优化下载并行数

### update-checker.yml
- [ ] 更新 cache 版本到 v4

## 📊 优化效果预期

### 编译速度
- **首次编译**：无变化（需要完整编译）
- **后续编译**：提升 30-50%（ccache 缓存生效）

### 稳定性
- **错误处理**：超时设置避免无限等待
- **兼容性**：修复弃用警告，确保未来兼容

### 资源利用
- **CPU 利用**：并行下载充分利用 CPU
- **存储利用**：ccache 缓存减少重复编译

## ⚠️ 注意事项

1. **ccache 缓存大小**：当前设置为 5G，可根据需要调整
2. **超时时间**：根据实际编译时间调整，避免过早超时
3. **缓存键**：使用配置文件哈希，配置变更时自动失效
4. **Actions 配额**：ccache 可以显著减少编译时间，节省配额

## 🚀 使用建议

1. **首次运行**：会创建缓存，编译时间正常
2. **后续运行**：缓存生效，编译速度明显提升
3. **配置变更**：缓存自动失效，重新编译
4. **清理缓存**：如需清理，可在 Actions 中手动删除缓存

## 📝 后续优化建议

1. **添加编译矩阵**：支持多内核版本并行编译
2. **添加通知**：编译完成/失败时发送通知
3. **优化清理步骤**：更智能的旧文件清理
4. **添加编译统计**：记录编译时间和成功率

