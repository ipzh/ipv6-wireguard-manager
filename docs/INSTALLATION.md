# IPv6 WireGuard Manager 安装指南

## 📋 系统要求

### 支持的操作系统
- **Ubuntu**: 18.04+ (推荐 20.04+)
- **Debian**: 9+ (推荐 11+)
- **CentOS**: 7+ (推荐 8+)
- **RHEL**: 7+ (推荐 8+)
- **Fedora**: 30+ (推荐 35+)
- **Rocky Linux**: 8+
- **AlmaLinux**: 8+
- **Arch Linux**: 最新版本
- **openSUSE**: 15+
- **Windows子系统**: WSL、MSYS2、Cygwin

### 硬件要求
- **CPU**: 1核心以上 (推荐 2核心+)
- **内存**: 512MB以上 (推荐 1GB+)
- **磁盘**: 1GB可用空间
- **网络**: 支持IPv6的网络连接

### 软件依赖
- **WireGuard**: 最新版本
- **BIRD**: 1.x/2.x/3.x版本
- **防火墙工具**: UFW/firewalld/nftables/iptables
- **网络工具**: iproute2, net-tools
- **系统工具**: curl/wget, git, systemd

## 🚀 安装方法

### 方法1: 一键安装（推荐）

这是最简单快捷的安装方式，自动安装所有功能模块。

#### 自动安装
```bash
# 一键安装所有功能
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

#### 手动下载安装
```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh

# 设置执行权限
chmod +x install.sh

# 运行安装脚本
sudo ./install.sh
```

### 方法2: 交互式安装

适合需要自定义配置的用户，支持多种安装类型。

```bash
# 运行安装脚本
sudo ./install.sh

# 选择安装选项
# 1. 快速安装 - 安装所有功能
# 2. 交互式安装 - 自定义配置
# 3. 仅下载文件 - 不安装

# 交互式安装类型选择
# 1. 完整安装 - 所有功能
# 2. 最小安装 - 仅核心功能
# 3. 自定义安装 - 选择组件
```

#### 安装类型说明
- **完整安装**: 安装所有功能模块，适合生产环境
- **最小安装**: 仅安装核心功能（WireGuard、BIRD、防火墙），适合资源受限环境
- **自定义安装**: 用户逐个选择要安装的功能，适合特殊需求

### 方法3: 从源码安装

适合开发者或需要自定义修改的用户。

```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行安装脚本
sudo ./install.sh
```

### 方法4: 自定义仓库安装

如果需要使用自定义的仓库地址，可以通过环境变量配置：

```bash
# 设置环境变量
export REPO_OWNER="your-username"
export REPO_NAME="your-repo-name"
export REPO_BRANCH="main"
export REPO_URL="https://github.com/your-username/your-repo-name"
export RAW_URL="https://raw.githubusercontent.com/your-username/your-repo-name/main"

# 运行安装
curl -sSL $RAW_URL/install.sh | bash
```

## ⚙️ 安装配置

### 安装类型

#### 1. 完整安装（推荐）
- **功能**: 安装所有功能模块
- **包含**: WireGuard、BIRD、防火墙、Web界面、监控、自动安装、备份、更新、安全增强、配置管理、增强Web界面、OAuth认证、安全审计监控
- **适用**: 生产环境、完整功能需求
- **端口**: 自动开放所有必需端口

#### 2. 最小安装
- **功能**: 仅安装核心功能
- **包含**: WireGuard、BIRD、防火墙管理
- **不包含**: Web界面、监控系统、自动安装、备份、更新、安全增强、配置管理、增强Web界面、OAuth认证、安全审计监控
- **适用**: 资源受限环境、基础VPN需求
- **端口**: 仅开放核心端口

#### 3. 自定义安装
- **功能**: 用户逐个选择要安装的功能
- **选择**: WireGuard、BIRD、防火墙、Web界面、监控、自动安装、备份、更新、安全增强、配置管理、增强Web界面、OAuth认证、安全审计监控
- **适用**: 特殊需求、安全环境
- **端口**: 根据选择的功能开放相应端口

### 安装选项

#### 基本选项
- **安装目录**: `/opt/ipv6-wireguard-manager` (默认)
- **配置目录**: `/etc/ipv6-wireguard-manager`
- **日志目录**: `/var/log/ipv6-wireguard-manager`
- **二进制目录**: `/usr/local/bin`

#### 高级选项
- **跳过依赖安装**: 如果已安装所需依赖
- **跳过配置创建**: 如果已有配置文件
- **跳过服务安装**: 如果不需要系统服务
- **强制安装**: 覆盖现有安装

## 🔧 安装后配置

### 1. 启动服务

```bash
# 启动主管理服务
sudo systemctl start ipv6-wireguard-manager

# 设置开机自启
sudo systemctl enable ipv6-wireguard-manager

# 检查服务状态
sudo systemctl status ipv6-wireguard-manager
```

### 2. 配置WireGuard

```bash
# 启动管理界面
sudo ipv6-wireguard-manager

# 选择 "1. 快速安装" 或 "2. 交互式安装"
# 按照提示配置WireGuard服务器
```

### 3. 配置BIRD BGP

```bash
# 在主菜单中选择 "8. BGP配置管理"
# 选择 "1. BGP配置向导"
# 按照提示配置BGP路由
```

### 4. 配置防火墙

```bash
# 在主菜单中选择 "9. 防火墙管理"
# 系统会自动检测并配置防火墙

# 防火墙自动配置功能
# - 自动检测防火墙类型 (UFW/firewalld/nftables/iptables)
# - 根据安装的功能自动开放端口
# - 必需端口: SSH(22), DNS(53), HTTP(80), HTTPS(443), NTP(123)
# - 功能端口: WireGuard(51820), BGP(179), Web管理(8080/8443), 监控(9090), API(3000)
```

#### 自动端口开放逻辑
- **WireGuard VPN**: 自动开放 51820/udp
- **BIRD BGP**: 自动开放 179/tcp
- **Web管理界面**: 自动开放 8080/tcp, 8443/tcp
- **监控系统**: 自动开放 9090/tcp
- **客户端自动安装**: 自动开放 3000/tcp
- **基础服务**: 自动开放 SSH(22), DNS(53), HTTP(80), HTTPS(443), NTP(123)

## 🧪 验证安装

### 1. 检查服务状态

```bash
# 检查主服务
sudo systemctl status ipv6-wireguard-manager

# 检查WireGuard服务
sudo systemctl status wg-quick@wg0

# 检查BIRD服务
sudo systemctl status bird
sudo systemctl status bird6
```

### 2. 检查配置文件

```bash
# 检查主配置文件
ls -la /etc/ipv6-wireguard-manager/

# 检查WireGuard配置
ls -la /etc/wireguard/

# 检查BIRD配置
ls -la /etc/bird/
```

### 3. 测试功能

```bash
# 启动管理界面
sudo ipv6-wireguard-manager

# 测试各个功能模块
# 1. 服务器管理 - 查看服务状态
# 2. 客户端管理 - 添加测试客户端
# 3. 网络配置 - 检查IPv6配置
# 4. 防火墙管理 - 检查防火墙规则
```

## 🔧 高级配置

### 环境变量配置

```bash
# 编辑环境变量文件
sudo nano /etc/environment

# 添加以下配置
REPO_OWNER=ipzh
REPO_NAME=ipv6-wireguard-manager
REPO_BRANCH=main
REPO_URL=https://github.com/ipzh/ipv6-wireguard-manager
RAW_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main
```

### 配置文件位置

```
/etc/ipv6-wireguard-manager/
├── manager.conf              # 主配置文件
├── repository.conf           # 仓库配置
├── update.conf              # 更新配置
└── auto_install/            # 自动安装配置
    └── auto_install.conf

/etc/bird/
├── bird.conf                # BIRD IPv4配置
├── bird6.conf               # BIRD IPv6配置
└── keys/                    # BGP密钥目录

/etc/wireguard/
└── wg0.conf                 # WireGuard配置

/var/lib/ipv6-wireguard-manager/
├── clients.db               # 客户端数据库
├── install_tokens.db        # 安装令牌数据库
└── install_logs.db          # 安装日志数据库
```

## 🐛 故障排除

### 常见问题

#### 1. 权限问题
```bash
# 确保以root权限运行
sudo ./install.sh

# 检查文件权限
sudo chown -R root:root /opt/ipv6-wireguard-manager
sudo chmod +x /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh
```

#### 2. 依赖问题
```bash
# 手动安装依赖
sudo apt update  # Ubuntu/Debian
sudo apt install wireguard bird2 curl wget git

# 或者
sudo yum install wireguard-tools bird curl wget git  # CentOS/RHEL
```

#### 3. 网络问题
```bash
# 检查网络连接
ping -c 4 8.8.8.8
ping -c 4 2001:4860:4860::8888

# 检查防火墙
sudo ufw status
sudo firewall-cmd --list-all
```

#### 4. 服务启动问题
```bash
# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

### 日志文件

```bash
# 主服务日志
sudo journalctl -u ipv6-wireguard-manager

# 安装日志
tail -f /var/log/ipv6-wireguard-manager/install.log

# WireGuard日志
sudo journalctl -u wg-quick@wg0

# BIRD日志
sudo journalctl -u bird
sudo journalctl -u bird6
```

## 🔄 更新和升级

### 检查更新
```bash
# 启动管理界面
sudo ipv6-wireguard-manager

# 选择 "13. 更新检查"
# 选择 "2. 检查更新"
```

### 自动更新
```bash
# 在主菜单中选择 "13. 更新检查"
# 选择 "3. 自动更新"
```

### 手动更新
```bash
# 下载最新版本
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者使用更新脚本
sudo /opt/ipv6-wireguard-manager/update.sh
```

## 🗑️ 卸载

### 完全卸载
```bash
# 运行卸载脚本
sudo /opt/ipv6-wireguard-manager/uninstall.sh

# 或者手动卸载
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl disable ipv6-wireguard-manager
sudo rm -rf /opt/ipv6-wireguard-manager
sudo rm -rf /etc/ipv6-wireguard-manager
sudo rm -rf /var/log/ipv6-wireguard-manager
```

### 保留配置卸载
```bash
# 备份配置文件
sudo cp -r /etc/ipv6-wireguard-manager /tmp/backup-config

# 卸载程序
sudo /opt/ipv6-wireguard-manager/uninstall.sh

# 恢复配置文件
sudo cp -r /tmp/backup-config /etc/ipv6-wireguard-manager
```

## 📞 获取帮助

如果遇到问题，可以通过以下方式获取帮助：

1. **查看日志**: 检查系统日志和程序日志
2. **检查配置**: 验证配置文件是否正确
3. **重启服务**: 尝试重启相关服务
4. **重新安装**: 如果问题严重，可以尝试重新安装

## 📚 相关文档

- [使用指南](USAGE.md) - 详细的功能使用说明
- [项目主页](https://github.com/ipzh/ipv6-wireguard-manager) - 项目主页和最新信息
- [问题反馈](https://github.com/ipzh/ipv6-wireguard-manager/issues) - 提交问题和建议