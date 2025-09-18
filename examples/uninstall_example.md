# IPv6 WireGuard Manager 卸载功能示例

## 概述

IPv6 WireGuard Manager 现在提供了强大的卸载功能，支持三种不同的卸载模式，可以满足不同用户的需求。

## 卸载模式

### 1. 标准卸载 (推荐)

**适用场景**: 只想删除管理程序，保留 WireGuard 和 BIRD 配置

**删除内容**:
- IPv6 WireGuard Manager 程序文件
- 管理配置文件
- 日志文件
- 备份文件
- 系统服务
- 符号链接

**保留内容**:
- WireGuard 配置 (`/etc/wireguard/`)
- BIRD BGP 配置 (`/etc/bird/`)
- 客户端配置 (`/etc/wireguard/clients/`)
- 防火墙规则

**使用方法**:
```bash
sudo ./uninstall.sh
# 选择: 1. 标准卸载 (推荐)
```

### 2. 完全卸载

**适用场景**: 完全清理所有相关组件

**删除内容**:
- 所有程序文件
- 所有配置文件
- WireGuard 配置和客户端
- BIRD BGP 配置
- 防火墙规则 (IPv6 WireGuard 相关)
- 所有日志和备份文件

**使用方法**:
```bash
sudo ./uninstall.sh
# 选择: 2. 完全卸载
```

### 3. 自定义卸载

**适用场景**: 精确控制要删除的组件

**可选组件**:
- WireGuard 配置和客户端
- BIRD BGP 配置
- 防火墙规则
- 客户端配置目录
- 所有日志文件
- 所有备份文件

**使用方法**:
```bash
sudo ./uninstall.sh
# 选择: 3. 自定义卸载
# 然后选择要删除的具体组件
```

## 功能特性

### 智能路径检测
- 自动检测安装目录
- 动态识别配置文件位置
- 支持多种安装方式

### 安全确认机制
- 双重确认防止误操作
- 详细显示将要删除的内容
- 清晰显示保留的内容

### 完整服务管理
- 停止相关服务
- 禁用系统服务
- 删除服务文件
- 清理符号链接

### 多平台支持
- 支持 Ubuntu/Debian (apt)
- 支持 CentOS/RHEL (yum/dnf)
- 支持 Arch Linux (pacman)
- 支持多种防火墙 (UFW/firewalld/iptables)

## 使用示例

### 示例1: 标准卸载

```bash
# 运行卸载脚本
sudo ./uninstall.sh

# 输出示例:
# ╔══════════════════════════════════════════════════════════════╗
# ║                IPv6 WireGuard Manager                      ║
# ║                    卸载程序 v1.0.5                         ║
# ╚══════════════════════════════════════════════════════════════╝
# 
# 请选择卸载模式:
# 
#   1. 标准卸载 (推荐)
#      • 删除 IPv6 WireGuard Manager 程序文件
#      • 删除管理配置文件
#      • 保留 WireGuard 和 BIRD 配置
#      • 保留客户端配置
# 
#   2. 完全卸载
#   3. 自定义卸载
#   0. 取消卸载
# 
# 请选择卸载模式 (0-3): 1
```

### 示例2: 完全卸载

```bash
# 选择完全卸载
sudo ./uninstall.sh

# 输出示例:
# 标准卸载 - 将要删除的内容:
#   • 程序文件: /opt/ipv6-wireguard-manager
#   • 管理配置: /etc/ipv6-wireguard
#   • 日志文件: /var/log/ipv6-wireguard
#   • 备份文件: /var/backups/ipv6-wireguard
#   • 系统服务: ipv6-wireguard-manager
#   • 符号链接: /usr/local/bin/ipv6-wg-manager
#   • 符号链接: /usr/local/bin/wg-manager
#   • WireGuard 配置: /etc/wireguard/
#   • BIRD BGP 配置: /etc/bird/
#   • 客户端配置: /etc/wireguard/clients/
#   • 防火墙规则 (IPv6 WireGuard 相关)
# 
# 此操作不可逆!
# 
# 确定要卸载 IPv6 WireGuard Manager 吗? (y/N): y
# 此操作不可逆，请再次确认 (y/N): y
```

### 示例3: 自定义卸载

```bash
# 选择自定义卸载
sudo ./uninstall.sh

# 输出示例:
# 请选择要删除的组件:
# 
#   1. WireGuard 配置和客户端
#   2. BIRD BGP 配置
#   3. 防火墙规则
#   4. 客户端配置目录
#   5. 所有日志文件
#   6. 所有备份文件
# 
#   0. 完成选择
# 
# 请选择要删除的组件 (0-6): 1
# ✓ 已选择 WireGuard
# 请选择要删除的组件 (0-6): 3
# ✓ 已选择防火墙规则
# 请选择要删除的组件 (0-6): 0
```

## 卸载过程

### 1. 服务停止
```bash
[INFO] Stopping services...
[INFO] Stopped ipv6-wireguard-manager service
[INFO] Stopped WireGuard service
[INFO] Stopped BIRD service
✓ 服务已停止
```

### 2. 服务禁用
```bash
[INFO] Disabling services...
[INFO] Disabled ipv6-wireguard-manager service
✓ 服务已禁用
```

### 3. 文件删除
```bash
[INFO] Removing system service...
[INFO] Removed system service file
✓ 系统服务已删除

[INFO] Removing symbolic links...
[INFO] Removed symbolic link: /usr/local/bin/ipv6-wg-manager
[INFO] Removed symbolic link: /usr/local/bin/wg-manager
✓ 符号链接已删除

[INFO] Removing installation directory...
[INFO] Removed installation directory: /opt/ipv6-wireguard-manager
✓ 安装目录已删除
```

### 4. 组件卸载 (完全卸载模式)
```bash
[INFO] Uninstalling WireGuard...
[INFO] Stopped WireGuard service
[INFO] Disabled WireGuard service
[INFO] Removed WireGuard configuration
✓ WireGuard 已完全卸载

[INFO] Uninstalling BIRD BGP...
[INFO] Stopped BIRD service
[INFO] Disabled BIRD service
[INFO] Removed BIRD configuration
✓ BIRD BGP 已完全卸载

[INFO] Cleaning up firewall rules...
[INFO] Cleaned UFW rules
[INFO] Cleaned firewalld rules
[INFO] Cleaned iptables rules
✓ 防火墙规则已清理
```

## 卸载完成

### 标准卸载完成
```bash
╔══════════════════════════════════════════════════════════════╗
║                卸载完成!                                  ║
╚══════════════════════════════════════════════════════════════╝

✓ IPv6 WireGuard Manager 卸载成功!

以下文件被保留:
  WireGuard 配置: /etc/wireguard/
    - wg0.conf (服务器配置)
  BIRD BGP 配置: /etc/bird/bird.conf
  防火墙配置: UFW 规则
  客户端配置: /etc/wireguard/clients/ (3 个客户端)

后续操作:
  • 如需重新安装，请运行安装脚本
  • 如需完全清理，请手动删除保留的文件
  • 如需停止 WireGuard 服务，请运行: systemctl stop wg-quick@wg0
  • 如需停止 BIRD 服务，请运行: systemctl stop bird

感谢使用 IPv6 WireGuard Manager!
```

## 安全特性

### 1. 权限检查
- 必须使用 root 权限运行
- 自动检查权限并提示

### 2. 确认机制
- 双重确认防止误操作
- 详细显示删除内容
- 清晰显示保留内容

### 3. 日志记录
- 详细记录卸载过程
- 保存到 `/var/log/ipv6-wireguard-uninstall.log`
- 便于问题排查

### 4. 错误处理
- 优雅处理各种错误情况
- 继续执行其他卸载步骤
- 提供详细的错误信息

## 故障排除

### 问题1: 权限不足
```bash
[ERROR] This script must be run as root
```
**解决**: 使用 `sudo` 运行脚本

### 问题2: 服务停止失败
```bash
[WARN] Failed to stop service, continuing...
```
**解决**: 脚本会继续执行，可以手动停止服务

### 问题3: 文件删除失败
```bash
[WARN] Failed to remove file, continuing...
```
**解决**: 脚本会继续执行，可以手动删除文件

### 问题4: 包管理器错误
```bash
[WARN] Package manager error, continuing...
```
**解决**: 脚本会继续执行，可以手动卸载包

## 最佳实践

### 1. 备份重要数据
```bash
# 在卸载前备份重要配置
sudo cp -r /etc/wireguard /home/backup/wireguard-$(date +%Y%m%d)
sudo cp -r /etc/bird /home/backup/bird-$(date +%Y%m%d)
```

### 2. 检查依赖服务
```bash
# 检查是否有其他服务依赖 WireGuard
systemctl list-dependencies wg-quick@wg0
```

### 3. 清理用户数据
```bash
# 清理用户目录中的相关文件
rm -rf ~/.config/wireguard
rm -rf ~/.local/log/wireguard
```

### 4. 验证卸载结果
```bash
# 检查服务状态
systemctl status wg-quick@wg0
systemctl status bird

# 检查文件是否存在
ls -la /opt/ipv6-wireguard-manager
ls -la /etc/ipv6-wireguard
```

## 总结

IPv6 WireGuard Manager 的卸载功能提供了：

- ✅ **三种卸载模式**: 标准、完全、自定义
- ✅ **智能路径检测**: 自动识别安装位置
- ✅ **安全确认机制**: 防止误操作
- ✅ **完整服务管理**: 停止和禁用相关服务
- ✅ **多平台支持**: 支持各种 Linux 发行版
- ✅ **详细日志记录**: 便于问题排查
- ✅ **错误处理**: 优雅处理各种异常情况

这使得 IPv6 WireGuard Manager 的卸载过程既安全又灵活，满足不同用户的需求！
