# BIRD权限配置说明

## 概述

本文档详细说明了IPv6 WireGuard Manager中BIRD BGP服务的权限配置，确保BIRD服务以正确的用户和组权限运行，提高系统安全性。

## 权限配置原则

### 1. 最小权限原则
- BIRD服务以专用用户`bird`运行，不使用root权限
- 限制BIRD进程的文件系统访问权限
- 使用systemd安全特性限制进程能力

### 2. 专用用户和组
- **用户名**: `bird`
- **组名**: `bird`
- **主目录**: `/var/lib/bird`
- **Shell**: `/bin/false` (禁止登录)

## 详细配置

### 1. 用户和组创建

```bash
# 创建bird用户
useradd -r -s /bin/false -d /var/lib/bird -c "BIRD BGP daemon" bird

# 创建bird组
groupadd -r bird

# 确保bird用户在bird组中
usermod -a -G bird bird
```

### 2. 目录权限设置

| 目录 | 所有者 | 权限 | 说明 |
|------|--------|------|------|
| `/etc/bird` | bird:bird | 755 | 配置文件目录 |
| `/var/lib/bird` | bird:bird | 755 | 数据目录 |
| `/var/log/bird` | bird:bird | 755 | 日志目录 |
| `/var/run/bird` | bird:bird | 755 | 运行时目录 |
| `/etc/bird/bird.conf.d` | bird:bird | 755 | 配置子目录 |

### 3. 文件权限设置

| 文件 | 所有者 | 权限 | 说明 |
|------|--------|------|------|
| `/etc/bird/bird.conf` | bird:bird | 644 | 主配置文件 |
| `/etc/bird/bird.conf.d/*.conf` | bird:bird | 644 | 子配置文件 |
| `/var/log/bird/bird.log` | bird:bird | 644 | 日志文件 |

### 4. systemd服务配置

```ini
[Unit]
Description=BIRD Internet Routing Daemon
Documentation=man:bird(8)
After=network.target
Wants=network.target

[Service]
Type=notify
User=bird
Group=bird
ExecStart=/usr/sbin/bird -f -u bird -g bird -c /etc/bird/bird.conf
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=on-failure
RestartSec=5
TimeoutStartSec=60
TimeoutStopSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/bird /var/log/bird /var/run/bird
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Network settings
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true

# Capabilities
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN

[Install]
WantedBy=multi-user.target
```

## 安全特性说明

### 1. systemd安全限制

- **NoNewPrivileges**: 禁止进程获取新权限
- **PrivateTmp**: 使用私有临时目录
- **ProtectSystem**: 保护系统目录只读
- **ProtectHome**: 保护用户主目录
- **ReadWritePaths**: 限制可写路径

### 2. 网络限制

- **RestrictAddressFamilies**: 限制网络地址族
- **RestrictNamespaces**: 禁止创建命名空间
- **RestrictRealtime**: 禁止实时调度
- **RestrictSUIDSGID**: 禁止SUID/SGID

### 3. 能力限制

- **CapabilityBoundingSet**: 限制进程能力
- **AmbientCapabilities**: 设置环境能力
- 仅允许网络管理相关能力

## 实现细节

### 1. 权限配置函数

```bash
configure_bird_permissions() {
    # 创建用户和组
    # 创建目录
    # 设置权限
    # 配置systemd服务
}
```

### 2. 配置文件创建

所有BIRD配置文件的创建都会自动设置正确的权限：

```bash
# 创建配置文件后设置权限
chown bird:bird "$config_file"
chmod 644 "$config_file"
```

### 3. 服务启动

BIRD服务启动时会：
1. 配置权限
2. 创建systemd服务文件
3. 启动服务

## 权限检查工具

### 1. 检查脚本

提供了专门的权限检查脚本：`scripts/check_bird_permissions.sh`

### 2. 检查项目

- 用户和组存在性
- 目录权限
- 文件权限
- systemd服务配置
- 进程运行用户

### 3. 自动修复

检查脚本支持自动修复权限问题：

```bash
sudo ./scripts/check_bird_permissions.sh
```

## 故障排除

### 1. 常见问题

#### 权限不足
```bash
# 错误: Permission denied
# 解决: 检查文件所有者是否为bird:bird
chown bird:bird /etc/bird/bird.conf
```

#### 服务启动失败
```bash
# 错误: Failed to start BIRD service
# 解决: 检查systemd服务配置
systemctl status bird
journalctl -u bird
```

#### 配置文件无法读取
```bash
# 错误: Cannot read configuration file
# 解决: 检查文件权限
ls -la /etc/bird/bird.conf
chmod 644 /etc/bird/bird.conf
```

### 2. 调试命令

```bash
# 检查BIRD进程
ps aux | grep bird

# 检查文件权限
ls -la /etc/bird/
ls -la /var/log/bird/
ls -la /var/lib/bird/

# 检查用户信息
id bird
groups bird

# 检查服务状态
systemctl status bird
systemctl show bird
```

## 最佳实践

### 1. 安装时配置
- 安装BIRD包后立即配置权限
- 创建专用用户和组
- 设置正确的目录和文件权限

### 2. 运行时监控
- 定期检查BIRD进程运行用户
- 监控权限变更
- 使用权限检查脚本

### 3. 安全更新
- 更新BIRD包后重新检查权限
- 备份权限配置
- 测试服务启动

## 兼容性说明

### 1. 支持的系统
- Ubuntu/Debian
- CentOS/RHEL/Fedora
- Rocky Linux/AlmaLinux
- Arch Linux

### 2. BIRD版本
- BIRD 2.x
- 支持systemd的系统

### 3. 权限模型
- 基于systemd的安全特性
- 遵循最小权限原则
- 兼容SELinux/AppArmor

## 总结

BIRD权限配置确保了：

✅ **安全性**: 以非root用户运行，限制系统访问
✅ **稳定性**: 正确的文件权限，避免权限冲突
✅ **可维护性**: 标准化的权限配置，易于管理
✅ **兼容性**: 支持主流Linux发行版
✅ **可监控性**: 提供权限检查工具

通过正确的权限配置，BIRD服务可以安全、稳定地运行，同时保持系统的整体安全性。
