# IPv6 WireGuard Manager

一个功能强大的IPv6 WireGuard VPN服务器管理工具，支持IPv6前缀分发和BGP路由。版本 1.13 新增增强的BGP配置管理和诊断工具。

## 🚀 功能特性

### 核心功能
- **自动检测系统环境**并安装必要的依赖
- **配置 WireGuard VPN 服务器**
  - 支持交互式修改WireGuard端口
  - 自动检测端口占用情况
- **BIRD BGP 路由服务实现IPv6前缀分发**
  - **默认安装BIRD 2.x版本**，提供更好的性能和功能
  - 自动回退到BIRD 1.x版本（如果BIRD 2.x不可用）
  - 支持BIRD 1.x、2.x和3.x版本自动检测和配置
  - 支持宣告单段或多段IPv6地址
  - **新增交互式BGP配置**：Router ID、AS Number、Neighbors、Passwords、Multihop
- **服务端自动分配和管理 IPv6 子网**
  - 支持自定义IPv6段或者宣告ipv6子网（大于/48）
  - **正确的IPv6地址配置**：服务器使用具体IP地址（如2001:db8::1/64），客户端从子网段中分配
- **灵活的子网段支持**：支持从/56到/72的子网段范围，客户端自动获得合适的子网掩码
- **生成客户端配置文件和安装脚本**
- **跟踪和管理客户端分配状态**
- **防火墙配置**：自动配置防火墙规则，支持UFW、firewalld、nftables和iptables

### 管理功能
- **服务器管理** - 服务状态查看、启动/停止/重启服务、配置重载
- **客户端管理** - 添加/删除客户端、批量管理、配置生成
- **网络配置** - IPv6前缀管理（添加/删除/修改/统计）、BGP邻居配置、路由表查看、网络诊断
- **防火墙管理** - 规则查看/添加/删除、端口管理、服务管理
- **系统维护** - 日志查看、系统状态检查、性能监控、磁盘管理
- **BGP配置管理** - 交互式BGP配置、Router ID设置、AS Number管理、Neighbor配置、密码认证、Multihop设置
- **配置备份/恢复** - 自动备份、手动备份、配置恢复、导入/导出
- **更新检查** - 版本检查、自动更新、更新日志

### 优化特性
1. **模块化设计**
   - 将功能拆分为独立模块，提高代码可维护性
   - 支持两种运行方式：模块化版本和完整版本

2. **增强的错误处理**
   - 详细的错误日志，包含错误代码和描述
   - 关键函数的返回值检查
   - 安装失败时的回滚机制

3. **安全性增强**
   - 密钥轮换机制
   - 配置文件权限检查
   - 防火墙规则有效性验证

4. **可用性增强**
   - 交互式菜单系统，集成所有功能
   - 快速安装选项，一键完成配置
   - 交互式配置向导
   - 配置备份和恢复功能
   - 自动更新检查
   - 跨Linux发行版兼容性支持

5. **性能优化**
   - 并行处理独立任务
   - 缓存机制减少重复检测
   - 大量客户端场景下的性能优化

## 📋 系统要求

### 支持的操作系统
- **Ubuntu** 18.04+
- **Debian** 9+
- **CentOS** 7+
- **RHEL** 7+
- **Fedora** 30+
- **Rocky Linux** 8+
- **AlmaLinux** 8+
- **Arch Linux** 最新

### 硬件要求

#### 最低要求
- CPU: 1核心
- 内存: 512MB
- 磁盘: 1GB可用空间
- 网络: 公网IPv4地址
- BIRD: 2.x版本（默认安装，自动回退到1.x）

#### 推荐配置
- CPU: 2核心或更多
- 内存: 1GB或更多
- 磁盘: 5GB可用空间
- 网络: 公网IPv4地址 + IPv6地址
- BIRD: 2.x版本（默认安装，性能更佳）

### 网络要求
- **公网IPv4地址**: 必需，用于客户端连接
- **IPv6地址**: 可选，用于IPv6前缀分发
- **开放端口**: WireGuard端口（默认51820/UDP）
- **防火墙**: 支持UFW、firewalld、nftables或iptables

## 🛠️ 安装方法

### 快速安装（推荐）

1. **下载安装脚本**：
```bash
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
```

2. **运行安装脚本**：
```bash
sudo ./install.sh
```

3. **启动管理器**：
```bash
ipv6-wg-manager
```

**注意**: 安装脚本会自动检测系统环境并安装BIRD 2.x版本（如果可用），否则会安装BIRD 1.x版本作为备选。

## 📱 客户端安装

### 支持的平台
- **桌面系统**: Linux, Windows, macOS
- **移动设备**: Android, iOS
- **自动安装**: 支持自动生成安装脚本

### 一键安装脚本

我们提供了专门的客户端一键安装脚本，支持多种平台：

#### Linux/Unix 客户端
```bash
# 下载并运行客户端安装脚本
wget https://raw.githubusercontent.com/ipv6-wireguard-manager/ipv6-wireguard-manager/main/client-installer.sh
chmod +x client-installer.sh
./client-installer.sh
```

#### Windows 客户端
```powershell
# 下载并运行客户端安装脚本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ipv6-wireguard-manager/ipv6-wireguard-manager/main/client-installer.ps1" -OutFile "client-installer.ps1"
.\client-installer.ps1 -Install
```

### 客户端安装脚本特性

- ✅ **跨平台支持**: Linux、Windows、macOS
- ✅ **自动检测**: 自动检测操作系统和架构
- ✅ **智能安装**: 自动安装 WireGuard 依赖
- ✅ **多种配置方式**: 交互式配置、文件导入、QR 码扫描
- ✅ **一键启动**: 自动启动 WireGuard 客户端
- ✅ **状态监控**: 显示连接状态和配置信息
- ✅ **QR 码生成**: 生成配置 QR 码供移动设备使用

### 服务器端自动生成客户端安装包

- 🔧 **预配置脚本**: 服务器端自动生成包含所有配置的安装脚本
- 🔧 **零配置安装**: 客户端只需下载并运行，无需手动输入配置
- 🔧 **多平台支持**: 同时生成 Linux 和 Windows 安装脚本
- 🔧 **自动下载**: 提供多种下载方式（SCP、HTTP 服务器等）
- 🔧 **完整包**: 包含配置文件、安装脚本、QR 码和说明文档

### 自动下载必需文件

- 📥 **智能检测**: 自动检测缺失的模块和必需文件
- 📥 **一键下载**: 从 GitHub 自动下载所有必需文件
- 📥 **完整性验证**: 检查文件完整性并报告缺失文件
- 📥 **网络容错**: 支持部分下载失败时的重试机制
- 📥 **权限设置**: 自动设置正确的文件权限

### 客户端自动更新功能

- 🔄 **自动检查**: 定期检查服务器端是否有新版本
- 🔄 **智能更新**: 自动下载并安装最新版本
- 🔄 **配置保护**: 更新时自动备份现有配置
- 🔄 **无缝升级**: 更新过程中保持连接不断开
- 🔄 **版本管理**: 支持版本回滚和更新历史
- 🔄 **通知系统**: 更新时提供详细的通知和日志

### 传统安装方式

1. **在服务器上添加客户端**：
```bash
ipv6-wg-manager
# 选择：客户端管理 -> 添加客户端
# 输入客户端名称，选择自动分配地址
```

2. **在客户端设备上安装**：

**Linux/Unix（自动安装）：**
```bash
# 复制配置包到客户端
scp -r /etc/ipv6-wireguard/clients/client_name/ user@client_ip:/tmp/

# 运行自动安装脚本
cd /tmp/client_name/
sudo ./install.sh
```

**Windows：**
- 下载 WireGuard 客户端：https://www.wireguard.com/install/
- 导入 `config.conf` 配置文件

**移动设备：**
- 安装 WireGuard 应用
- 扫描生成的 QR 码

### 详细安装指南

完整的客户端安装说明请参考：[客户端安装指南](docs/CLIENT_INSTALLATION.md)

## 🚀 运行方式

IPv6 WireGuard Manager 提供两种运行方式：

### 方式1: 模块化版本（推荐）
```bash
./ipv6-wireguard-manager-core.sh
```
- **特点**: 轻量级核心脚本，按需加载功能模块
- **优势**: 启动更快，内存占用更少，便于维护
- **适用**: 日常使用和开发环境

### 方式2: 完整版本
```bash
./ipv6-wireguard-manager.sh
```
- **特点**: 包含所有功能的完整脚本
- **优势**: 无需模块文件，单文件部署
- **适用**: 离线环境或简化部署

### 使用符号链接
```bash
# 使用完整命令
ipv6-wg-manager

# 或使用简写命令
wg-manager
```

**建议**: 推荐使用模块化版本，它提供了更好的性能和可维护性。

## 📖 使用方法

### 启动管理器

```bash
# 使用模块化版本（推荐）
./ipv6-wireguard-manager-core.sh

# 或使用完整版本
./ipv6-wireguard-manager.sh

# 或使用符号链接
ipv6-wg-manager
```

### 主菜单功能

启动后您将看到以下主菜单：

```
主菜单:
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

#### 服务器管理功能

服务器管理模块包含以下功能：

```
服务器管理选项:
  1. 查看服务状态
  2. 启动服务
  3. 停止服务
  4. 重启服务
  5. 重载配置
  6. 查看服务日志
  7. 查看系统资源使用
  8. 查看网络连接
  9. BIRD诊断工具  ← 新增功能
  0. 返回主菜单
```

**BIRD诊断工具** 提供以下专业诊断功能：

- **综合诊断**: 全面检查BIRD安装、配置、服务和网络状态
- **安装诊断**: 检查BIRD安装状态、版本、控制工具和用户权限
- **配置诊断**: 验证配置文件语法、内容和权限设置
- **服务诊断**: 分析服务状态、systemd配置和启动失败原因
- **网络诊断**: 检查网络接口、IPv6转发和BGP连接状态
- **自动修复**: 自动修复权限问题、服务文件和网络配置
- **错误详情**: 显示详细的配置错误信息和修复建议

### 安装模式

#### 1. 快速安装模式
- 使用默认配置
- 适合快速部署
- 最小用户交互

#### 2. 交互式安装模式
- 完整配置向导
- 自定义所有参数
- 适合生产环境

## 🔧 功能详解

### 服务器管理
- 查看服务状态（WireGuard、BIRD、防火墙）
- 启动/停止/重启服务
- 重载配置
- 查看服务日志
- 系统资源监控
- 网络连接状态

### 客户端管理
- 添加单个客户端
- 批量添加客户端
- 删除客户端
- 生成客户端配置
- 客户端状态跟踪
- QR码生成（移动设备）
- **自动安装脚本生成** - 支持多平台自动安装
- **移动设备支持** - Android/iOS 扫码配置
- **灵活子网段支持** - 支持/56到/72的IPv6子网段

### 网络配置
- IPv6前缀管理
- BGP邻居配置
- 路由表查看
- 网络接口管理
- 网络诊断工具
- BGP状态监控

### BGP配置管理 (新增)
- **交互式BGP配置** - 完整的BGP参数配置向导
- **Router ID设置** - 自定义BGP Router ID
- **AS Number管理** - 配置本地和上游AS号
- **Neighbor管理** - 添加/编辑/删除BGP邻居
- **密码认证** - 配置BGP会话密码
- **Multihop设置** - 配置BGP多跳参数
- **IPv6 Prefix管理** - 管理BGP分发的IPv6前缀
- **配置验证** - 自动验证BGP配置语法
- **服务管理** - 启动/停止/重启BIRD服务

### 防火墙管理
- 防火墙状态查看
- 规则管理（添加/删除）
- 端口管理
- 服务管理
- 防火墙日志查看

### 系统维护
- 系统状态检查
- 性能监控
- 日志管理
- 磁盘空间管理
- 系统更新
- 进程管理
- 安全扫描

### 配置备份/恢复
- 创建配置备份
- 恢复配置备份
- 自动备份设置
- 配置导入/导出
- 备份文件管理

### 更新检查
- 检查更新
- 版本信息显示
- 更新管理器
- 系统包更新
- 自动更新设置

## 🐦 BIRD版本支持

### 支持的BIRD版本
- **BIRD 2.x** (推荐) - 默认安装版本，提供更好的性能和功能
- **BIRD 1.x** (兼容) - 自动回退版本，确保在BIRD 2.x不可用时仍能正常工作

### 版本选择策略
1. 优先尝试安装BIRD 2.x (`bird2`包)
2. 如果BIRD 2.x不可用，自动安装BIRD 1.x (`bird`包)
3. 支持所有主要Linux发行版

### 服务管理
- 自动检测已安装的BIRD版本
- 支持BIRD 1.x和2.x的服务管理
- 兼容不同的控制台命令 (`birdc` vs `birdc2`)

## 📁 项目结构

```
IPv6 WireGuard/
├── ipv6-wireguard-manager.sh          # 完整版本脚本
├── ipv6-wireguard-manager-core.sh     # 模块化版本脚本
├── install.sh                         # 安装脚本
├── uninstall.sh                       # 卸载脚本
├── modules/                           # 功能模块目录
│   ├── server_management.sh           # 服务器管理模块
│   ├── network_management.sh          # 网络管理模块
│   ├── firewall_management.sh         # 防火墙管理模块
│   ├── system_maintenance.sh          # 系统维护模块
│   ├── backup_restore.sh              # 备份恢复模块
│   ├── update_management.sh           # 更新管理模块
│   ├── client_management.sh           # 客户端管理模块
│   ├── bird_config.sh                 # BIRD配置模块
│   ├── firewall_config.sh             # 防火墙配置模块
│   ├── system_detection.sh            # 系统检测模块
│   └── wireguard_config.sh            # WireGuard配置模块
├── config/                           # 配置文件目录
├── examples/                         # 示例文件目录
├── scripts/                          # 辅助脚本目录
└── docs/                            # 文档目录
```

## 🔍 故障排除

### 常见问题

1. **权限问题**
   ```bash
   sudo ./ipv6-wireguard-manager-core.sh
   ```

2. **BIRD服务未启动**
   ```bash
   # 使用BIRD诊断工具（推荐）
   ./ipv6-wireguard-manager-core.sh
   # 选择: 3. 服务器管理 → 9. BIRD诊断工具 → 1. 综合诊断
   
   # 或手动检查
   systemctl status bird2  # BIRD 2.x
   systemctl status bird   # BIRD 1.x
   
   # 启动服务
   sudo systemctl start bird2  # BIRD 2.x
   sudo systemctl start bird   # BIRD 1.x
   ```

3. **防火墙问题**
   ```bash
   # 检查防火墙状态
   sudo ufw status          # Ubuntu/Debian
   sudo firewall-cmd --state # CentOS/RHEL/Fedora
   ```

4. **端口占用**
   ```bash
   # 检查端口占用
   sudo netstat -tulpn | grep 51820
   ```

### BIRD诊断工具使用指南

当遇到BIRD相关问题时，推荐使用内置的BIRD诊断工具：

#### 1. 启动诊断工具
```bash
./ipv6-wireguard-manager-core.sh
# 选择: 3. 服务器管理 → 9. BIRD诊断工具
```

#### 2. 诊断选项说明

**综合诊断（推荐）**
- 运行所有检查项目
- 提供完整的问题报告
- 适合首次诊断或全面检查

**安装诊断**
- 检查BIRD是否已安装
- 验证BIRD版本和控制工具
- 检查用户和组权限
- 检查目录权限设置

**配置诊断**
- 验证配置文件语法
- 检查配置文件内容
- 验证路由器ID和AS号
- 检查IPv6和BGP配置

**服务诊断**
- 检查systemd服务文件
- 分析服务启动失败原因
- 查看系统日志
- 检查端口占用情况

**网络诊断**
- 检查WireGuard接口状态
- 验证IPv6转发设置
- 检查BGP邻居连接
- 分析路由表状态

**自动修复**
- 自动修复权限问题
- 重新创建systemd服务文件
- 启用IPv6转发
- 尝试启动BIRD服务

**错误详情**
- 显示详细的配置错误
- 提供具体的修复建议
- 包含常见错误解决方案

### WireGuard服务启动失败

如果遇到WireGuard服务启动失败的问题：

#### 1. 快速诊断
```bash
# 查看详细错误信息
sudo systemctl status wg-quick@wg0.service
sudo journalctl -xeu wg-quick@wg0.service

# 检查配置文件
sudo cat /etc/wireguard/wg0.conf
```

#### 2. 常见解决方案
```bash
# 方案1：重新生成配置
ipv6-wg-manager
# 选择：3. 服务器管理 -> 重新配置 WireGuard

# 方案2：修复权限问题
sudo chmod 600 /etc/wireguard/wg0.conf
sudo chown root:root /etc/wireguard/wg0.conf

# 方案3：启用IPv6支持
echo 0 | sudo tee /proc/sys/net/ipv6/conf/all/disable_ipv6

# 方案4：加载WireGuard模块
sudo modprobe wireguard

# 方案5：检查防火墙设置
sudo ufw allow 51820/udp
sudo ufw reload
```

#### 3. 验证修复
```bash
# 启动服务
sudo systemctl start wg-quick@wg0.service

# 检查状态
sudo systemctl status wg-quick@wg0.service
sudo wg show
```

#### 3. 诊断输出示例

```
=== BIRD综合诊断 ===
开始全面诊断BIRD安装、配置和服务状态...

=== BIRD安装诊断 ===
1. 检查BIRD安装状态...
✓ BIRD已安装
   版本: BIRD 2.0.10

2. 检查BIRD控制工具...
✓ BIRD控制工具已安装

3. 检查BIRD用户和组...
✓ BIRD用户存在
✓ BIRD组存在

4. 检查BIRD目录权限...
✓ /etc/bird 权限正确 (bird:bird)
✓ /var/lib/bird 权限正确 (bird:bird)
✓ /var/log/bird 权限正确 (bird:bird)
✓ /var/run/bird 权限正确 (bird:bird)

=== BIRD配置诊断 ===
1. 检查BIRD配置文件...
✓ 配置文件存在: /etc/bird/bird.conf
✓ 配置文件权限正确 (bird:bird)

2. 检查配置文件语法...
✓ 配置文件语法正确

3. 检查配置文件内容...
✓ 路由器ID已配置: 10.0.0.1
✓ BGP协议已配置
✓ IPv6支持已配置

=== BIRD服务诊断 ===
1. 检查systemd服务文件...
✓ systemd服务文件存在
✓ 服务文件配置正确

2. 检查BIRD服务状态...
✓ BIRD服务正在运行
✓ BIRD服务已启用

=== BIRD网络诊断 ===
1. 检查网络接口...
✓ WireGuard接口 wg0 存在
   状态: state UP
✓ WireGuard接口有IPv6地址
   inet6 2001:db8::1/64 scope global

2. 检查IPv6转发...
✓ IPv6转发已启用

3. 检查BGP邻居连接...
✓ BGP协议已配置
✓ 有BGP邻居已建立连接

4. 检查路由表...
✓ 发现 15 条IPv6路由
✓ BIRD管理 8 条路由

=== 诊断总结 ===
✓ BIRD综合诊断完成，未发现任何问题
BIRD服务运行正常，可以正常使用BGP功能
```

#### 4. 常见问题修复

**权限问题**
```bash
# 诊断工具会自动提供修复命令
sudo chown -R bird:bird /etc/bird /var/lib/bird /var/log/bird /var/run/bird
```

**配置文件语法错误**
```bash
# 检查配置文件语法
sudo birdc configure
# 或
sudo birdc2 configure
```

**服务启动失败**
```bash
# 查看详细日志
sudo journalctl -u bird -f
# 或
sudo journalctl -u bird2 -f
```

**IPv6转发未启用**
```bash
# 启用IPv6转发
echo 1 | sudo tee /proc/sys/net/ipv6/conf/all/forwarding
```

**IPv6地址配置错误**
- 问题：WireGuard接口使用子网段作为地址（如2001:db8::/48）
- 解决：服务器使用具体IP地址（如2001:db8::1/64），客户端从子网段分配
- 自动修复：管理器会自动将子网段转换为正确的服务器地址

## 📚 文档

- [快速启动指南](QUICK_START.md) - 快速开始使用
- [安装指南](docs/INSTALLATION.md) - 详细安装说明
- [使用指南](docs/USAGE.md) - 功能使用说明
- [BIRD版本兼容性](docs/BIRD_VERSION_COMPATIBILITY.md) - BIRD版本支持说明
- [模块化架构](MODULAR_ARCHITECTURE.md) - 架构设计说明
- [项目总结](PROJECT_SUMMARY.md) - 项目功能总结
- [更新日志](CHANGELOG.md) - 版本更新记录

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 📄 许可证

本项目采用MIT许可证。

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者。

---

**推荐**: 使用模块化版本 `./ipv6-wireguard-manager-core.sh` 获得最佳性能体验。