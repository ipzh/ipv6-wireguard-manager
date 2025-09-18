# IPv6 WireGuard Manager 完整用户指南

## 📖 目录

1. [项目概述](#项目概述)
2. [快速开始](#快速开始)
3. [服务器端管理](#服务器端管理)
4. [客户端管理](#客户端管理)
5. [网络配置](#网络配置)
6. [高级功能](#高级功能)
7. [故障排除](#故障排除)
8. [最佳实践](#最佳实践)
9. [API 参考](#api-参考)
10. [更新日志](#更新日志)

## 项目概述

IPv6 WireGuard Manager 是一个功能强大的 VPN 管理工具，专为 IPv6 网络环境设计，支持 BGP 路由和自动客户端管理。

### 核心特性

- 🌐 **IPv6 原生支持**: 完整的 IPv6 网络配置和管理
- 🔧 **BGP 路由**: 集成 BIRD BGP 路由协议
- 👥 **客户端管理**: 自动化客户端配置和部署
- 🔄 **自动更新**: 客户端自动检查和更新机制
- 🛡️ **安全防护**: 内置防火墙和访问控制
- 📊 **监控统计**: 实时连接状态和流量统计
- 🔧 **模块化设计**: 可扩展的模块化架构

## 快速开始

### 系统要求

- **操作系统**: Linux (Ubuntu 20.04+, CentOS 8+, Debian 11+)
- **内存**: 最少 512MB RAM
- **存储**: 最少 1GB 可用空间
- **网络**: 支持 IPv6 的网络环境
- **权限**: root 或 sudo 权限

### 安装步骤

#### 1. 下载安装脚本

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/ipv6-wireguard-manager/ipv6-wireguard-manager/main/install.sh

# 添加执行权限
chmod +x install.sh

# 运行安装
sudo ./install.sh
```

#### 2. 启动管理器

```bash
# 启动主管理器
ipv6-wg-manager

# 或启动核心版本
./ipv6-wireguard-manager-core.sh
```

#### 3. 快速配置

```bash
# 选择：1. 快速安装 (一键配置)
# 系统将自动：
# - 检测系统环境
# - 安装 WireGuard 和 BIRD
# - 配置网络和防火墙
# - 启动所有服务
```

## 服务器端管理

### 主菜单功能

启动管理器后，您将看到以下主菜单：

```
主菜单:
  1. 快速安装 (一键配置)
  2. 交互式安装
  3. 服务器管理
  4. 客户端管理
  5. 网络配置
  6. 防火墙管理
  7. 系统维护
  8. 配置备份/恢复
  9. 更新检查
  0. 退出
```

### 服务器管理功能

#### 服务状态管理

```bash
# 选择：3. 服务器管理
# 子菜单：
#   1. 查看服务状态
#   2. 启动服务
#   3. 停止服务
#   4. 重启服务
#   5. 重载配置
#   6. 查看服务日志
#   7. 查看系统资源使用
#   8. 查看网络连接
#   9. WireGuard 诊断工具
#   0. 返回主菜单
```

#### WireGuard 诊断工具

专业的诊断工具提供以下功能：

- **综合诊断**: 全面检查 WireGuard 安装、配置、服务和网络状态
- **安装诊断**: 检查 WireGuard 安装状态、版本、控制工具和用户权限
- **配置诊断**: 验证配置文件语法、内容和权限设置
- **服务诊断**: 分析服务状态、systemd 配置和启动失败原因
- **网络诊断**: 检查网络接口、IPv6 转发和 BGP 连接状态
- **自动修复**: 自动修复权限问题、服务文件和网络配置
- **错误详情**: 显示详细的配置错误信息和修复建议

### 网络配置管理

#### IPv6 前缀管理

```bash
# 选择：5. 网络配置
# 子菜单：
#   1. 查看当前 IPv6 前缀
#   2. 添加 IPv6 前缀
#   3. 删除 IPv6 前缀
#   4. 修改 IPv6 前缀
#   5. 查看前缀统计
#   0. 返回主菜单
```

#### 地址池管理

- **灵活子网段支持**: 支持 /56 到 /72 的子网段配置
- **智能地址分配**: 自动为客户端分配可用的 IPv6 地址
- **地址池监控**: 实时显示地址使用情况和可用性
- **批量操作**: 支持批量添加、删除和修改客户端地址

## 客户端管理

### 客户端安装方式

#### 方式1: 服务器端生成安装包（推荐）

```bash
# 1. 在服务器上添加客户端
ipv6-wg-manager
# 选择：4. 客户端管理 -> 1. 添加客户端
# 输入客户端名称，选择自动分配地址

# 2. 生成客户端安装包
# 选择：4. 客户端管理 -> 6. 生成客户端安装包 (自动安装脚本)
# 输入客户端名称和输出目录

# 3. 在客户端下载并运行
# Linux:
scp user@server:/path/to/install-linux.sh /tmp/
chmod +x /tmp/install-linux.sh
./install-linux.sh

# Windows:
# 下载 install-windows.ps1
# 以管理员权限运行 PowerShell
.\install-windows.ps1
```

#### 方式2: 传统配置文件方式

```bash
# 1. 生成客户端配置
# 选择：4. 客户端管理 -> 5. 生成客户端配置包

# 2. 在客户端安装 WireGuard
# Ubuntu/Debian:
sudo apt install wireguard

# CentOS/RHEL:
sudo yum install wireguard-tools

# 3. 导入配置文件
sudo cp client.conf /etc/wireguard/
sudo wg-quick up client
```

### 客户端自动更新

#### 自动更新功能

客户端安装后自动包含更新功能：

```bash
# 检查更新
./update.sh check

# 手动更新
./update.sh update

# 自动更新检查
./update.sh auto
```

#### 更新配置

```bash
# 配置自动更新
./update.sh config

# 配置选项：
# 1. 启用/禁用自动更新
# 2. 设置检查间隔
# 3. 设置更新服务器
# 4. 查看更新日志
# 5. 手动检查更新
```

### 客户端管理功能

#### 客户端列表管理

```bash
# 选择：4. 客户端管理
# 子菜单：
#   1. 添加客户端
#   2. 删除客户端
#   3. 列出所有客户端
#   4. 查看客户端信息
#   5. 生成客户端配置包
#   6. 生成客户端安装包 (自动安装脚本)
#   7. 批量生成客户端
#   8. 快速批量添加客户端
#   9. 导出客户端配置
#   10. 监控客户端连接
#   11. 清理不活跃客户端
#   12. 地址池管理
#   0. 返回主菜单
```

#### 批量客户端管理

```bash
# 批量添加客户端
# 选择：4. 客户端管理 -> 8. 快速批量添加客户端
# 输入要添加的客户端数量、名称前缀和起始索引

# 批量生成客户端
# 选择：4. 客户端管理 -> 7. 批量生成客户端
# 从 CSV 文件批量生成客户端配置
```

## 网络配置

### IPv6 网络配置

#### 服务器端配置

```bash
# 服务器使用具体 IP 地址
# 例如：2001:db8::1/64
Address = 10.0.0.1/24, 2001:db8::1/64
```

#### 客户端配置

```bash
# 客户端从子网段分配
# 例如：2001:db8::2/64
Address = 10.0.0.2/32, 2001:db8::2/64
```

#### 子网段支持

- **/56 子网**: 支持 256 个 /64 子网
- **/64 子网**: 标准 IPv6 子网
- **/72 子网**: 支持 4096 个 /80 子网

### BGP 路由配置

#### BIRD 配置

```bash
# 自动检测 BIRD 版本
# 优先安装 BIRD 2.x，失败时安装 BIRD 1.x

# BIRD 2.x 配置
protocol bgp {
    local as 65001;
    neighbor 2001:db8::1 as 65002;
    ipv6 {
        import all;
        export all;
    };
}
```

#### 路由管理

```bash
# 查看 BGP 状态
birdc show protocols
birdc show routes

# 重启 BGP 服务
sudo systemctl restart bird2
```

## 高级功能

### 监控和统计

#### 连接监控

```bash
# 实时监控客户端连接
# 选择：4. 客户端管理 -> 10. 监控客户端连接

# 显示信息：
# - 客户端连接状态
# - 数据传输统计
# - 连接时间
# - 最后握手时间
```

#### 系统资源监控

```bash
# 查看系统资源使用
# 选择：3. 服务器管理 -> 7. 查看系统资源使用

# 显示信息：
# - CPU 使用率
# - 内存使用情况
# - 磁盘空间
# - 网络接口状态
```

### 备份和恢复

#### 配置备份

```bash
# 选择：8. 配置备份/恢复
# 子菜单：
#   1. 创建备份
#   2. 恢复备份
#   3. 列出备份
#   4. 删除备份
#   0. 返回主菜单
```

#### 自动备份

```bash
# 系统自动备份：
# - 每日自动备份配置文件
# - 保留最近 30 天的备份
# - 备份包含客户端配置、网络设置和系统配置
```

### 安全功能

#### 防火墙管理

```bash
# 选择：6. 防火墙管理
# 子菜单：
#   1. 查看防火墙状态
#   2. 配置防火墙规则
#   3. 添加端口规则
#   4. 删除端口规则
#   5. 重置防火墙
#   0. 返回主菜单
```

#### 访问控制

```bash
# 支持的防火墙类型：
# - UFW (Ubuntu/Debian)
# - firewalld (CentOS/RHEL/Fedora)
# - iptables (通用)
# - nftables (现代 Linux)
```

## 故障排除

### 常见问题

#### 1. WireGuard 服务启动失败

```bash
# 检查服务状态
sudo systemctl status wg-quick@wg0

# 查看详细日志
sudo journalctl -xeu wg-quick@wg0

# 使用诊断工具
# 选择：3. 服务器管理 -> 9. WireGuard 诊断工具
```

#### 2. IPv6 配置错误

```bash
# 检查 IPv6 支持
cat /proc/net/if_inet6

# 启用 IPv6 转发
echo 1 | sudo tee /proc/sys/net/ipv6/conf/all/forwarding

# 检查网络接口
ip -6 addr show
```

#### 3. BIRD BGP 连接问题

```bash
# 检查 BIRD 状态
sudo systemctl status bird2

# 查看 BIRD 日志
sudo journalctl -u bird2

# 检查 BGP 邻居
birdc show protocols
```

#### 4. 客户端连接问题

```bash
# 检查客户端配置
cat ~/.config/wireguard/client.conf

# 测试连接
ping 8.8.8.8
ping 2001:4860:4860::8888

# 查看 WireGuard 状态
sudo wg show
```

### 日志文件位置

```bash
# 系统日志
/var/log/ipv6-wireguard/manager.log

# WireGuard 日志
sudo journalctl -u wg-quick@wg0

# BIRD 日志
sudo journalctl -u bird2

# 客户端更新日志
~/.local/log/wireguard/update.log
```

## 最佳实践

### 安全建议

1. **定期更新**: 保持系统和软件包最新
2. **强密钥**: 使用强随机密钥生成
3. **访问控制**: 限制管理接口访问
4. **监控日志**: 定期检查系统日志
5. **备份配置**: 定期备份重要配置

### 性能优化

1. **资源监控**: 定期检查系统资源使用
2. **网络优化**: 优化网络配置和路由
3. **客户端管理**: 定期清理不活跃客户端
4. **日志轮转**: 配置日志文件轮转

### 维护建议

1. **定期检查**: 每周检查系统状态
2. **更新管理**: 及时应用安全更新
3. **配置备份**: 在重大更改前备份配置
4. **监控告警**: 设置关键指标监控

## API 参考

### 命令行接口

```bash
# 主管理器
ipv6-wg-manager [选项]

# 核心脚本
./ipv6-wireguard-manager-core.sh [选项]

# 客户端安装
./client-installer.sh [选项]

# 客户端更新
./update.sh [check|update|auto|config]
```

### 配置文件格式

#### 主配置文件

```ini
# /etc/ipv6-wireguard/manager.conf
[server]
wg_port = 51820
ipv6_prefix = 2001:db8::/48
as_number = 65001

[client]
auto_allocate = true
subnet_mask = 64
```

#### 客户端配置

```ini
# ~/.config/wireguard/client.conf
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/32, 2001:db8::2/64
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = <server-public-key>
Endpoint = server.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

## 更新日志

### 版本 1.11 (最新)

#### 新增功能
- ✅ 客户端自动更新系统
- ✅ 灵活的子网段支持 (/56 到 /72)
- ✅ 智能客户端地址分配
- ✅ 增强的诊断工具
- ✅ 改进的错误处理

#### 修复问题
- 🔧 修复 IPv6 地址配置错误
- 🔧 修复模块路径问题
- 🔧 修复安装状态显示不一致
- 🔧 改进符号链接支持

#### 性能优化
- ⚡ 优化客户端安装速度
- ⚡ 改进网络检测算法
- ⚡ 减少内存使用

### 版本 1.0.4

#### 新增功能
- ✅ 客户端一键安装脚本
- ✅ 跨平台支持 (Linux/Windows/macOS)
- ✅ QR 码生成和扫描
- ✅ 批量客户端管理

### 版本 1.0.3

#### 新增功能
- ✅ BIRD BGP 路由支持
- ✅ IPv6 前缀管理
- ✅ 防火墙自动配置
- ✅ 客户端管理界面

### 版本 1.0.2

#### 新增功能
- ✅ 基础 WireGuard 管理
- ✅ IPv6 网络支持
- ✅ 模块化架构

### 版本 1.0.1

#### 初始版本
- ✅ 基础 WireGuard 管理
- ✅ IPv6 网络支持
- ✅ 模块化架构

### 版本 1.0.0

#### 初始版本
- ✅ 基础 WireGuard 管理
- ✅ IPv6 网络支持
- ✅ 模块化架构
- ✅ 用户友好界面

---

## 技术支持

如果您在使用过程中遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查系统日志和错误信息
3. 确认网络连接和防火墙设置
4. 联系技术支持团队

**项目地址**: https://github.com/ipv6-wireguard-manager/ipv6-wireguard-manager
**文档地址**: https://github.com/ipv6-wireguard-manager/ipv6-wireguard-manager/docs
**问题反馈**: https://github.com/ipv6-wireguard-manager/ipv6-wireguard-manager/issues

---

**注意**: 本指南基于最新版本编写，建议定期查看更新。
