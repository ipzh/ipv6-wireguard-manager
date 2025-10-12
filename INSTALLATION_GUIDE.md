# IPv6 WireGuard Manager 安装指南

## 📋 安装脚本概述

我们提供了多个安装脚本来满足不同的安装需求，每个脚本都整合了构造过程中出现的所有问题解决方案。

### 🚀 安装脚本选择

| 脚本名称 | 用途 | 适用场景 |
|---------|------|----------|
| `install.sh` | 主安装脚本 | 智能选择安装方式，推荐使用 |
| `install-complete.sh` | 完整安装脚本 | 需要特定安装类型时使用 |
| `quick-install.sh` | 快速安装脚本 | 快速部署，适合熟悉环境的用户 |
| `fix-installation-issues.sh` | 问题修复脚本 | 安装后遇到问题时使用 |

## 🎯 推荐安装方式

### 1. 一键安装（推荐）

```bash
# 下载并运行主安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者指定安装类型
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s docker
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s native
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s low-memory
```

### 2. 本地安装

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行安装脚本
chmod +x install.sh
./install.sh
```

## 🔧 安装类型说明

### Docker 安装
- **优点**: 环境隔离，易于管理，支持一键部署
- **缺点**: 资源占用较高，性能略有损失
- **适用**: 测试环境、开发环境、对性能要求不高的场景
- **内存需求**: 2GB+

### 原生安装
- **优点**: 性能最优，资源占用最小，启动速度快
- **缺点**: 需要手动管理依赖，环境配置相对复杂
- **适用**: 生产环境、VPS部署、对性能要求高的场景
- **内存需求**: 1GB+

### 低内存安装
- **优点**: 专为1GB内存优化，包含swap创建和内存优化
- **缺点**: 功能可能受限
- **适用**: 资源受限的VPS、测试环境
- **内存需求**: 512MB+

## 🛠️ 安装选项

### 主安装脚本选项

```bash
./install.sh [安装类型] [选项]

安装类型:
  docker      - Docker 安装
  native      - 原生安装
  low-memory  - 低内存优化安装

选项:
  --force     - 强制重新安装
  --skip-deps - 跳过依赖检查
  --auto      - 自动模式（非交互式）
```

### 完整安装脚本选项

```bash
./install-complete.sh [安装类型] [选项]

安装类型:
  docker      - Docker 安装
  native      - 原生安装
  low-memory  - 低内存优化安装

选项:
  --force     - 强制重新安装
  --skip-deps - 跳过依赖检查
```

### 快速安装脚本

```bash
./quick-install.sh
# 无参数，自动检测环境并安装
```

## 🔍 智能安装选择

安装脚本会自动检测系统环境并选择最适合的安装方式：

- **内存 < 1GB**: 自动选择低内存安装
- **WSL环境**: 自动选择原生安装
- **内存 < 2GB**: 自动选择原生安装
- **内存 ≥ 2GB**: 自动选择Docker安装

## 🚨 常见问题解决

### 1. Docker相关问题

```bash
# 修复Docker仓库配置问题
./fix-installation-issues.sh docker

# 修复Docker Compose问题
./fix-installation-issues.sh docker-compose
```

**常见问题**:
- Docker仓库配置错误
- Docker Compose命令不可用
- 权限问题

### 2. 前端构建问题

```bash
# 修复前端构建问题
./fix-installation-issues.sh frontend
```

**常见问题**:
- Node.js版本过低
- 内存不足导致构建失败
- 依赖安装失败

### 3. 数据库问题

```bash
# 修复数据库问题
./fix-installation-issues.sh database
```

**常见问题**:
- PostgreSQL认证失败
- 数据库连接问题
- 权限配置错误

### 4. 后端启动问题

```bash
# 修复后端启动问题
./fix-installation-issues.sh backend
```

**常见问题**:
- Python依赖问题
- Pydantic兼容性问题
- 环境配置错误

### 5. Nginx配置问题

```bash
# 修复Nginx配置问题
./fix-installation-issues.sh nginx
```

**常见问题**:
- 配置文件错误
- 权限问题
- 端口冲突

### 6. 全面修复

```bash
# 修复所有已知问题
./fix-installation-issues.sh all
```

## 📊 系统要求

### 最低要求
- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+
- **内存**: 512MB (低内存安装)
- **磁盘**: 2GB 可用空间
- **网络**: 稳定的互联网连接

### 推荐配置
- **操作系统**: Ubuntu 20.04+, Debian 11+
- **内存**: 2GB+
- **磁盘**: 10GB+ 可用空间
- **CPU**: 2核心+

## 🔐 安全配置

安装完成后，系统会自动配置：

- **防火墙规则**: 允许SSH、HTTP/HTTPS、WireGuard端口
- **用户权限**: 创建专用系统用户
- **数据库安全**: 配置PostgreSQL认证
- **服务隔离**: 使用systemd管理服务

## 📝 安装后配置

### 1. 访问系统

安装完成后，您可以通过以下方式访问：

- **前端界面**: http://your-server-ip
- **后端API**: http://your-server-ip:8000
- **API文档**: http://your-server-ip:8000/docs

### 2. 默认登录信息

- **用户名**: admin
- **密码**: admin123

### 3. 服务管理

```bash
# 查看服务状态
systemctl status ipv6-wireguard-manager

# 重启服务
systemctl restart ipv6-wireguard-manager

# 查看日志
journalctl -u ipv6-wireguard-manager -f

# 停止服务
systemctl stop ipv6-wireguard-manager

# 启动服务
systemctl start ipv6-wireguard-manager
```

## 🔄 更新和升级

### 更新系统

```bash
# 拉取最新代码
cd /opt/ipv6-wireguard-manager
git pull origin main

# 重启服务
systemctl restart ipv6-wireguard-manager
```

### 重新安装

```bash
# 强制重新安装
./install.sh --force

# 或者使用修复脚本
./fix-installation-issues.sh all
```

## 🆘 故障排除

### 1. 检查服务状态

```bash
# 检查所有相关服务
systemctl status nginx postgresql redis-server ipv6-wireguard-manager

# 检查端口监听
netstat -tlnp | grep -E ':(80|8000|5432|6379)'
```

### 2. 查看日志

```bash
# 查看后端日志
journalctl -u ipv6-wireguard-manager -f

# 查看Nginx日志
tail -f /var/log/nginx/error.log

# 查看PostgreSQL日志
tail -f /var/log/postgresql/postgresql-*.log
```

### 3. 测试连接

```bash
# 测试后端API
curl http://127.0.0.1:8000/health

# 测试前端
curl http://127.0.0.1/

# 测试数据库连接
sudo -u postgres psql -c "SELECT version();"
```

## 📞 获取帮助

如果您在安装过程中遇到问题：

1. **查看日志**: 检查安装日志和错误信息
2. **运行修复脚本**: 使用 `./fix-installation-issues.sh`
3. **检查系统要求**: 确保满足最低系统要求
4. **查看文档**: 参考项目文档和FAQ
5. **提交Issue**: 在GitHub上提交问题报告

## 🎉 安装完成

安装完成后，您将拥有一个功能完整的IPv6 WireGuard管理系统，包括：

- ✅ BGP会话和宣告管理
- ✅ IPv6前缀池管理
- ✅ WireGuard服务器和客户端管理
- ✅ 实时监控和告警
- ✅ 用户管理和权限控制
- ✅ 系统设置和配置管理

开始使用您的IPv6 WireGuard Manager吧！
