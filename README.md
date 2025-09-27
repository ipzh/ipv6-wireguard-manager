# IPv6 WireGuard Manager

一个完整的IPv6 WireGuard VPN服务器管理系统，提供自动化的安装、配置和管理功能。

## 🚀 功能特性

### 核心功能
- **自动化安装** - 一键安装所有必要组件
- **IPv6支持** - 完整的IPv6网络配置
- **BGP路由** - 集成BIRD BGP路由器
- **Web管理界面** - 直观的Web管理界面
- **客户端管理** - 自动生成和管理客户端配置
- **安全增强** - 多层安全防护机制

### 高级功能
- **懒加载机制** - 优化系统性能和启动时间
- **统一配置管理** - 集中化配置管理
- **系统监控** - 实时系统状态监控
- **自我诊断** - 自动故障检测和修复
- **备份恢复** - 自动备份和恢复功能
- **更新检查** - 自动检查和安装更新

## 📋 系统要求

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

## 🛠️ 快速开始

### 一键安装
```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh | bash
```

### 手动安装
```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行安装脚本
sudo ./install.sh
```

### 下载安装
```bash
# 使用下载安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install_with_download.sh | bash
```

## 📖 使用指南

### 基本使用
```bash
# 启动管理程序
sudo ipv6-wireguard-manager

# 查看帮助
ipv6-wireguard-manager --help

# 查看版本
ipv6-wireguard-manager --version
```

### 服务管理
```bash
# 启动服务
sudo systemctl start ipv6-wireguard-manager
sudo systemctl start wg-quick@wg0
sudo systemctl start bird

# 停止服务
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl stop wg-quick@wg0
sudo systemctl stop bird

# 查看状态
sudo systemctl status ipv6-wireguard-manager
```

### Web管理界面
- **访问地址**: `http://YOUR_SERVER_IP:8080`
- **默认用户名**: admin
- **默认密码**: admin123

**重要**: 首次登录后请立即修改默认密码！

## 🔧 配置说明

### 主配置文件
- **位置**: `/etc/ipv6-wireguard-manager/manager.conf`
- **格式**: 键值对格式
- **版本**: 支持配置版本管理和迁移

### 关键配置项
```bash
# WireGuard配置
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
WIREGUARD_NETWORK=10.0.0.0/24

# IPv6配置
IPV6_PREFIX=2001:db8::/56

# Web界面配置
WEB_PORT=8080
WEB_USER=admin
WEB_PASS=admin123

# 功能开关
INSTALL_WIREGUARD=true
INSTALL_BIRD=true
INSTALL_FIREWALL=true
INSTALL_WEB_INTERFACE=true
```

## 🧪 测试和诊断

### 自动化测试
```bash
# 运行完整测试套件
sudo ./scripts/automated-testing.sh

# 运行特定测试
sudo ./scripts/automated-testing.sh --syntax-check
sudo ./scripts/automated-testing.sh --functionality-test
```

### 系统诊断
```bash
# 快速诊断
sudo ipv6-wireguard-manager --diagnose

# 完整诊断
sudo ipv6-wireguard-manager --full-diagnose
```

### 监控功能
```bash
# 启动系统监控
sudo ipv6-wireguard-manager --monitor

# 查看监控状态
sudo ipv6-wireguard-manager --monitor-status
```

## 📁 项目结构

```
ipv6-wireguard-manager/
├── ipv6-wireguard-manager.sh    # 主管理脚本
├── install.sh                   # 安装脚本
├── uninstall.sh                 # 卸载脚本
├── install_with_download.sh     # 下载安装脚本
├── modules/                     # 功能模块
│   ├── common_functions.sh      # 公共函数库
│   ├── unified_config.sh        # 统一配置管理
│   ├── lazy_loading.sh          # 懒加载模块
│   ├── common_utils.sh          # 通用工具函数
│   ├── system_monitoring.sh     # 系统监控
│   ├── self_diagnosis.sh        # 自我诊断
│   └── ...
├── scripts/                     # 脚本目录
│   └── automated-testing.sh     # 自动化测试
├── examples/                    # 配置示例
│   ├── wireguard-server.conf    # WireGuard服务器配置
│   ├── wireguard-client.conf    # WireGuard客户端配置
│   ├── bird.conf                # BIRD BGP配置
│   └── ...
├── docs/                        # 文档目录
│   ├── INSTALLATION_GUIDE.md    # 安装指南
│   └── reports/                 # 报告文件
└── README.md                    # 项目说明
```

## 🔄 更新和维护

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

### 卸载
```bash
# 完全卸载
sudo ./uninstall.sh --complete

# 保留配置卸载
sudo ./uninstall.sh --quick

# 自定义卸载
sudo ./uninstall.sh --interactive
```

## 🐛 故障排除

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
```bash
# 查看所有相关日志
sudo journalctl -u ipv6-wireguard-manager -u wg-quick@wg0 -u bird -f

# 查看WireGuard详细日志
sudo wg show wg0
```

## 🤝 贡献

我们欢迎各种形式的贡献！

### 报告问题
- 使用 [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues) 报告bug
- 提供详细的错误信息和复现步骤

### 提交代码
1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 文档改进
- 改进文档和注释
- 添加使用示例
- 翻译文档

## 📄 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者和用户！

## 📞 支持

### 获取帮助
- **文档**: [项目Wiki](https://github.com/ipzh/ipv6-wireguard-manager/wiki)
- **问题报告**: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **讨论**: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

### 社区支持
- **Telegram群组**: [加入群组](https://t.me/ipv6_wireguard_manager)
- **QQ群**: 123456789
- **微信群**: 扫描二维码加入

---

**IPv6 WireGuard Manager** - 让IPv6 VPN管理变得简单高效！
