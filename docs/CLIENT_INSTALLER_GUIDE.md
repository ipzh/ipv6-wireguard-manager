# 客户端安装脚本使用指南

## 概述

IPv6 WireGuard Manager 提供了专门的客户端一键安装脚本，支持多种操作系统平台，让客户端安装变得简单快捷。

## 支持的平台

### 桌面系统
- **Linux**: Ubuntu, Debian, CentOS, RHEL, Fedora, Rocky Linux, AlmaLinux, Arch Linux, openSUSE
- **Windows**: Windows 10/11 (PowerShell 脚本)
- **macOS**: macOS 10.15+ (通过 Homebrew)

### 移动设备
- **Android**: 通过 WireGuard 官方应用
- **iOS**: 通过 WireGuard 官方应用

## 安装脚本特性

### 核心功能
- ✅ **自动检测**: 自动检测操作系统类型和架构
- ✅ **智能安装**: 自动安装 WireGuard 依赖包
- ✅ **多种配置**: 支持交互式配置、文件导入、QR 码扫描
- ✅ **一键启动**: 自动启动 WireGuard 客户端
- ✅ **状态监控**: 实时显示连接状态和配置信息
- ✅ **QR 码生成**: 生成配置 QR 码供移动设备使用

### 高级功能
- 🔧 **权限管理**: 自动处理文件权限和目录创建
- 🔧 **错误处理**: 完善的错误检测和恢复机制
- 🔧 **日志记录**: 详细的安装和运行日志
- 🔧 **配置验证**: 自动验证配置文件格式和内容
- 🔧 **服务管理**: 自动配置系统服务（Linux/macOS）

## Linux/Unix 客户端安装

### 快速安装

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/client-installer.sh

# 添加执行权限
chmod +x client-installer.sh

# 运行安装脚本
./client-installer.sh
```

### 安装过程

1. **系统检测**
   - 自动检测操作系统类型和版本
   - 检测系统架构 (x86_64, ARM64, etc.)
   - 检查现有 WireGuard 安装

2. **依赖安装**
   - 自动安装 WireGuard 工具包
   - 安装必要的系统依赖
   - 配置系统服务

3. **客户端配置**
   - 交互式输入服务器信息
   - 自动生成客户端密钥对
   - 创建客户端配置文件

4. **服务启动**
   - 自动启动 WireGuard 服务
   - 配置开机自启动
   - 验证连接状态

### 配置选项

#### 交互式配置
```bash
./client-installer.sh
# 按提示输入服务器信息
# 服务器地址: your-server.com
# 服务器端口: 51820
# 客户端名称: my-client
# IPv4 地址: 10.0.0.2/32
# IPv6 地址: 2001:db8::2/64
```

#### 从文件导入
```bash
# 准备配置文件
cat > my-client.conf << EOF
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/32, 2001:db8::2/64
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# 导入配置文件
./client-installer.sh
# 选择: 2. 从配置文件导入
# 输入: my-client.conf
```

#### 从 QR 码导入
```bash
./client-installer.sh
# 选择: 3. 从 QR 码导入
# 使用摄像头扫描 QR 码
```

### 常用命令

```bash
# 启动客户端
sudo wg-quick up client-name

# 停止客户端
sudo wg-quick down client-name

# 查看状态
sudo wg show

# 查看日志
sudo journalctl -u wg-quick@client-name

# 生成 QR 码
qrencode -t ansiutf8 < ~/.config/wireguard/client-name.conf
```

## Windows 客户端安装

### 快速安装

```powershell
# 下载安装脚本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/client-installer.ps1" -OutFile "client-installer.ps1"

# 运行安装脚本
.\client-installer.ps1 -Install
```

### 安装参数

```powershell
# 基本安装
.\client-installer.ps1 -Install

# 指定配置文件
.\client-installer.ps1 -ConfigFile "C:\config\client.conf" -Start

# 指定客户端名称
.\client-installer.ps1 -ClientName "my-client" -Install

# 显示帮助
.\client-installer.ps1 -Help
```

### 安装过程

1. **权限检查**
   - 检查管理员权限
   - 提示权限不足时的解决方案

2. **WireGuard 安装**
   - 自动下载 WireGuard 安装程序
   - 静默安装 WireGuard 客户端
   - 验证安装结果

3. **配置管理**
   - 创建配置目录
   - 导入或生成配置文件
   - 配置 WireGuard 服务

4. **服务启动**
   - 启动 WireGuard 服务
   - 验证连接状态
   - 显示配置信息

### 配置方式

#### 交互式配置
```powershell
.\client-installer.ps1
# 按提示输入服务器信息
```

#### 从文件导入
```powershell
.\client-installer.ps1 -ConfigFile "C:\path\to\client.conf"
```

#### 从剪贴板导入
```powershell
# 复制配置文件内容到剪贴板
.\client-installer.ps1
# 选择: 3. 从剪贴板导入
```

## macOS 客户端安装

### 快速安装

```bash
# 下载安装脚本
curl -O https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/client-installer.sh

# 添加执行权限
chmod +x client-installer.sh

# 运行安装脚本
./client-installer.sh
```

### 安装过程

1. **Homebrew 检查**
   - 检查 Homebrew 是否已安装
   - 自动安装 Homebrew（如需要）

2. **WireGuard 安装**
   - 通过 Homebrew 安装 WireGuard
   - 安装必要的依赖包

3. **配置和启动**
   - 创建配置目录
   - 生成或导入配置文件
   - 启动 WireGuard 服务

### 常用命令

```bash
# 启动客户端
sudo wg-quick up client-name

# 停止客户端
sudo wg-quick down client-name

# 查看状态
sudo wg show

# 生成 QR 码
qrencode -t ansiutf8 < ~/.config/wireguard/client-name.conf
```

## 移动设备安装

### Android 安装

1. **下载应用**
   - 从 Google Play Store 下载 WireGuard 应用
   - 或从 [官网](https://www.wireguard.com/install/) 下载 APK

2. **导入配置**
   - 扫描服务器生成的 QR 码
   - 或手动导入配置文件
   - 配置客户端名称

3. **连接 VPN**
   - 点击连接按钮
   - 验证连接状态

### iOS 安装

1. **下载应用**
   - 从 App Store 下载 WireGuard 应用

2. **导入配置**
   - 扫描服务器生成的 QR 码
   - 或通过 AirDrop 接收配置文件

3. **连接 VPN**
   - 启用 VPN 连接
   - 验证连接状态

## 配置管理

### 配置文件位置

#### Linux/macOS
```
~/.config/wireguard/
├── client1.conf
├── client2.conf
└── ...
```

#### Windows
```
%USERPROFILE%\.config\wireguard\
├── client1.conf
├── client2.conf
└── ...
```

### 配置文件格式

```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/32, 2001:db8::2/64
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### 配置验证

```bash
# 验证配置文件语法
wg-quick strip client-name

# 测试配置
sudo wg-quick up client-name --dry-run
```

## 故障排除

### 常见问题

#### 1. 权限问题
```bash
# Linux/macOS
sudo chmod 600 ~/.config/wireguard/client.conf
sudo chown $USER:$USER ~/.config/wireguard/client.conf
```

#### 2. 服务启动失败
```bash
# 检查服务状态
sudo systemctl status wg-quick@client-name

# 查看详细日志
sudo journalctl -u wg-quick@client-name -f
```

#### 3. 网络连接问题
```bash
# 检查网络接口
ip addr show wg0

# 检查路由表
ip route show

# 测试连接
ping 8.8.8.8
```

#### 4. 配置文件问题
```bash
# 验证配置文件
wg-quick strip client-name

# 重新生成配置
./client-installer.sh
```

### 日志查看

#### Linux/macOS
```bash
# 系统日志
sudo journalctl -u wg-quick@client-name

# WireGuard 日志
sudo wg show
```

#### Windows
```powershell
# 事件查看器
Get-WinEvent -LogName "Application" | Where-Object {$_.ProviderName -like "*WireGuard*"}

# WireGuard 日志
Get-Content "$env:USERPROFILE\.local\log\wireguard\client.log"
```

## 高级配置

### 自定义 DNS
```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/32, 2001:db8::2/64
DNS = 1.1.1.1, 1.0.0.1, 2001:4860:4860::8888
```

### 自定义路由
```ini
[Peer]
PublicKey = <server-public-key>
Endpoint = your-server.com:51820
AllowedIPs = 10.0.0.0/24, 2001:db8::/64
PersistentKeepalive = 25
```

### 多服务器配置
```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/32, 2001:db8::2/64

[Peer]
PublicKey = <server1-public-key>
Endpoint = server1.example.com:51820
AllowedIPs = 10.0.0.0/24

[Peer]
PublicKey = <server2-public-key>
Endpoint = server2.example.com:51820
AllowedIPs = 2001:db8::/64
```

## 安全建议

### 密钥管理
- 定期轮换客户端密钥
- 安全存储私钥文件
- 使用强随机密钥生成

### 网络安全
- 启用防火墙规则
- 定期更新 WireGuard 版本
- 监控异常连接

### 配置安全
- 限制 AllowedIPs 范围
- 使用专用 DNS 服务器
- 定期备份配置文件

## 更新和维护

### 更新客户端
```bash
# Linux/macOS
sudo apt update && sudo apt upgrade wireguard-tools  # Ubuntu/Debian
sudo yum update wireguard-tools  # CentOS/RHEL
brew upgrade wireguard-tools  # macOS

# Windows
# 通过 WireGuard 应用自动更新
```

### 配置备份
```bash
# 备份配置文件
tar -czf wireguard-configs-backup.tar.gz ~/.config/wireguard/

# 恢复配置文件
tar -xzf wireguard-configs-backup.tar.gz -C ~/.config/
```

### 服务管理
```bash
# 启用开机自启动
sudo systemctl enable wg-quick@client-name

# 禁用开机自启动
sudo systemctl disable wg-quick@client-name

# 重启服务
sudo systemctl restart wg-quick@client-name
```

## 技术支持

如果您在使用客户端安装脚本时遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查系统日志和错误信息
3. 确认网络连接和防火墙设置
4. 联系技术支持团队

---

**注意**: 本指南基于 WireGuard 官方文档和最佳实践编写，建议定期查看更新。
