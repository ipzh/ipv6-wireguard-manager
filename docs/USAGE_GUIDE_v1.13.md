# IPv6 WireGuard Manager 使用指南 v1.13

## 概述

IPv6 WireGuard Manager 是一个功能强大的VPN服务器管理工具，支持IPv6前缀分发和BGP路由。本指南将帮助您快速上手并充分利用所有功能。

## 目录

1. [快速开始](#快速开始)
2. [主要功能](#主要功能)
3. [服务器管理](#服务器管理)
4. [客户端管理](#客户端管理)
5. [网络配置](#网络配置)
6. [防火墙管理](#防火墙管理)
7. [BGP配置](#bgp配置)
8. [系统维护](#系统维护)
9. [备份与恢复](#备份与恢复)
10. [故障排除](#故障排除)

## 快速开始

### 1. 安装

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/install.sh | bash

# 或者手动下载后运行
wget https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

### 2. 首次配置

```bash
# 运行主程序
sudo ./ipv6-wireguard-manager.sh

# 选择 "1. 服务器管理" -> "1. 安装WireGuard服务器"
# 按照提示完成配置
```

### 3. 基本使用

```bash
# 启动服务
sudo systemctl start wg-quick@wg0

# 检查状态
sudo systemctl status wg-quick@wg0

# 查看日志
sudo journalctl -xeu wg-quick@wg0.service
```

## 主要功能

### 核心功能

- **WireGuard VPN服务器**: 完整的WireGuard VPN服务器配置和管理
- **IPv6支持**: 原生IPv6前缀分发和管理
- **BGP路由**: 支持BIRD BGP路由配置
- **客户端管理**: 自动生成客户端配置文件
- **防火墙管理**: 自动配置iptables/ufw/firewalld规则
- **系统监控**: 实时监控VPN连接状态

### 新增功能 (v1.13)

- **增强的BGP配置**: 支持Router ID、密码、多跳等高级BGP参数
- **交互式配置**: 更友好的交互式配置界面
- **自动诊断**: 自动检测和修复常见配置问题
- **版本管理**: 统一的版本管理和更新机制

## 服务器管理

### 安装WireGuard服务器

1. 运行主程序
2. 选择 "1. 服务器管理"
3. 选择 "1. 安装WireGuard服务器"
4. 按照提示完成以下配置：
   - 选择网络接口
   - 配置IPv6前缀
   - 设置WireGuard端口
   - 配置BGP参数（可选）

### 配置WireGuard

```bash
# 编辑WireGuard配置
sudo nano /etc/wireguard/wg0.conf

# 重启WireGuard服务
sudo systemctl restart wg-quick@wg0
```

### 管理WireGuard服务

```bash
# 启动服务
sudo systemctl start wg-quick@wg0

# 停止服务
sudo systemctl stop wg-quick@wg0

# 重启服务
sudo systemctl restart wg-quick@wg0

# 查看状态
sudo systemctl status wg-quick@wg0

# 启用开机自启
sudo systemctl enable wg-quick@wg0
```

## 客户端管理

### 生成客户端配置

1. 运行主程序
2. 选择 "2. 客户端管理"
3. 选择 "1. 生成客户端配置"
4. 输入客户端信息：
   - 客户端名称
   - IPv6地址
   - 公钥（可选，系统可自动生成）

### 客户端配置文件

生成的客户端配置文件包含：
- 客户端私钥
- 服务器公钥
- 服务器地址和端口
- 分配的IPv6地址
- 路由配置

### 客户端安装

#### Linux客户端

```bash
# 安装WireGuard
sudo apt update && sudo apt install wireguard

# 导入配置
sudo wg-quick up wg0.conf

# 设置开机自启
sudo systemctl enable wg-quick@wg0
```

#### Windows客户端

1. 下载WireGuard客户端
2. 导入配置文件
3. 连接VPN

#### 移动客户端

1. 安装WireGuard应用
2. 扫描二维码或导入配置文件
3. 连接VPN

## 网络配置

### IPv6前缀配置

```bash
# 查看当前IPv6前缀
ip -6 route show

# 配置IPv6转发
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
sysctl -p
```

### 网络接口管理

```bash
# 查看网络接口
ip addr show

# 查看路由表
ip -6 route show

# 测试IPv6连接
ping6 2001:4860:4860::8888
```

## 防火墙管理

### 自动配置防火墙

1. 运行主程序
2. 选择 "4. 防火墙管理"
3. 选择 "1. 配置防火墙规则"
4. 系统会自动检测并配置相应的防火墙

### 手动配置防火墙

#### UFW (Ubuntu)

```bash
# 启用UFW
sudo ufw enable

# 允许WireGuard端口
sudo ufw allow 51820/udp

# 允许IPv6转发
sudo ufw allow in on wg0
sudo ufw allow out on wg0
```

#### iptables

```bash
# 允许WireGuard流量
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

## BGP配置

### 配置BGP参数

1. 运行主程序
2. 选择 "6. BGP配置管理"
3. 选择 "1. 交互式BGP配置"
4. 配置以下参数：
   - Router ID
   - AS Number
   - Upstream ASN
   - Neighbors (IP, AS, Password, Description)
   - Multihop设置
   - IPv6 Prefixes

### BGP配置示例

```bash
# Router ID
BGP_ROUTER_ID="192.168.1.1"

# AS Number
BGP_AS_NUMBER="65001"

# Upstream ASN
BGP_UPSTREAM_ASN="65000"

# Neighbors
BGP_NEIGHBORS="2001:db8::1,65000,password123,Upstream Provider"

# Multihop
BGP_MULTIHOP="2"

# IPv6 Prefixes
BGP_IPV6_PREFIXES="2001:db8::/48,2001:db8:1::/64"
```

### 管理BIRD服务

```bash
# 启动BIRD
sudo systemctl start bird

# 停止BIRD
sudo systemctl stop bird

# 重启BIRD
sudo systemctl restart bird

# 查看状态
sudo systemctl status bird

# 查看BGP状态
sudo birdc show protocols
sudo birdc show routes
```

## 系统维护

### 系统监控

```bash
# 查看系统资源使用
htop

# 查看网络连接
ss -tuln

# 查看WireGuard状态
sudo wg show

# 查看BGP状态
sudo birdc show protocols
```

### 日志管理

```bash
# 查看WireGuard日志
sudo journalctl -xeu wg-quick@wg0.service

# 查看BIRD日志
sudo journalctl -xeu bird.service

# 查看系统日志
sudo journalctl -f
```

### 性能优化

```bash
# 优化内核参数
echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
sysctl -p
```

## 备份与恢复

### 自动备份

1. 运行主程序
2. 选择 "7. 系统维护"
3. 选择 "1. 备份系统配置"
4. 选择备份位置和选项

### 手动备份

```bash
# 备份WireGuard配置
sudo cp -r /etc/wireguard /backup/wireguard-$(date +%Y%m%d)

# 备份BIRD配置
sudo cp -r /etc/bird /backup/bird-$(date +%Y%m%d)

# 备份系统配置
sudo cp /etc/sysctl.conf /backup/sysctl-$(date +%Y%m%d).conf
```

### 恢复配置

```bash
# 恢复WireGuard配置
sudo cp -r /backup/wireguard-20240101/* /etc/wireguard/

# 恢复BIRD配置
sudo cp -r /backup/bird-20240101/* /etc/bird/

# 重启服务
sudo systemctl restart wg-quick@wg0
sudo systemctl restart bird
```

## 故障排除

### 常见问题

#### WireGuard连接失败

```bash
# 检查服务状态
sudo systemctl status wg-quick@wg0

# 检查配置语法
sudo wg-quick strip wg0

# 检查端口是否被占用
sudo netstat -tuln | grep 51820

# 检查防火墙规则
sudo ufw status
```

#### BGP连接问题

```bash
# 检查BIRD状态
sudo systemctl status bird

# 检查BGP配置
sudo birdc configure check

# 查看BGP邻居状态
sudo birdc show protocols all bgp1

# 检查路由表
sudo birdc show routes
```

#### IPv6连接问题

```bash
# 检查IPv6转发
cat /proc/sys/net/ipv6/conf/all/forwarding

# 检查IPv6路由
ip -6 route show

# 测试IPv6连接
ping6 2001:4860:4860::8888

# 检查IPv6地址分配
ip -6 addr show wg0
```

### 诊断工具

```bash
# 运行系统诊断
sudo ./ipv6-wireguard-manager.sh

# 选择 "7. 系统维护" -> "3. 系统诊断"
# 系统会自动检测并报告问题
```

### 日志分析

```bash
# 查看错误日志
sudo journalctl -p err -xeu wg-quick@wg0.service

# 查看警告日志
sudo journalctl -p warn -xeu wg-quick@wg0.service

# 实时监控日志
sudo journalctl -f -u wg-quick@wg0.service
```

## 高级配置

### 自定义配置

```bash
# 编辑主配置文件
sudo nano /opt/ipv6-wireguard-manager/config/manager.conf

# 编辑WireGuard配置
sudo nano /etc/wireguard/wg0.conf

# 编辑BIRD配置
sudo nano /etc/bird/bird.conf
```

### 性能调优

```bash
# 调整WireGuard参数
echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf

# 调整BGP参数
# 在BIRD配置中设置合适的keepalive和holdtime
```

### 安全加固

```bash
# 限制SSH访问
sudo ufw limit ssh

# 启用fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban

# 定期更新系统
sudo apt update && sudo apt upgrade
```

## 更新和维护

### 检查更新

```bash
# 运行更新检查
sudo ./ipv6-wireguard-manager.sh

# 选择 "8. 更新管理" -> "1. 检查更新"
```

### 应用更新

```bash
# 下载并应用更新
sudo ./scripts/update.sh

# 或者使用主程序
sudo ./ipv6-wireguard-manager.sh
# 选择 "8. 更新管理" -> "2. 应用更新"
```

### 版本管理

```bash
# 查看当前版本
grep "版本:" ipv6-wireguard-manager.sh

# 查看更新日志
cat CHANGELOG.md
```

## 支持和帮助

### 获取帮助

- 查看内置帮助：运行主程序后选择 "帮助"
- 查看日志：`sudo journalctl -xeu wg-quick@wg0.service`
- 运行诊断：主程序 -> "系统维护" -> "系统诊断"

### 报告问题

如果遇到问题，请提供以下信息：
- 系统版本：`lsb_release -a`
- 内核版本：`uname -r`
- WireGuard版本：`wg --version`
- BIRD版本：`bird --version`
- 相关日志：`sudo journalctl -xeu wg-quick@wg0.service`

### 社区支持

- GitHub Issues: [项目地址]
- 文档：查看 `docs/` 目录
- 示例：查看 `examples/` 目录

---

**版本**: 1.13  
**最后更新**: 2024-01-01  
**维护者**: IPv6 WireGuard Manager Team
