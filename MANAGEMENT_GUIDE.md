# IPv6 WireGuard Manager 管理指南

## 📋 概述

本指南介绍IPv6 WireGuard Manager的日常管理和维护操作。

## 🚀 快速开始

### 下载管理脚本

```bash
# 下载管理脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/manage.sh -o manage.sh
chmod +x manage.sh

# 或者直接使用
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/manage.sh | bash -s status
```

### 基本用法

```bash
# 查看帮助
./manage.sh help

# 查看服务状态
./manage.sh status

# 查看访问地址
./manage.sh access

# 健康检查
./manage.sh health
```

## 🔧 日常管理操作

### 1. 服务管理

#### 查看服务状态
```bash
./manage.sh status
# 或
sudo systemctl status ipv6-wireguard-manager nginx
```

#### 启动/停止/重启服务
```bash
./manage.sh start    # 启动服务
./manage.sh stop     # 停止服务
./manage.sh restart  # 重启服务
```

### 2. 日志管理

#### 查看日志
```bash
# 使用管理脚本
./manage.sh logs

# 手动查看
sudo journalctl -u ipv6-wireguard-manager -f
sudo tail -f /var/log/nginx/error.log
```

### 3. 监控和健康检查

#### 健康检查
```bash
./manage.sh health
```

#### 实时监控
```bash
./manage.sh monitor
```

### 4. 配置管理

#### 查看和编辑配置
```bash
./manage.sh config
```

#### 主要配置文件
- **环境配置**: `/opt/ipv6-wireguard-manager/backend/.env`
- **Nginx配置**: `/etc/nginx/sites-available/ipv6-wireguard-manager`
- **systemd服务**: `/etc/systemd/system/ipv6-wireguard-manager.service`

### 5. 数据备份和恢复

```bash
./manage.sh backup   # 备份数据
./manage.sh restore  # 恢复数据
```

### 6. 应用更新

```bash
./manage.sh update
```

## 🌐 访问管理

### 查看访问地址
```bash
./manage.sh access
```

### 访问地址类型
- **本地访问**: `http://localhost`
- **IPv4访问**: `http://您的IPv4地址`
- **IPv6访问**: `http://[您的IPv6地址]`

### 默认登录信息
- **用户名**: admin
- **密码**: admin123

## 🔍 故障排除

### 快速修复

```bash
# 修复常见问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-common-issues.sh | bash

# 验证安装状态
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/verify-installation.sh | bash
```

### 常见问题

#### 1. 服务无法启动
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看详细日志
sudo journalctl -u ipv6-wireguard-manager -n 50
```

#### 2. 前端访问异常
```bash
# 检查前端文件
ls -la /opt/ipv6-wireguard-manager/frontend/dist/

# 重新构建前端
cd /opt/ipv6-wireguard-manager/frontend
npm run build
```

#### 3. IPv6访问问题
```bash
# 检查IPv6地址
ip -6 addr show

# 检查IPv6监听
ss -tlnp | grep :80 | grep "::"
```

## 🔐 安全建议

### 1. 更改默认密码
```bash
# 编辑环境配置文件
sudo nano /opt/ipv6-wireguard-manager/backend/.env

# 修改以下配置
FIRST_SUPERUSER=您的用户名
FIRST_SUPERUSER_PASSWORD=您的强密码
```

### 2. 配置防火墙
```bash
# 开放必要端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp

# 启用防火墙
sudo ufw enable
```

### 3. 定期更新
```bash
# 定期运行更新
./manage.sh update

# 或手动更新
cd /opt/ipv6-wireguard-manager
git pull origin main
sudo systemctl restart ipv6-wireguard-manager
```

## 📊 性能监控

### 系统资源监控
```bash
# CPU和内存使用
htop

# 磁盘使用
df -h

# 网络连接
ss -tuln
```

### 应用性能监控
```bash
# 查看服务资源使用
sudo systemctl status ipv6-wireguard-manager

# 查看Nginx状态
sudo nginx -s status
```

## 📅 维护计划

### 日常维护
- 检查服务状态
- 查看错误日志
- 监控系统资源

### 每周维护
- 备份数据
- 检查磁盘空间
- 更新系统包

### 每月维护
- 更新应用
- 检查安全配置
- 性能优化

## 🆘 获取帮助

### 在线资源
- **GitHub仓库**: https://github.com/ipzh/ipv6-wireguard-manager
- **问题报告**: https://github.com/ipzh/ipv6-wireguard-manager/issues

### 本地帮助
```bash
# 查看管理脚本帮助
./manage.sh help

# 查看服务状态
./manage.sh status

# 健康检查
./manage.sh health
```

## 📝 总结

通过本管理指南，您可以：

1. **日常管理**: 启动、停止、重启服务
2. **监控维护**: 查看日志、健康检查、性能监控
3. **配置管理**: 修改配置、重新加载
4. **数据管理**: 备份、恢复数据
5. **故障排除**: 诊断和修复问题
6. **安全维护**: 更新、安全配置

使用管理脚本 `./manage.sh` 可以简化大部分操作，建议定期运行健康检查以确保服务正常运行。