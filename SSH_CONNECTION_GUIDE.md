# GitHub Actions SSH 连接指南

## 📋 概述

当你在 GitHub Actions 工作流中设置 `ssh: true` 时，可以使用 `P3TERX/ssh2actions` 连接到正在运行的 Actions 环境进行调试。

## 🚀 连接步骤

### 1. 启动工作流并启用 SSH

1. 进入 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 选择对应的工作流（如 `OpenWrt-lede6`）
4. 点击 **Run workflow** 按钮
5. 在 **SSH connection to Actions** 输入框中输入 `true`
6. 点击 **Run workflow** 开始运行

### 2. 查看 SSH 连接信息

工作流运行后，在日志中找到 **"SSH链接管理"** 步骤，你会看到类似以下的信息：

```
🚀 SSH connection is ready!
📝 Connection information:
   Host: xxx.xxx.xxx.xxx
   Port: xxxxx
   User: runner
   Password: xxxxxxxxxxxxxx
   
To connect to this session copy and paste the following into a terminal:
ssh runner@xxx.xxx.xxx.xxx -p xxxxx
```

### 3. 连接方式

#### 方式一：使用 SSH 命令（推荐）

**Linux/macOS:**
```bash
ssh runner@<IP地址> -p <端口>
```

**Windows (PowerShell):**
```powershell
ssh runner@<IP地址> -p <端口>
```

**Windows (CMD):**
```cmd
ssh runner@<IP地址> -p <端口>
```

#### 方式二：使用 SSH 客户端（如 PuTTY）

1. 打开 PuTTY
2. 在 **Host Name** 输入：`<IP地址>`
3. 在 **Port** 输入：`<端口>`
4. 连接类型选择：**SSH**
5. 点击 **Open**
6. 用户名输入：`runner`
7. 密码输入：日志中显示的密码

### 4. 连接后可以做什么

连接成功后，你可以：

- **查看编译环境**：
  ```bash
  pwd
  ls -la
  df -hT
  ```

- **进入编译目录**：
  ```bash
  cd $GITHUB_WORKSPACE/openwrt
  # 或
  cd /workdir/openwrt
  ```

- **手动执行编译命令**：
  ```bash
  cd openwrt
  make menuconfig
  make -j$(nproc)
  ```

- **查看编译日志**：
  ```bash
  tail -f build.log
  ```

- **调试问题**：
  ```bash
  # 检查文件
  ls -la
  # 查看配置
  cat .config
  # 检查磁盘空间
  df -h
  ```

## ⚠️ 注意事项

1. **连接时效性**：
   - SSH 连接只在工作流运行期间有效
   - 工作流完成后，连接会自动断开
   - 建议在编译步骤之前或编译过程中连接

2. **安全性**：
   - SSH 密码是临时生成的，每次运行都不同
   - 连接信息只在工作流日志中显示
   - 不要将连接信息分享给他人

3. **Telegram 通知（可选）**：
   - 如果配置了 `TELEGRAM_CHAT_ID` 和 `TELEGRAM_BOT_TOKEN`
   - SSH 连接信息也会通过 Telegram 机器人发送
   - 方便在手机上查看连接信息

4. **连接位置**：
   - SSH 连接步骤在 "更改设置" 之后
   - 在 "下载安装包" 之前
   - 这是连接的最佳时机

## 🔧 配置 Telegram 通知（可选）

如果你想通过 Telegram 接收 SSH 连接信息：

1. 创建 Telegram Bot：
   - 在 Telegram 中搜索 `@BotFather`
   - 发送 `/newbot` 创建新机器人
   - 获取 Bot Token

2. 获取 Chat ID：
   - 在 Telegram 中搜索 `@userinfobot`
   - 发送任意消息获取你的 Chat ID

3. 在 GitHub 仓库中添加 Secrets：
   - 进入仓库 **Settings** → **Secrets and variables** → **Actions**
   - 添加 `TELEGRAM_CHAT_ID`（你的 Chat ID）
   - 添加 `TELEGRAM_BOT_TOKEN`（Bot Token）

## 📝 示例

### 完整的连接流程

1. **启动工作流**：
   ```
   Actions → OpenWrt-lede6 → Run workflow → ssh: true → Run workflow
   ```

2. **等待 SSH 步骤**：
   ```
   等待 "SSH链接管理" 步骤执行
   ```

3. **查看日志**：
   ```
   在 "SSH链接管理" 步骤的日志中查找连接信息
   ```

4. **连接**：
   ```bash
   ssh runner@xxx.xxx.xxx.xxx -p xxxxx
   # 输入密码（从日志中复制）
   ```

5. **开始调试**：
   ```bash
   cd $GITHUB_WORKSPACE/openwrt
   ls -la
   make menuconfig
   ```

## 🆘 常见问题

**Q: 找不到 SSH 连接信息？**
- A: 确保工作流已运行到 "SSH链接管理" 步骤
- A: 检查日志中是否有错误信息
- A: 确认 `ssh` 输入参数设置为 `true`

**Q: 连接被拒绝？**
- A: 检查 IP 地址和端口是否正确
- A: 确认工作流仍在运行中
- A: 尝试重新启动工作流

**Q: 密码输入后无法连接？**
- A: 密码可能包含特殊字符，尝试复制粘贴
- A: 检查密码是否完整（没有截断）
- A: 确认用户名是 `runner`

**Q: 连接后找不到文件？**
- A: 使用 `cd $GITHUB_WORKSPACE` 切换到工作空间
- A: 使用 `pwd` 查看当前目录
- A: 使用 `ls -la` 查看文件列表

## 📚 参考资源

- [P3TERX/ssh2actions GitHub](https://github.com/P3TERX/ssh2actions)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

