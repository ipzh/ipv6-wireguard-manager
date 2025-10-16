# IPv6 WireGuard Manager - CLI管理工具指南

## 📋 概述

IPv6 WireGuard Manager CLI 是一个功能强大的命令行管理工具，提供了完整的服务管理、系统监控、备份恢复等功能。安装完成后，您可以在任何地方使用 `ipv6-wireguard-manager` 命令来管理系统。

## 🚀 快速开始

### 基本用法

```bash
ipv6-wireguard-manager <命令> [选项]
```

### 查看帮助

```bash
# 显示所有可用命令
ipv6-wireguard-manager help

# 显示版本信息
ipv6-wireguard-manager version
```

## 🔧 服务管理命令

### 启动服务

```bash
ipv6-wireguard-manager start
```

**功能**:
- 启动IPv6 WireGuard Manager后端服务
- 自动检查服务状态
- 等待服务完全启动并验证

**示例输出**:
```
[INFO] 启动IPv6 WireGuard Manager服务...
[SUCCESS] 服务启动成功
[SUCCESS] 服务运行正常
```

### 停止服务

```bash
ipv6-wireguard-manager stop
```

**功能**:
- 安全停止IPv6 WireGuard Manager服务
- 检查服务状态确认停止

**示例输出**:
```
[INFO] 停止IPv6 WireGuard Manager服务...
[SUCCESS] 服务停止成功
```

### 重启服务

```bash
ipv6-wireguard-manager restart
```

**功能**:
- 重启IPv6 WireGuard Manager服务
- 自动验证重启后的服务状态

**示例输出**:
```
[INFO] 重启IPv6 WireGuard Manager服务...
[SUCCESS] 服务重启成功
[SUCCESS] 服务运行正常
```

### 查看状态

```bash
ipv6-wireguard-manager status
```

**功能**:
- 显示详细的服务状态信息
- 检查端口监听状态
- 测试API连接
- 显示systemd服务状态

**示例输出**:
```
[INFO] IPv6 WireGuard Manager 服务状态
==================================================
[SUCCESS] ✓ 服务正在运行

详细状态:
● ipv6-wireguard-manager.service - IPv6 WireGuard Manager Backend
     Loaded: loaded (/etc/systemd/system/ipv6-wireguard-manager.service; enabled)
     Active: active (running) since Thu 2025-10-16 01:26:34 EDT

端口监听状态:
tcp6       0      0 :::8000                 :::*                    LISTEN      17408/python3.11

API连接测试:
[SUCCESS] ✓ API连接正常
```

## 📊 系统管理命令

### 查看日志

```bash
# 查看最近50行日志
ipv6-wireguard-manager logs

# 查看最近100行日志
ipv6-wireguard-manager logs -n 100

# 实时查看日志
ipv6-wireguard-manager logs -f
```

**选项**:
- `-n, --lines N`: 显示最近N行日志 (默认50)
- `-f, --follow`: 实时跟踪日志 (按Ctrl+C退出)

**示例输出**:
```
[INFO] 显示最近 50 行服务日志:
Oct 16 01:26:34 VM117 systemd[1]: Starting ipv6-wireguard-manager.service...
Oct 16 01:26:34 VM117 systemd[1]: Started ipv6-wireguard-manager.service.
Oct 16 01:26:35 VM117 uvicorn[17408]: INFO: Started server process [17408]
Oct 16 01:26:35 VM117 uvicorn[17408]: INFO: Waiting for application startup.
Oct 16 01:26:35 VM117 uvicorn[17408]: INFO: Application startup complete.
```

### 更新系统

```bash
ipv6-wireguard-manager update
```

**功能**:
- 自动停止服务
- 备份当前配置
- 拉取最新代码
- 更新Python依赖
- 重启服务

**示例输出**:
```
[INFO] 更新IPv6 WireGuard Manager系统...
[INFO] 停止服务...
[SUCCESS] ✓ 服务已停止
[INFO] 备份当前配置...
[INFO] 拉取最新代码...
[SUCCESS] ✓ 代码更新完成
[INFO] 更新Python依赖...
[SUCCESS] ✓ 依赖更新完成
[INFO] 重启服务...
[SUCCESS] ✓ 服务启动成功
[SUCCESS] 系统更新完成
```

### 创建备份

```bash
# 创建自动命名备份
ipv6-wireguard-manager backup

# 创建命名备份
ipv6-wireguard-manager backup --name daily-backup
```

**功能**:
- 备份配置文件
- 备份应用代码
- 备份数据库
- 创建备份信息文件

**示例输出**:
```
[INFO] 创建备份: daily-backup
[INFO] 备份数据库...
[SUCCESS] 数据库备份完成
[SUCCESS] 备份创建完成: /opt/ipv6-wireguard-manager/backups/daily-backup
```

**备份内容**:
- `.env` - 环境配置文件
- `backend/` - 后端应用代码
- `php-frontend/` - 前端应用代码
- `database.sql` - 数据库备份
- `backup_info.json` - 备份信息

### 系统监控

```bash
ipv6-wireguard-manager monitor
```

**功能**:
- 显示系统资源使用情况
- 检查服务运行状态
- 显示端口监听状态
- 测试API服务状态
- 检查数据库连接

**示例输出**:
```
[INFO] IPv6 WireGuard Manager 系统监控
==================================================

系统资源:
              total        used        free      shared  buff/cache   available
Mem:           1.9G        456M        234M         12M        1.2G        1.3G
Swap:          2.0G          0B        2.0G

Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G  3.2G   16G  17% /

服务状态:
[SUCCESS] ✓ IPv6 WireGuard Manager 运行中

端口状态:
tcp6       0      0 :::80                   :::*                    LISTEN      0/nginx
tcp6       0      0 :::8000                 :::*                    LISTEN      17408/python3.11

API状态:
[SUCCESS] ✓ API服务正常
  版本: 3.1.0
  状态: healthy

数据库状态:
[SUCCESS] ✓ 数据库连接正常
```

## 🎯 高级用法

### 组合命令

```bash
# 重启服务并查看状态
ipv6-wireguard-manager restart && ipv6-wireguard-manager status

# 创建备份并显示监控信息
ipv6-wireguard-manager backup --name pre-update && ipv6-wireguard-manager monitor
```

### 脚本集成

```bash
#!/bin/bash
# 自动备份脚本

# 创建每日备份
ipv6-wireguard-manager backup --name "daily-$(date +%Y%m%d)"

# 检查服务状态
if ! ipv6-wireguard-manager status > /dev/null 2>&1; then
    echo "服务异常，尝试重启..."
    ipv6-wireguard-manager restart
fi
```

### 监控脚本

```bash
#!/bin/bash
# 系统监控脚本

# 显示监控信息
ipv6-wireguard-manager monitor

# 如果API不可用，重启服务
if ! curl -f http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    echo "API不可用，重启服务..."
    ipv6-wireguard-manager restart
fi
```

## 🔍 故障排除

### 常见问题

#### 1. 命令未找到

**错误**: `ipv6-wireguard-manager: command not found`

**解决方案**:
```bash
# 检查CLI工具是否安装
ls -la /usr/local/bin/ipv6-wireguard-manager

# 如果不存在，重新安装
sudo cp /opt/ipv6-wireguard-manager/ipv6-wireguard-manager /usr/local/bin/
sudo chmod +x /usr/local/bin/ipv6-wireguard-manager
```

#### 2. 权限不足

**错误**: `Permission denied`

**解决方案**:
```bash
# 检查文件权限
ls -la /usr/local/bin/ipv6-wireguard-manager

# 修复权限
sudo chmod +x /usr/local/bin/ipv6-wireguard-manager
```

#### 3. 服务启动失败

**错误**: 服务状态显示失败

**解决方案**:
```bash
# 查看详细日志
ipv6-wireguard-manager logs -n 100

# 检查系统资源
ipv6-wireguard-manager monitor

# 尝试手动重启
ipv6-wireguard-manager restart
```

### 调试模式

```bash
# 查看详细的服务状态
ipv6-wireguard-manager status

# 实时查看日志
ipv6-wireguard-manager logs -f

# 检查系统监控
ipv6-wireguard-manager monitor
```

## 📚 相关文档

- [安装指南](INSTALLATION_GUIDE.md)
- [服务故障排除](SERVICE_TROUBLESHOOTING.md)
- [API文档](API_REFERENCE.md)
- [用户手册](docs/USER_MANUAL.md)

## 🆘 获取帮助

如果遇到问题：

1. 查看帮助信息：`ipv6-wireguard-manager help`
2. 检查服务状态：`ipv6-wireguard-manager status`
3. 查看服务日志：`ipv6-wireguard-manager logs`
4. 运行系统监控：`ipv6-wireguard-manager monitor`
5. 提交问题到GitHub Issues

---

**CLI管理工具指南** - 轻松管理IPv6 WireGuard Manager！🔧
