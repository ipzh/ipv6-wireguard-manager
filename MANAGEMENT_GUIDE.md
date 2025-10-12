# IPv6 WireGuard Manager 管理指南

## 📋 概述

本指南介绍IPv6 WireGuard Manager安装后的日常管理和维护操作。

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
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
```

#### 启动服务
```bash
./manage.sh start
# 或
sudo systemctl start ipv6-wireguard-manager
sudo systemctl start nginx
```

#### 停止服务
```bash
./manage.sh stop
# 或
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl stop nginx
```

#### 重启服务
```bash
./manage.sh restart
# 或
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl restart nginx
```

### 2. 日志管理

#### 查看日志
```bash
# 使用管理脚本
./manage.sh logs

# 手动查看
sudo journalctl -u ipv6-wireguard-manager -f
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

#### 日志类型
- **后端服务日志**: `sudo journalctl -u ipv6-wireguard-manager`
- **Nginx错误日志**: `/var/log/nginx/error.log`
- **Nginx访问日志**: `/var/log/nginx/access.log`
- **系统日志**: `sudo journalctl`

### 3. 监控和健康检查

#### 健康检查
```bash
./manage.sh health
```

检查项目包括：
- 服务运行状态
- 端口监听状态
- API响应测试
- 前端访问测试
- IPv6访问测试

#### 实时监控
```bash
./manage.sh monitor
```

监控选项：
- 服务状态监控
- 日志实时监控
- 系统资源监控
- 网络连接监控

### 4. 配置管理

#### 查看配置
```bash
./manage.sh config
```

#### 主要配置文件
- **环境配置**: `/opt/ipv6-wireguard-manager/backend/.env`
- **Nginx配置**: `/etc/nginx/sites-available/ipv6-wireguard-manager`
- **systemd服务**: `/etc/systemd/system/ipv6-wireguard-manager.service`

#### 重新加载配置
```bash
# 重新加载systemd配置
sudo systemctl daemon-reload

# 测试并重新加载Nginx配置
sudo nginx -t
sudo systemctl reload nginx

# 重启后端服务
sudo systemctl restart ipv6-wireguard-manager
```

### 5. 数据备份和恢复

#### 备份数据
```bash
./manage.sh backup
```

备份内容包括：
- 应用文件
- 数据库数据
- 配置文件

#### 恢复数据
```bash
./manage.sh restore
```

### 6. 应用更新

#### 更新应用
```bash
./manage.sh update
```

更新流程：
1. 停止服务
2. 备份当前配置
3. 更新应用代码
4. 更新依赖
5. 重启服务

## 🌐 访问管理

### 查看访问地址
```bash
./manage.sh access
```

### 访问地址类型
- **本地访问**: `http://localhost`
- **IPv4访问**: `http://您的IPv4地址`
- **IPv6访问**: `http://[您的IPv6地址]`
- **公网访问**: 根据您的网络配置

### 默认登录信息
- **用户名**: admin
- **密码**: admin123

## 🔍 故障排除

### 常见问题

#### 1. 服务无法启动
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看详细日志
sudo journalctl -u ipv6-wireguard-manager -n 50

# 检查端口占用
ss -tlnp | grep :8000
```

#### 2. 500 Internal Server Error
```bash
# 运行快速修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/quick-fix-500.sh | bash

# 或运行详细诊断
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-500-error.sh | bash
```

#### 3. IPv6访问问题
```bash
# 检查IPv6状态
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/check-ipv6-status.sh | bash

# 配置IPv6访问
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/configure-ipv6-access.sh | bash
```

#### 4. 权限问题
```bash
# 修复权限
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager
```

### 诊断命令

#### 检查服务状态
```bash
# 服务状态
sudo systemctl status ipv6-wireguard-manager nginx

# 端口监听
ss -tlnp | grep -E ":(80|8000)"

# 进程状态
ps aux | grep -E "(uvicorn|nginx)"
```

#### 检查网络连接
```bash
# 测试本地API
curl http://127.0.0.1:8000/health

# 测试前端访问
curl http://localhost

# 测试IPv6访问
curl -6 http://[您的IPv6地址]/api/v1/status
```

#### 检查日志
```bash
# 后端服务日志
sudo journalctl -u ipv6-wireguard-manager --since "1 hour ago"

# Nginx错误日志
sudo tail -50 /var/log/nginx/error.log

# 系统日志
sudo journalctl --since "1 hour ago" | grep -i error
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

# 查看数据库连接
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
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

### 紧急修复
```bash
# 快速修复500错误
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/quick-fix-500.sh | bash

# 完整修复
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/final-fix.sh | bash
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
