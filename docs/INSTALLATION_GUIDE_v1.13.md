# IPv6 WireGuard Manager 安装指南 v1.13

## 概述

本指南将帮助您在Linux服务器上安装和配置IPv6 WireGuard Manager v1.13。该工具支持IPv6前缀分发和BGP路由，提供完整的WireGuard VPN服务器管理功能。

## 系统要求

### 最低要求

- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+
- **架构**: x86_64, ARM64
- **内存**: 512MB RAM
- **存储**: 1GB 可用空间
- **网络**: 公网IP地址，支持IPv6

### 推荐配置

- **操作系统**: Ubuntu 20.04+ LTS
- **架构**: x86_64
- **内存**: 2GB+ RAM
- **存储**: 10GB+ 可用空间
- **网络**: 稳定的IPv6连接

### 软件依赖

- **WireGuard**: 1.0.0+
- **BIRD**: 2.0.0+ (可选，用于BGP路由)
- **iptables**: 用于防火墙管理
- **systemd**: 用于服务管理

## 安装方法

### 方法1: 自动安装 (推荐)

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/install.sh | bash

# 或者使用wget
wget -qO- https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/install.sh | bash
```

### 方法2: 手动安装

```bash
# 1. 克隆仓库
git clone https://github.com/your-repo/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 2. 设置权限
chmod +x *.sh
chmod +x scripts/*.sh
chmod +x modules/*.sh

# 3. 运行安装脚本
sudo ./install.sh
```

### 方法3: 从源码安装

```bash
# 1. 下载源码
wget https://github.com/your-repo/ipv6-wireguard-manager/archive/v1.13.tar.gz
tar -xzf v1.13.tar.gz
cd ipv6-wireguard-manager-1.13

# 2. 安装依赖
sudo apt update
sudo apt install -y wireguard bird2 iptables ufw

# 3. 运行安装脚本
sudo ./install.sh
```

## 安装过程详解

### 1. 系统检测

安装脚本会自动检测：
- 操作系统类型和版本
- 架构支持
- 已安装的软件包
- 网络接口配置
- IPv6支持状态

### 2. 依赖安装

脚本会自动安装以下依赖：

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y wireguard bird2 iptables ufw curl wget

# CentOS/RHEL
sudo yum install -y epel-release
sudo yum install -y wireguard-tools bird2 iptables firewalld curl wget

# 或者使用dnf (CentOS 8+)
sudo dnf install -y wireguard-tools bird2 iptables firewalld curl wget
```

### 3. 目录结构创建

```
/opt/ipv6-wireguard-manager/
├── config/                 # 配置文件
├── modules/               # 功能模块
├── scripts/               # 工具脚本
├── logs/                  # 日志文件
├── backups/               # 备份文件
└── clients/               # 客户端配置
```

### 4. 服务配置

```bash
# 创建systemd服务文件
sudo systemctl daemon-reload
sudo systemctl enable ipv6-wireguard-manager

# 创建BIRD服务文件
sudo systemctl enable bird
```

## 首次配置

### 1. 运行配置向导

```bash
# 运行主程序
sudo ./ipv6-wireguard-manager.sh

# 或者使用完整路径
sudo /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh
```

### 2. 选择配置选项

```
╔══════════════════════════════════════════════════════════════╗
║                IPv6 WireGuard VPN Manager                  ║
║                    版本 1.13                              ║
╚══════════════════════════════════════════════════════════════╝

请选择操作:
1. 服务器管理
2. 客户端管理
3. 网络配置
4. 防火墙管理
5. 系统维护
6. BGP配置管理
7. 备份与恢复
8. 更新管理
9. 帮助
0. 退出
```

### 3. 服务器配置

选择 "1. 服务器管理" -> "1. 安装WireGuard服务器"

#### 3.1 网络接口选择

```
检测到的网络接口:
1. eth0 (192.168.1.100, 2001:db8::1)
2. wlan0 (192.168.1.101, 2001:db8::2)
3. 手动输入

请选择网络接口 (1-3): 1
```

#### 3.2 IPv6前缀配置

```
请输入IPv6前缀 (例如: 2001:db8:1::/64): 2001:db8:1::/64
```

#### 3.3 WireGuard端口配置

```
请输入WireGuard端口 (默认: 51820): 51820
```

#### 3.4 BGP配置 (可选)

```
是否配置BGP路由? (y/n): y

请输入BGP Router ID (默认: 192.168.1.100): 192.168.1.100
请输入BGP AS Number (默认: 65001): 65001
请输入上游ASN (默认: 65000): 65000
```

## 验证安装

### 1. 检查服务状态

```bash
# 检查WireGuard服务
sudo systemctl status wg-quick@wg0

# 检查BIRD服务
sudo systemctl status bird

# 检查管理器服务
sudo systemctl status ipv6-wireguard-manager
```

### 2. 检查配置文件

```bash
# 检查WireGuard配置
sudo cat /etc/wireguard/wg0.conf

# 检查BIRD配置
sudo cat /etc/bird/bird.conf

# 检查管理器配置
sudo cat /opt/ipv6-wireguard-manager/config/manager.conf
```

### 3. 测试网络连接

```bash
# 测试IPv6连接
ping6 2001:4860:4860::8888

# 测试WireGuard端口
sudo netstat -tuln | grep 51820

# 测试BGP连接
sudo birdc show protocols
```

## 常见问题解决

### 1. 安装失败

```bash
# 检查系统要求
uname -a
lsb_release -a

# 检查网络连接
ping -c 3 8.8.8.8
ping6 -c 3 2001:4860:4860::8888

# 检查权限
sudo -v
```

### 2. WireGuard安装失败

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:wireguard/wireguard
sudo apt update
sudo apt install -y wireguard

# CentOS/RHEL
sudo yum install -y epel-release
sudo yum install -y wireguard-tools
```

### 3. BIRD安装失败

```bash
# Ubuntu/Debian
sudo apt install -y bird2

# CentOS/RHEL
sudo yum install -y bird2

# 或者从源码编译
wget https://bird.network.cz/download/bird-2.0.8.tar.gz
tar -xzf bird-2.0.8.tar.gz
cd bird-2.0.8
./configure
make
sudo make install
```

### 4. 权限问题

```bash
# 检查文件权限
ls -la /opt/ipv6-wireguard-manager/

# 修复权限
sudo chown -R root:root /opt/ipv6-wireguard-manager/
sudo chmod +x /opt/ipv6-wireguard-manager/*.sh
sudo chmod +x /opt/ipv6-wireguard-manager/scripts/*.sh
sudo chmod +x /opt/ipv6-wireguard-manager/modules/*.sh
```

## 卸载

### 完全卸载

```bash
# 运行卸载脚本
sudo ./uninstall.sh

# 或者手动卸载
sudo systemctl stop wg-quick@wg0
sudo systemctl stop bird
sudo systemctl stop ipv6-wireguard-manager

sudo systemctl disable wg-quick@wg0
sudo systemctl disable bird
sudo systemctl disable ipv6-wireguard-manager

sudo rm -rf /opt/ipv6-wireguard-manager/
sudo rm -f /etc/systemd/system/ipv6-wireguard-manager.service
sudo systemctl daemon-reload
```

### 保留配置卸载

```bash
# 备份配置
sudo cp -r /opt/ipv6-wireguard-manager/config /backup/
sudo cp -r /etc/wireguard /backup/
sudo cp -r /etc/bird /backup/

# 运行卸载脚本
sudo ./uninstall.sh

# 恢复配置
sudo cp -r /backup/config /opt/ipv6-wireguard-manager/
sudo cp -r /backup/wireguard /etc/
sudo cp -r /backup/bird /etc/
```

## 升级

### 从旧版本升级

```bash
# 1. 备份当前配置
sudo ./ipv6-wireguard-manager.sh
# 选择 "7. 系统维护" -> "1. 备份系统配置"

# 2. 下载新版本
wget https://github.com/your-repo/ipv6-wireguard-manager/archive/v1.13.tar.gz
tar -xzf v1.13.tar.gz

# 3. 运行升级脚本
cd ipv6-wireguard-manager-1.13
sudo ./scripts/update.sh
```

### 自动升级

```bash
# 启用自动升级检查
sudo ./ipv6-wireguard-manager.sh
# 选择 "8. 更新管理" -> "3. 启用自动更新"
```

## 安全配置

### 1. 防火墙配置

```bash
# 配置UFW
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 51820/udp
sudo ufw allow from 2001:db8::/64

# 配置iptables
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
sudo ip6tables -A INPUT -p udp --dport 51820 -j ACCEPT
```

### 2. 系统加固

```bash
# 禁用不必要的服务
sudo systemctl disable bluetooth
sudo systemctl disable cups

# 配置SSH安全
sudo nano /etc/ssh/sshd_config
# 设置: PermitRootLogin no
# 设置: PasswordAuthentication no
sudo systemctl restart ssh
```

### 3. 监控配置

```bash
# 安装监控工具
sudo apt install -y htop iotop nethogs

# 配置日志轮转
sudo nano /etc/logrotate.d/ipv6-wireguard-manager
```

## 性能优化

### 1. 内核参数优化

```bash
# 编辑sysctl配置
sudo nano /etc/sysctl.conf

# 添加以下配置
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.all.accept_redirects = 0

# 应用配置
sudo sysctl -p
```

### 2. WireGuard优化

```bash
# 编辑WireGuard配置
sudo nano /etc/wireguard/wg0.conf

# 添加性能优化参数
[Interface]
# ... 其他配置 ...
PostUp = echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
PostUp = echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
PostUp = sysctl -p
```

### 3. BIRD优化

```bash
# 编辑BIRD配置
sudo nano /etc/bird/bird.conf

# 优化扫描时间
protocol device {
    scan time 5;
}

protocol kernel {
    scan time 10;
}
```

## 故障排除

### 1. 安装日志

```bash
# 查看安装日志
sudo journalctl -u ipv6-wireguard-manager-install

# 查看详细日志
sudo tail -f /var/log/ipv6-wireguard-manager.log
```

### 2. 服务状态检查

```bash
# 检查所有相关服务
sudo systemctl status wg-quick@wg0 bird ipv6-wireguard-manager

# 检查端口占用
sudo netstat -tuln | grep -E "(51820|179)"
```

### 3. 网络诊断

```bash
# 检查网络接口
ip addr show
ip -6 route show

# 检查防火墙规则
sudo ufw status verbose
sudo iptables -L -n
sudo ip6tables -L -n
```

## 支持

### 获取帮助

- 查看内置帮助：运行主程序后选择 "帮助"
- 查看日志：`sudo journalctl -xeu wg-quick@wg0.service`
- 运行诊断：主程序 -> "系统维护" -> "系统诊断"

### 报告问题

如果遇到问题，请提供以下信息：
- 系统版本：`lsb_release -a`
- 内核版本：`uname -r`
- 安装日志：`sudo journalctl -u ipv6-wireguard-manager-install`
- 错误信息：完整的错误输出

---

**版本**: 1.13  
**最后更新**: 2024-01-01  
**维护者**: IPv6 WireGuard Manager Team
