# 客户端安装指南

## 概述

IPv6 WireGuard Manager 提供了多种客户端安装方式，支持各种操作系统和设备类型。本指南将详细介绍如何在不同平台上安装和配置 WireGuard 客户端。

## 支持的客户端平台

### 桌面操作系统
- **Linux** (Ubuntu, Debian, CentOS, RHEL, Fedora, Rocky, AlmaLinux, Arch Linux)
- **Windows** (Windows 10/11)
- **macOS** (macOS 10.15+)

### 移动操作系统
- **Android** (Android 5.0+)
- **iOS** (iOS 12.0+)

## 安装方法

### 方法一：自动安装脚本（推荐）

#### 1. 生成客户端配置包

在服务器上添加客户端时，系统会自动生成完整的配置包：

```bash
# 启动管理器
ipv6-wg-manager

# 选择：客户端管理 -> 添加客户端
# 输入客户端名称，选择自动分配地址
```

系统会自动生成以下文件：
- `config.conf` - WireGuard客户端配置文件
- `install.sh` - 自动安装脚本（Linux/Unix）
- `qr.png` - QR码（移动设备）
- `README.txt` - 安装说明

#### 2. Linux/Unix 系统安装

**自动安装（推荐）：**
```bash
# 1. 将配置包复制到客户端设备
scp -r /etc/ipv6-wireguard/clients/client_name/ user@client_ip:/tmp/

# 2. 在客户端设备上运行安装脚本
cd /tmp/client_name/
sudo ./install.sh
```

**手动安装：**
```bash
# 1. 安装 WireGuard
# Ubuntu/Debian
sudo apt update
sudo apt install -y wireguard

# CentOS/RHEL/Fedora
sudo yum install -y epel-release
sudo yum install -y wireguard-tools

# Arch Linux
sudo pacman -S wireguard-tools

# 2. 配置客户端
sudo mkdir -p /etc/wireguard
sudo cp config.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf

# 3. 启动 WireGuard
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

#### 3. Windows 系统安装

**使用 WireGuard 官方客户端：**

1. **下载 WireGuard 客户端**
   - 访问：https://www.wireguard.com/install/
   - 下载 Windows 版本

2. **安装客户端**
   - 运行下载的安装程序
   - 按照提示完成安装

3. **导入配置**
   - 打开 WireGuard 客户端
   - 点击 "Add Tunnel" -> "Import from file"
   - 选择 `config.conf` 文件
   - 点击 "Add" 完成配置

4. **连接 VPN**
   - 在客户端列表中选择配置
   - 点击 "Activate" 连接

#### 4. macOS 系统安装

**使用 Homebrew 安装：**
```bash
# 1. 安装 WireGuard
brew install wireguard-tools

# 2. 配置客户端
sudo mkdir -p /etc/wireguard
sudo cp config.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf

# 3. 启动 WireGuard
sudo wg-quick up wg0
```

**使用官方客户端：**
1. 从 Mac App Store 下载 WireGuard 客户端
2. 导入 `config.conf` 配置文件
3. 点击连接按钮

### 方法二：移动设备安装

#### 1. Android 设备

**安装步骤：**
1. 从 Google Play Store 安装 WireGuard 应用
2. 打开应用，点击 "+" 按钮
3. 选择 "Create from QR code"
4. 扫描服务器生成的 `qr.png` 文件
5. 点击 "Add Tunnel" 完成配置
6. 点击隧道名称旁边的开关连接

**手动配置：**
1. 打开 WireGuard 应用
2. 点击 "+" -> "Create from file or archive"
3. 选择 `config.conf` 文件
4. 点击 "Add" 完成配置

#### 2. iOS 设备

**安装步骤：**
1. 从 App Store 安装 WireGuard 应用
2. 打开应用，点击 "+" 按钮
3. 选择 "Create from QR code"
4. 扫描服务器生成的 `qr.png` 文件
5. 点击 "Add Tunnel" 完成配置
6. 点击隧道名称旁边的开关连接

**手动配置：**
1. 打开 WireGuard 应用
2. 点击 "+" -> "Create from file or archive"
3. 选择 `config.conf` 文件
4. 点击 "Add" 完成配置

### 方法三：批量客户端安装

#### 1. 使用 CSV 文件批量添加

**创建客户端列表文件：**
```csv
# 客户端名称,IPv4地址,IPv6地址,描述
client1,auto,auto,测试客户端1
client2,10.0.0.100/32,2001:db8::100/128,指定地址客户端
mobile1,auto,auto,移动设备1
laptop1,auto,auto,笔记本电脑1
```

**在服务器上批量生成：**
```bash
ipv6-wg-manager
# 选择：客户端管理 -> 批量添加客户端
# 选择：使用CSV文件批量添加
# 输入文件路径：clients.csv
```

#### 2. 快速批量添加

```bash
ipv6-wg-manager
# 选择：客户端管理 -> 批量添加客户端
# 选择：快速批量添加
# 输入客户端数量：10
# 输入名称前缀：client
# 输入起始索引：1
```

## 客户端配置文件说明

### 配置文件结构

```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.0.0.2/32, 2001:db8::2/128
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = SERVER_IP:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### 配置参数说明

- **PrivateKey**: 客户端私钥（自动生成）
- **Address**: 客户端IP地址（IPv4和IPv6）
- **DNS**: DNS服务器地址
- **PublicKey**: 服务器公钥
- **Endpoint**: 服务器地址和端口
- **AllowedIPs**: 允许通过VPN的流量（0.0.0.0/0表示所有流量）
- **PersistentKeepalive**: 保持连接的心跳间隔

## IPv6 子网段支持

### 支持的子网段范围

客户端支持从 /56 到 /72 的灵活 IPv6 子网段分配：

| 网络前缀 | 客户端子网掩码 | 示例地址 | 说明 |
|---------|---------------|----------|------|
| /56     | /64          | 2001:db8::2/64 | 大型网络部署 |
| /57     | /65          | 2001:db8::2/65 | 中型网络部署 |
| /58     | /66          | 2001:db8::2/66 | 中型网络部署 |
| /59     | /67          | 2001:db8::2/67 | 小型网络部署 |
| /60     | /68          | 2001:db8::2/68 | 小型网络部署 |
| /61     | /69          | 2001:db8::2/69 | 小型网络部署 |
| /62     | /70          | 2001:db8::2/70 | 小型网络部署 |
| /63     | /71          | 2001:db8::2/71 | 小型网络部署 |
| /64     | /72          | 2001:db8::2/72 | 小型网络部署 |
| /65     | /73          | 2001:db8::2/73 | 超小型网络 |
| /66     | /74          | 2001:db8::2/74 | 超小型网络 |
| /67     | /75          | 2001:db8::2/75 | 超小型网络 |
| /68     | /76          | 2001:db8::2/76 | 超小型网络 |
| /69     | /77          | 2001:db8::2/77 | 超小型网络 |
| /70     | /78          | 2001:db8::2/78 | 超小型网络 |
| /71     | /79          | 2001:db8::2/79 | 超小型网络 |
| /72     | /80          | 2001:db8::2/80 | 超小型网络 |

### 自动子网掩码分配

系统会根据服务器网络前缀自动确定客户端子网掩码：
- 检测服务器网络配置
- 计算合适的客户端子网掩码
- 自动分配避免冲突的地址

## 连接验证

### 检查连接状态

**Linux/Unix/macOS：**
```bash
# 检查 WireGuard 状态
sudo wg show

# 检查网络接口
ip addr show wg0

# 测试连接
ping 10.0.0.1
ping6 2001:db8::1
```

**Windows：**
```bash
# 在 PowerShell 中检查
wg show

# 测试连接
ping 10.0.0.1
ping 2001:db8::1
```

**移动设备：**
- 打开 WireGuard 应用
- 查看连接状态和流量统计
- 测试网络连接

### 网络测试

```bash
# 测试 IPv4 连接
ping 8.8.8.8

# 测试 IPv6 连接
ping6 2001:4860:4860::8888

# 测试 DNS 解析
nslookup google.com

# 检查路由表
ip route show
```

## 故障排除

### 常见问题

#### 1. 连接失败

**检查项目：**
- 服务器是否在线
- 防火墙是否阻止连接
- 客户端配置是否正确
- 网络连接是否正常

**解决方法：**
```bash
# 检查服务器状态
ipv6-wg-manager
# 选择：服务器管理 -> 查看服务状态

# 检查客户端配置
sudo wg show

# 检查网络连接
ping SERVER_IP
```

#### 2. IPv6 连接问题

**检查项目：**
- 系统是否支持 IPv6
- 网络是否支持 IPv6
- 客户端配置中的 IPv6 地址

**解决方法：**
```bash
# 检查 IPv6 支持
ip -6 addr show

# 测试 IPv6 连接
ping6 2001:4860:4860::8888

# 检查 IPv6 路由
ip -6 route show
```

#### 3. DNS 解析问题

**检查项目：**
- DNS 服务器配置
- 网络连接
- 防火墙设置

**解决方法：**
```bash
# 测试 DNS 解析
nslookup google.com

# 更换 DNS 服务器
# 在客户端配置中修改 DNS 设置
```

#### 4. 移动设备连接问题

**检查项目：**
- 移动网络设置
- 应用权限
- 配置文件格式

**解决方法：**
- 重新扫描 QR 码
- 检查应用权限设置
- 重新导入配置文件

### 重新生成配置

如果客户端配置有问题，可以在服务器上重新生成：

```bash
ipv6-wg-manager
# 选择：客户端管理 -> 重新生成客户端配置
# 输入客户端名称
# 选择重新生成选项
```

## 安全建议

### 1. 密钥管理
- 定期轮换客户端密钥
- 安全存储私钥文件
- 不要共享私钥

### 2. 网络安全
- 使用强密码保护设备
- 定期更新客户端软件
- 监控连接日志

### 3. 配置管理
- 定期备份客户端配置
- 使用有意义的客户端名称
- 及时删除不需要的客户端

## 最佳实践

### 1. 安装建议
- 优先使用自动安装脚本
- 定期更新客户端软件
- 备份重要配置文件

### 2. 配置建议
- 使用自动地址分配避免冲突
- 配置合适的 DNS 服务器
- 设置合理的保持连接间隔

### 3. 维护建议
- 定期检查连接状态
- 监控网络性能
- 及时处理连接问题

## 总结

IPv6 WireGuard Manager 提供了完整的客户端安装解决方案，支持多种操作系统和设备类型。通过自动化的配置生成和安装脚本，可以大大简化客户端的部署和管理过程。

主要特点：
- ✅ 支持多种操作系统和设备
- ✅ 自动生成安装脚本和配置
- ✅ 支持批量客户端管理
- ✅ 灵活的 IPv6 子网段支持
- ✅ 完整的故障排除指南
- ✅ 安全的最佳实践建议

通过本指南，您可以轻松地为各种平台安装和配置 WireGuard 客户端，实现安全可靠的 VPN 连接。
