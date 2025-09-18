# 客户端安装包生成和使用示例

## 概述

IPv6 WireGuard Manager 现在支持从服务器端自动生成预配置的客户端安装包，客户端只需下载并运行即可完成安装，无需手动输入任何配置信息。

## 服务器端操作

### 1. 添加客户端

```bash
# 启动管理器
ipv6-wg-manager

# 选择：4. 客户端管理
# 选择：1. 添加客户端
# 输入客户端名称：my-client
# 选择：1. 自动分配地址
```

### 2. 生成客户端安装包

```bash
# 在客户端管理菜单中选择：6. 生成客户端安装包 (自动安装脚本)
# 输入客户端名称：my-client
# 输入输出目录：/tmp/client-packages/my-client
```

### 3. 查看生成的文件

```bash
ls -la /tmp/client-packages/my-client/
```

输出示例：
```
total 48K
-rw-r--r-- 1 root root  1.2K my-client.conf
-rw-r--r-- 1 root root  2.1K install-linux.sh
-rw-r--r-- 1 root root  3.4K install-windows.ps1
-rw-r--r-- 1 root root  1.5K my-client-qr.png
-rw-r--r-- 1 root root  1.8K README.md
```

## 客户端安装

### Linux/Unix 客户端

#### 方法1：直接下载运行
```bash
# 下载安装脚本
scp user@server:/tmp/client-packages/my-client/install-linux.sh /tmp/
chmod +x /tmp/install-linux.sh
./install-linux.sh
```

#### 方法2：通过 HTTP 服务器
```bash
# 在服务器上启动 HTTP 服务器
cd /tmp/client-packages/my-client
python3 -m http.server 8000

# 在客户端下载并运行
wget http://server-ip:8000/install-linux.sh
chmod +x install-linux.sh
./install-linux.sh
```

### Windows 客户端

#### 方法1：PowerShell 下载运行
```powershell
# 下载安装脚本
Invoke-WebRequest -Uri "http://server-ip:8000/install-windows.ps1" -OutFile "install-windows.ps1"

# 运行安装脚本
.\install-windows.ps1
```

#### 方法2：手动下载
1. 访问 `http://server-ip:8000/`
2. 下载 `install-windows.ps1`
3. 以管理员权限运行 PowerShell
4. 执行 `.\install-windows.ps1`

### 移动设备

1. 下载 WireGuard 应用
2. 扫描 `my-client-qr.png` QR 码
3. 连接 VPN

## 安装过程示例

### Linux 安装过程

```bash
$ ./install-linux.sh

╔══════════════════════════════════════════════════════════════╗
║                IPv6 WireGuard 客户端自动安装                ║
║                    客户端: my-client                        ║
╚══════════════════════════════════════════════════════════════╝

此脚本将自动安装和配置 WireGuard 客户端
服务器: your-server.com:51820
客户端: my-client

[INFO] 检测到操作系统: ubuntu 22.04 (x86_64)
[INFO] 创建客户端配置目录...
[INFO] 配置目录: /home/user/.config/wireguard
[INFO] 日志目录: /home/user/.local/log/wireguard
[INFO] 正在安装 WireGuard...
[INFO] WireGuard 安装完成
[INFO] 生成客户端配置: my-client
[INFO] 客户端配置已生成: /home/user/.config/wireguard/my-client.conf
[INFO] 启动 WireGuard 客户端: my-client
[INFO] WireGuard 客户端已启动

═══════════════════════════════════════════════════════════════
                        客户端状态                          
═══════════════════════════════════════════════════════════════

WireGuard 接口状态:
interface: wg0
  public key: <client-public-key>
  private key: (hidden)
  listening port: 51820

peer: <server-public-key>
  endpoint: your-server.com:51820
  allowed ips: 0.0.0.0/0, ::/0
  latest handshake: 2 minutes, 15 seconds ago
  transfer: 1.2 MB received, 856 KB sent

配置文件: /home/user/.config/wireguard/my-client.conf

[INFO] 客户端安装完成!
配置文件位置: /home/user/.config/wireguard/my-client.conf
日志文件位置: /home/user/.local/log/wireguard

常用命令:
  启动: sudo wg-quick up my-client
  停止: sudo wg-quick down my-client
  状态: sudo wg show
  日志: sudo journalctl -u wg-quick@my-client
```

### Windows 安装过程

```powershell
PS C:\Users\User> .\install-windows.ps1

╔══════════════════════════════════════════════════════════════╗
║                IPv6 WireGuard 客户端自动安装                ║
║                    客户端: my-client                        ║
╚══════════════════════════════════════════════════════════════╝

此脚本将自动安装和配置 WireGuard 客户端
服务器: your-server.com:51820
客户端: my-client

[INFO] 创建客户端配置目录...
[INFO] 配置目录: C:\Users\User\.config\wireguard
[INFO] 日志目录: C:\Users\User\.local\log\wireguard
[INFO] 正在安装 WireGuard...
[INFO] WireGuard 安装完成
[INFO] 生成客户端配置: my-client
[INFO] 客户端配置已生成: C:\Users\User\.config\wireguard\my-client.conf
[INFO] 启动 WireGuard 客户端: my-client
[INFO] WireGuard 客户端已启动

═══════════════════════════════════════════════════════════════
                        客户端状态                          
═══════════════════════════════════════════════════════════════

配置文件: C:\Users\User\.config\wireguard\my-client.conf
配置内容:
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/32, 2001:db8::2/64
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25

[INFO] 客户端安装完成!
配置文件位置: C:\Users\User\.config\wireguard\my-client.conf
日志文件位置: C:\Users\User\.local\log\wireguard

常用操作:
  启动: 使用 WireGuard 图形界面导入配置文件
  停止: 在 WireGuard 图形界面中禁用隧道
  状态: 在 WireGuard 图形界面中查看连接状态
```

## 高级功能

### 批量生成客户端安装包

```bash
# 在客户端管理菜单中选择：7. 批量生成客户端
# 输入配置文件路径：/path/to/clients.csv
# 选择：2. 自动分配地址
```

### 通过 HTTP 服务器分发

```bash
# 在服务器上启动 HTTP 服务器
cd /tmp/client-packages
python3 -m http.server 8000

# 客户端访问
# http://server-ip:8000/my-client/
```

### 自定义配置

安装脚本支持以下参数：

#### Linux 脚本
```bash
# 查看帮助
./install-linux.sh --help

# 自定义安装目录
./install-linux.sh --config-dir /custom/path
```

#### Windows 脚本
```powershell
# 查看帮助
.\install-windows.ps1 -Help

# 只安装不启动
.\install-windows.ps1 -Install -Start:$false

# 指定配置文件
.\install-windows.ps1 -ConfigFile "C:\path\to\config.conf"
```

## 故障排除

### 常见问题

1. **权限问题**
   ```bash
   # Linux
   sudo chmod +x install-linux.sh
   sudo ./install-linux.sh
   
   # Windows
   # 以管理员权限运行 PowerShell
   ```

2. **网络连接问题**
   ```bash
   # 检查服务器连接
   ping your-server.com
   telnet your-server.com 51820
   ```

3. **WireGuard 安装失败**
   ```bash
   # 手动安装 WireGuard
   sudo apt update
   sudo apt install wireguard
   ```

4. **配置文件问题**
   ```bash
   # 检查配置文件
   cat ~/.config/wireguard/my-client.conf
   
   # 验证配置
   wg-quick strip my-client
   ```

### 日志查看

#### Linux
```bash
# 查看系统日志
sudo journalctl -u wg-quick@my-client -f

# 查看 WireGuard 状态
sudo wg show
```

#### Windows
```powershell
# 查看事件日志
Get-WinEvent -LogName "Application" | Where-Object {$_.ProviderName -like "*WireGuard*"}

# 查看配置文件
Get-Content "$env:USERPROFILE\.config\wireguard\my-client.conf"
```

## 安全建议

1. **保护私钥**: 确保客户端私钥文件权限正确
2. **定期更新**: 定期更新 WireGuard 版本
3. **监控连接**: 监控客户端连接状态
4. **备份配置**: 定期备份客户端配置

## 自动更新功能

### 更新检查

客户端安装后自动包含更新功能：

```bash
# 检查更新
./update.sh check

# 手动更新
./update.sh update

# 自动更新检查
./update.sh auto

# 配置自动更新
./update.sh config
```

### 更新配置

```bash
# 更新配置文件位置
~/.config/wireguard/update.conf

# 配置选项：
# - AUTO_UPDATE_ENABLED: 启用/禁用自动更新
# - UPDATE_CHECK_INTERVAL: 检查间隔（秒）
# - UPDATE_SERVER_URL: 更新服务器地址
# - UPDATE_LOG_FILE: 更新日志文件
```

### 更新流程

1. **定期检查**: 每小时检查一次更新
2. **版本比较**: 比较当前版本和最新版本
3. **下载更新**: 自动下载最新版本
4. **备份配置**: 自动备份现有配置
5. **安装更新**: 静默安装新版本
6. **重启服务**: 自动重启 WireGuard 服务

## 高级功能

### 批量客户端管理

```bash
# 批量生成客户端安装包
# 选择：4. 客户端管理 -> 7. 批量生成客户端

# 从 CSV 文件批量生成
# CSV 格式：
# client_name,ipv4_address,ipv6_address,notes
# client1,10.0.0.2/32,2001:db8::2/64,测试客户端1
# client2,10.0.0.3/32,2001:db8::3/64,测试客户端2
```

### 监控和统计

```bash
# 监控客户端连接
# 选择：4. 客户端管理 -> 10. 监控客户端连接

# 显示信息：
# - 客户端连接状态
# - 数据传输统计
# - 连接时间
# - 最后握手时间
```

### 系统维护

```bash
# 系统维护功能
# 选择：7. 系统维护

# 子菜单：
#   1. 系统信息查看
#   2. 服务状态检查
#   3. 日志文件管理
#   4. 磁盘空间检查
#   5. 网络连接测试
#   6. 性能监控
#   7. 清理临时文件
#   8. 系统优化建议
#   0. 返回主菜单
```

## 总结

客户端安装包功能大大简化了 WireGuard 客户端的部署过程：

- ✅ **零配置**: 客户端无需手动输入任何配置
- ✅ **跨平台**: 支持 Linux、Windows、macOS
- ✅ **自动化**: 自动安装依赖和启动服务
- ✅ **用户友好**: 提供详细的安装过程和状态信息
- ✅ **灵活分发**: 支持多种下载和分发方式
- ✅ **自动更新**: 客户端自动检查和安装更新
- ✅ **监控管理**: 实时监控客户端连接状态
- ✅ **批量操作**: 支持批量客户端管理

这使得 IPv6 WireGuard Manager 成为一个真正的一站式 VPN 解决方案。
