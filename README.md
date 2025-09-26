# IPv6 WireGuard Manager

一个功能完整的IPv6 WireGuard VPN服务器管理系统，支持自动环境检测、BGP路由、客户端管理、Web界面等企业级功能。

## ✨ 主要特性

- 🚀 **智能安装** - 一键安装全部功能，交互式安装可选择功能
- 🔧 **自动配置** - WireGuard服务器、BIRD BGP路由、IPv6子网管理
- 🛡️ **安全增强** - 最小权限原则、systemd安全特性、防火墙自动配置
- 🔥 **智能防火墙** - 自动检测防火墙类型，智能开放功能端口
- 👥 **客户端管理** - 完整的客户端生命周期管理
- 🌐 **Web界面** - 现代化的Web管理界面
- 📊 **监控告警** - 实时监控、邮件/Webhook告警
- 🔄 **自动更新** - 版本检查、自动更新、回滚功能
- 📦 **批量操作** - CSV导入、批量管理、远程安装
- ⚙️ **功能管理** - 动态启用/禁用功能模块，灵活配置
- 🔐 **OAuth 2.0认证** - 企业级认证授权系统
- 🔒 **多因素认证** - MFA和TOTP安全认证
- 🛡️ **安全审计** - 完整的操作审计和监控
- 🎯 **网络拓扑可视化** - 交互式网络拓扑图展示
- 📚 **API文档** - 完整OpenAPI文档和Swagger UI
- 🔄 **实时通信** - WebSocket双向实时通信
- 🏢 **多租户支持** - 组织项目隔离和资源配额
- ⚡ **性能优化** - 懒加载机制和性能监控

## 🚀 快速开始

### 方法1: 一键安装（推荐）

```bash
# 自动安装 - 安装所有功能
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 手动下载安装
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

### 方法2: 交互式安装

```bash
# 运行安装脚本
sudo ./install.sh

# 选择安装选项
# 1. 快速安装 - 安装所有功能
# 2. 交互式安装 - 自定义配置
# 3. 仅下载文件 - 不安装

# 交互式安装选项
# 1. 完整安装 - 所有功能
# 2. 最小安装 - 仅核心功能
# 3. 自定义安装 - 选择组件
```

### 方法3: 从源码安装

```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行安装脚本
sudo ./install.sh
```

### 方法4: 自定义仓库安装

```bash
# 使用环境变量配置仓库地址
export REPO_OWNER="your-username"
export REPO_NAME="your-repo-name"
export REPO_BRANCH="main"
export REPO_URL="https://github.com/your-username/your-repo-name"
export RAW_URL="https://raw.githubusercontent.com/your-username/your-repo-name/main"

# 运行安装
curl -sSL $RAW_URL/install.sh | bash
```

## 📋 系统要求

### 支持的操作系统
- Ubuntu 18.04+ / Debian 9+
- CentOS 7+ / RHEL 7+
- Fedora 30+ / Rocky Linux 8+ / AlmaLinux 8+
- Arch Linux / openSUSE 15+
- Windows子系统 (WSL、MSYS2、Cygwin)

### 依赖要求
- WireGuard
- BIRD (1.x/2.x/3.x)
- 防火墙工具 (UFW/firewalld/nftables/iptables)
- 网络工具 (iproute2, net-tools)

## 🎯 主要功能

### 1. 智能安装系统
- **一键安装** - 自动安装所有功能模块
- **交互式安装** - 用户可选择安装类型和功能
- **自定义安装** - 精确控制安装内容
- **功能管理** - 动态启用/禁用功能模块

### 2. 服务器管理
- 服务状态查看、启动/停止/重启
- 配置重载、日志查看
- 系统资源监控、网络连接诊断
- BIRD和WireGuard诊断工具

### 3. 客户端管理
- 添加/删除/修改客户端
- 配置生成、QR码生成
- 批量导入/导出 (CSV)
- 实时状态监控
- 客户端数据库管理

### 4. 网络配置
- IPv6前缀管理 (/56到/72范围)
- BGP邻居配置
- 路由表查看、网络诊断
- BGP配置向导

### 5. 智能防火墙管理
- **自动检测** - 检测UFW、firewalld、nftables、iptables
- **智能配置** - 根据功能自动开放端口
- **端口管理** - 批量端口操作、状态监控
- **规则管理** - 防火墙规则管理、安全扫描

### 6. 客户端自动安装
- 一键安装链接生成
- 远程自动安装 (SSH/API)
- 多平台支持 (Linux/Windows/macOS/Android/iOS)
- 安全令牌验证

### 7. Web管理界面
- 现代化Web界面
- 实时状态监控
- 客户端管理
- 用户认证和权限控制

### 8. 监控告警系统
- 实时监控客户端连接状态
- 邮件和Webhook告警
- 性能监控、日志分析
- 自动重连和离线警报

### 9. 配置备份恢复
- 自动备份配置
- 手动备份/恢复
- 配置导入/导出
- 版本管理

### 10. 高级功能
- **网络拓扑可视化** - 交互式网络拓扑图展示
- **API文档系统** - 完整OpenAPI文档和Swagger UI
- **实时通信** - WebSocket双向实时通信
- **多租户支持** - 组织项目隔离和资源配额
- **性能优化** - 懒加载机制和性能监控
- **配置懒加载** - 优化启动性能和内存使用

### 11. 更新检查
- 版本检查、自动更新
- 更新日志、版本回滚
- 更新设置、清理功能

### 12. 安全增强
- BIRD权限配置 (最小权限原则)
- systemd安全特性
- 密钥轮换、权限检查
- 防火墙验证

### 12. 功能管理
- **功能状态** - 查看已安装和未安装的功能
- **动态控制** - 运行时启用/禁用功能
- **依赖检查** - 检查功能依赖关系
- **重新安装** - 重新安装功能模块

### 13. 配置管理
- **YAML配置** - 标准化的YAML配置管理
- **配置验证** - 配置语法和有效性验证
- **版本控制** - 配置版本管理和回滚
- **模板管理** - 配置模板创建和管理

### 14. 增强Web界面
- **实时监控** - 实时系统状态显示
- **用户管理** - 完整的用户权限管理
- **API接口** - RESTful API接口
- **响应式设计** - 现代化响应式界面

### 15. OAuth认证管理
- **OAuth 2.0** - 标准OAuth 2.0认证
- **多因素认证** - TOTP和备用代码支持
- **角色权限** - 基于角色的访问控制
- **令牌管理** - 安全的令牌生命周期管理

### 16. 安全审计监控
- **操作审计** - 完整的操作日志记录
- **安全事件** - 安全事件监控和告警
- **漏洞管理** - 安全漏洞管理
- **实时监控** - 实时安全状态监控

## 🏗️ 项目结构

```
ipv6-wireguard-manager/
├── ipv6-wireguard-manager.sh          # 主脚本
├── install.sh                         # 安装脚本
├── uninstall.sh                       # 卸载脚本
├── modules/                           # 功能模块
│   ├── common_functions.sh            # 公共函数库
│   ├── system_detection.sh            # 系统检测
│   ├── wireguard_config.sh            # WireGuard配置
│   ├── bird_config.sh                 # BIRD BGP配置
│   ├── network_management.sh          # 网络管理
│   ├── firewall_management.sh         # 防火墙管理
│   ├── client_management.sh           # 客户端管理
│   ├── client_auto_install.sh         # 客户端自动安装
│   ├── web_management.sh              # Web管理界面
│   ├── monitoring_alerting.sh         # 监控告警
│   ├── backup_restore.sh              # 备份恢复
│   ├── update_management.sh           # 更新管理
│   ├── repository_config.sh           # 仓库配置
│   └── ...
├── config/                            # 配置文件
│   ├── manager.conf                   # 主配置文件
│   ├── bird_template.conf             # BIRD配置模板
│   └── ...
├── examples/                          # 示例文件
│   ├── clients.csv                    # 客户端CSV模板
│   ├── bgp_neighbors.conf             # BGP邻居配置示例
│   └── ...
└── docs/                              # 文档
    ├── INSTALLATION.md                # 安装指南
    └── USAGE.md                       # 使用指南
```

## 🎮 使用方法

### 启动管理界面

```bash
# 启动主管理界面
sudo ipv6-wireguard-manager

# 或者直接运行脚本
sudo ./ipv6-wireguard-manager.sh
```

### 主菜单功能

```
主菜单:
1.  快速安装 - 一键配置所有服务
2.  交互式安装 - 自定义配置安装
3.  服务器管理 - 服务状态管理
4.  客户端管理 - 客户端配置管理
5.  客户端自动安装 - 生成安装链接和远程安装 (可选)
6.  Web管理界面 - 启动Web管理界面 (可选)
7.  网络配置 - IPv6前缀和BGP配置
8.  BGP配置管理 - BGP路由配置
9.  防火墙管理 - 防火墙规则管理 (可选)
10. 配置备份/恢复 - 配置备份和恢复 (可选)
11. 监控告警系统 - 监控和告警系统 (可选)
12. 系统维护 - 系统状态和日志管理
13. 更新检查 - 版本更新检查 (可选)
14. 安全增强功能 - 安全扫描和增强 (可选)
15. 用户界面功能 - 界面优化和主题
16. 下载必需文件 - 下载缺失的文件
17. 功能管理 - 启用/禁用功能模块
18. 配置管理 - YAML配置管理 (可选)
19. 增强Web界面 - 实时状态和用户管理 (可选)
20. OAuth认证管理 - OAuth 2.0和MFA (可选)
21. 安全审计监控 - 安全事件和漏洞管理 (可选)
0.  退出
```

**注意**: 标记为"(可选)"的功能需要先安装才能使用，可通过功能管理菜单启用。

## 🔧 配置说明

### 环境变量配置

```bash
# 仓库配置（可选）
export REPO_OWNER="ipzh"
export REPO_NAME="ipv6-wireguard-manager"
export REPO_BRANCH="main"
export REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager"
export RAW_URL="https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main"

# 功能选择配置（安装时使用）
export INSTALL_WIREGUARD=true                    # WireGuard VPN服务
export INSTALL_BIRD=true                         # BIRD BGP路由服务
export INSTALL_FIREWALL=true                     # 防火墙管理功能
export INSTALL_WEB_INTERFACE=true                # Web管理界面
export INSTALL_MONITORING=true                   # 监控告警系统
export INSTALL_CLIENT_AUTO_INSTALL=true          # 客户端自动安装功能
export INSTALL_BACKUP_RESTORE=true               # 配置备份恢复功能
export INSTALL_UPDATE_MANAGEMENT=true            # 更新管理功能
export INSTALL_SECURITY_ENHANCEMENTS=true        # 安全增强功能
export INSTALL_CONFIG_MANAGEMENT=true            # 配置管理功能
export INSTALL_WEB_INTERFACE_ENHANCED=true       # 增强Web界面功能
export INSTALL_OAUTH_AUTHENTICATION=true         # OAuth认证功能
export INSTALL_SECURITY_AUDIT_MONITORING=true    # 安全审计监控功能
```

### 主要配置文件

- `/etc/ipv6-wireguard-manager/manager.conf` - 主配置文件
- `/etc/ipv6-wireguard-manager/repository.conf` - 仓库配置
- `/etc/bird/bird.conf` - BIRD IPv4配置
- `/etc/bird/bird6.conf` - BIRD IPv6配置
- `/etc/wireguard/wg0.conf` - WireGuard配置

## 📚 文档

- [安装指南](docs/INSTALLATION.md) - 详细的安装说明
- [使用指南](docs/USAGE.md) - 功能使用说明

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者！

---

**IPv6 WireGuard Manager** - 让IPv6 WireGuard VPN管理变得简单高效！