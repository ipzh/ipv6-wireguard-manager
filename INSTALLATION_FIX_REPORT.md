# 安装脚本404错误修复报告

## 🚨 问题描述

用户在尝试安装IPv6 WireGuard Manager时遇到404错误：

```bash
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
# 错误: 404 Not Found
```

## 🔍 问题分析

### 根本原因
- **错误的分支名**: 用户使用了 `main` 分支，但仓库实际使用 `master` 分支
- **文件存在**: `install.sh` 文件确实存在于仓库中
- **分支不匹配**: GitHub仓库默认分支是 `master`，不是 `main`

### 验证结果
- ✅ **文件存在**: `install.sh` 文件存在于本地仓库
- ✅ **文件大小**: 56,021 字节，文件完整
- ✅ **提交状态**: 文件已提交到远程仓库
- ❌ **分支错误**: 用户使用了错误的分支名

## 🔧 修复方案

### 方案1: 使用正确的分支名
```bash
# 正确的安装命令
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh | bash
```

### 方案2: 手动下载安装
```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh

# 设置执行权限
chmod +x install.sh

# 运行安装脚本
sudo ./install.sh
```

### 方案3: 克隆仓库安装
```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git

# 进入目录
cd ipv6-wireguard-manager

# 运行安装脚本
sudo ./install.sh
```

## 📋 正确的安装命令

### 一键安装（推荐）
```bash
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh | bash
```

### 分步安装
```bash
# 1. 下载安装脚本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh

# 2. 设置执行权限
chmod +x install.sh

# 3. 运行安装脚本
sudo ./install.sh
```

### 克隆安装
```bash
# 1. 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git

# 2. 进入目录
cd ipv6-wireguard-manager

# 3. 运行安装脚本
sudo ./install.sh
```

## 🎯 验证安装

### 检查文件存在
```bash
# 验证文件可访问
curl -I https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh
# 应该返回 200 OK
```

### 检查文件内容
```bash
# 查看文件前几行
curl -s https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh | head -10
```

## 📊 仓库状态

### 当前状态
- **仓库名**: ipzh/ipv6-wireguard-manager
- **默认分支**: master
- **文件状态**: install.sh 存在且完整
- **最新提交**: 1f6266c - "test: 触发GitHub Actions CI/CD测试"

### 文件信息
- **文件名**: install.sh
- **文件大小**: 56,021 字节
- **文件类型**: Shell脚本
- **执行权限**: 需要设置

## 🚀 安装流程

### 1. 下载安装脚本
```bash
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh -o install.sh
```

### 2. 设置执行权限
```bash
chmod +x install.sh
```

### 3. 运行安装脚本
```bash
sudo ./install.sh
```

### 4. 选择安装选项
- 快速安装: `sudo ./install.sh --quick`
- 自定义安装: `sudo ./install.sh --custom`
- 帮助信息: `sudo ./install.sh --help`

## ✅ 解决方案总结

### 问题原因
- 用户使用了错误的分支名 `main` 而不是 `master`
- GitHub仓库默认分支是 `master`

### 解决方法
- 使用正确的分支名 `master`
- 或者使用克隆仓库的方式安装

### 推荐命令
```bash
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh | bash
```

## 📝 用户指导

### 对于用户
1. 使用正确的分支名 `master`
2. 确保网络连接正常
3. 使用sudo权限运行安装脚本

### 对于开发者
1. 考虑将默认分支改为 `main` 以符合现代GitHub实践
2. 在README中提供正确的安装命令
3. 添加安装验证步骤

## 🎉 总结

问题已解决！用户只需要使用正确的分支名 `master` 即可成功安装IPv6 WireGuard Manager。

**正确的安装命令**:
```bash
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh | bash
```
