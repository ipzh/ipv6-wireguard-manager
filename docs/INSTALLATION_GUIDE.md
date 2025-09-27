# IPv6 WireGuard Manager 安装指南

## 概述

IPv6 WireGuard Manager 是一个完整的IPv6 WireGuard VPN服务器管理系统，提供自动化的安装、配置和管理功能。

## 系统要求

### 最低要求
- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+, Debian 10+, Fedora 30+)
- **内存**: 512MB RAM
- **存储**: 1GB 可用空间
- **网络**: 公网IP地址（支持IPv6更佳）
- **权限**: root权限

### 推荐配置
- **操作系统**: Ubuntu 20.04+ 或 CentOS 8+
- **内存**: 1GB+ RAM
- **存储**: 5GB+ 可用空间
- **网络**: 双栈网络（IPv4 + IPv6）
- **CPU**: 2核心+

## 安装方法

### 方法1: 一键安装（推荐）

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh | bash
```

### 方法2: 下载安装

```bash
# 下载项目文件
wget https://github.com/ipzh/ipv6-wireguard-manager/archive/master.tar.gz
tar -xzf master.tar.gz
cd ipv6-wireguard-manager-master

# 运行安装脚本
sudo ./install.sh
```

### 方法3: 克隆仓库

```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行安装脚本
sudo ./install.sh
```

## 安装选项

### 快速安装
使用默认配置进行快速安装：

```bash
sudo ./install.sh --quick
```

### 交互式安装
自定义配置进行安装：

```bash
sudo ./install.sh --interactive
```

### 完全安装
安装所有功能模块：

```bash
sudo ./install.sh --complete
```

## 配置说明

### 基本配置

安装完成后，系统会自动创建配置文件：

- **主配置**: `/etc/ipv6-wireguard-manager/manager.conf`
- **WireGuard配置**: `/etc/wireguard/`
- **BIRD配置**: `/etc/bird/`
- **日志文件**: `/var/log/ipv6-wireguard-manager/`

### 网络配置

#### IPv4配置
```bash
# 编辑WireGuard配置
sudo nano /etc/wireguard/wg0.conf

[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

#### IPv6配置
```bash
# 添加IPv6支持
[Interface]
Address = 10.0.0.1/24, 2001:db8::1/64
```

### BIRD BGP配置

#### BIRD 2.x配置
```bash
# /etc/bird/bird.conf
router id 192.168.1.1;

protocol device {
    scan time 10;
}

protocol kernel {
    learn;
    scan time 20;
    import all;
    export all;
    merge paths on;
}

protocol bgp BGP_NEIGHBOR {
    local as 65001;
    neighbor 192.168.1.2 as 65002;
    import all;
    export all;
    next hop self;
    hold time 240;
    keepalive time 80;
}
```

## 服务管理

### 启动服务
```bash
# 启动IPv6 WireGuard Manager
sudo systemctl start ipv6-wireguard-manager

# 启动WireGuard
sudo systemctl start wg-quick@wg0

# 启动BIRD
sudo systemctl start bird
```

### 停止服务
```bash
# 停止所有服务
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl stop wg-quick@wg0
sudo systemctl stop bird
```

### 查看状态
```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status wg-quick@wg0
sudo systemctl status bird
```

### 查看日志
```bash
# 查看IPv6 WireGuard Manager日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看WireGuard日志
sudo journalctl -u wg-quick@wg0 -f

# 查看BIRD日志
sudo journalctl -u bird -f
```

## Web管理界面

### 访问Web界面
安装完成后，可以通过Web界面管理VPN：

- **IPv4地址**: `http://YOUR_SERVER_IP:8080`
- **IPv6地址**: `http://[YOUR_SERVER_IPV6]:8080`

### 默认登录信息
- **用户名**: admin
- **密码**: admin123

**重要**: 首次登录后请立即修改默认密码！

## 客户端配置

### 生成客户端配置
```bash
# 使用管理脚本生成客户端配置
sudo ipv6-wireguard-manager

# 选择 "客户端管理" -> "添加客户端"
```

### 客户端安装

#### Linux客户端
```bash
# 安装WireGuard
sudo apt install wireguard  # Ubuntu/Debian
sudo yum install wireguard-tools  # CentOS/RHEL

# 复制配置文件
sudo cp client.conf /etc/wireguard/wg0.conf

# 启动客户端
sudo wg-quick up wg0
```

#### Windows客户端
1. 下载WireGuard客户端: https://www.wireguard.com/install/
2. 导入配置文件
3. 连接VPN

#### macOS客户端
```bash
# 安装WireGuard
brew install wireguard-tools

# 启动客户端
sudo wg-quick up wg0
```

#### Android/iOS客户端
1. 从应用商店下载WireGuard应用
2. 扫描二维码或导入配置文件
3. 连接VPN

## 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看详细日志
sudo journalctl -u ipv6-wireguard-manager -n 50
```

#### 2. 网络连接问题
```bash
# 检查WireGuard接口
sudo wg show

# 检查路由表
ip route show

# 检查防火墙规则
sudo iptables -L
```

#### 3. BGP连接问题
```bash
# 检查BIRD状态
sudo birdc show status

# 检查BGP邻居
sudo birdc show protocols
```

### 日志分析

#### 查看系统日志
```bash
# 查看所有相关日志
sudo journalctl -u ipv6-wireguard-manager -u wg-quick@wg0 -u bird -f
```

#### 查看WireGuard日志
```bash
# 查看WireGuard详细日志
sudo wg show wg0
```

## 卸载

### 完全卸载
```bash
# 运行卸载脚本
sudo ./uninstall.sh --complete
```

### 保留配置卸载
```bash
# 快速卸载（保留配置）
sudo ./uninstall.sh --quick
```

### 自定义卸载
```bash
# 交互式卸载
sudo ./uninstall.sh --interactive
```

## 更新

### 检查更新
```bash
# 检查是否有新版本
sudo ipv6-wireguard-manager --check-update
```

### 手动更新
```bash
# 下载最新版本
wget https://github.com/ipzh/ipv6-wireguard-manager/archive/master.tar.gz
tar -xzf master.tar.gz
cd ipv6-wireguard-manager-master

# 运行更新
sudo ./install.sh --update
```

## 支持

### 获取帮助
- **文档**: https://github.com/ipzh/ipv6-wireguard-manager/wiki
- **问题报告**: https://github.com/ipzh/ipv6-wireguard-manager/issues
- **讨论**: https://github.com/ipzh/ipv6-wireguard-manager/discussions

### 社区支持
- **Telegram群组**: [加入群组](https://t.me/ipv6_wireguard_manager)
- **QQ群**: 123456789
- **微信群**: 扫描二维码加入

## 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。
