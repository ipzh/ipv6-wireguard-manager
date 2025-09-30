# IPv6 WireGuard Manager

一个功能强大的IPv6 WireGuard管理工具，支持BGP路由、Web界面和自动化管理。

## ✨ 核心特性

- 🚀 **一键安装**: 支持多种安装方式，快速部署
- 🌐 **IPv6支持**: 完整的IPv6网络配置和管理
- 🔧 **BGP集成**: 支持BIRD BGP路由配置
- 🖥️ **Web界面**: 现代化的Web管理界面
- 👥 **客户端管理**: 自动生成和管理客户端配置
- 🔒 **安全加固**: 内置安全审计和监控
- 📊 **性能监控**: 实时系统资源监控
- 🔄 **自动更新**: 支持自动检查和更新
- 🧪 **自动化测试**: 完整的测试套件和CI/CD流水线
- 🐳 **Docker支持**: 容器化部署和管理
- 📈 **性能优化**: 缓存机制和并行处理

## 🏗️ 架构特性

- **模块化设计**: 50+ 个独立功能模块
- **跨平台支持**: Linux, Windows (WSL), macOS
- **智能缓存**: 配置缓存和性能优化
- **错误处理**: 完善的错误处理和恢复机制
- **监控系统**: 实时监控和告警
- **安全增强**: 多层安全防护和审计

## 🚀 快速开始

### 安装方式

#### 方式1: 一键安装 (推荐)
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

#### 方式2: 下载安装
```bash
wget -O install.sh https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

#### 方式3: 克隆安装
```bash
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
sudo ./install.sh
```

#### 方式4: Docker安装
```bash
# 使用Docker Compose
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
docker-compose up -d

# 或使用Docker镜像
docker run -d --name ipv6-wireguard-manager \
  --privileged --network host \
  -v /etc/ipv6-wireguard-manager:/etc/ipv6-wireguard-manager \
  -v /var/log/ipv6-wireguard-manager:/var/log/ipv6-wireguard-manager \
  ipv6-wireguard-manager:latest
```

### 系统要求

- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+
- **架构**: x86_64, ARM64
- **内存**: 最小 512MB, 推荐 1GB+
- **磁盘**: 最小 1GB 可用空间
- **网络**: 支持IPv6的网络环境

### 依赖软件

- WireGuard
- BIRD (BGP路由)
- Nginx (Web服务器)
- SQLite3 (数据库)
- Python 3.6+ (Web后端)

## 📖 使用指南

### 基本命令

```bash
# 启动管理界面
sudo ./ipv6-wireguard-manager.sh

# 查看状态
sudo ./ipv6-wireguard-manager.sh --status

# 重启服务
sudo ./ipv6-wireguard-manager.sh --restart

# 查看日志
sudo ./ipv6-wireguard-manager.sh --logs
```

### Web界面

安装完成后，访问 `http://your-server-ip:8080` 使用Web界面管理。

默认登录信息：
- 用户名: `admin`
- 密码: `admin123` (首次登录后请修改)

### 客户端管理

```bash
# 添加客户端
sudo ./ipv6-wireguard-manager.sh --add-client client1

# 生成客户端配置
sudo ./ipv6-wireguard-manager.sh --gen-config client1

# 列出所有客户端
sudo ./ipv6-wireguard-manager.sh --list-clients

# 删除客户端
sudo ./ipv6-wireguard-manager.sh --del-client client1
```

## 🔧 配置说明

### 主要配置文件

- `/etc/ipv6-wireguard-manager/manager.conf` - 主配置文件
- `/etc/wireguard/wg0.conf` - WireGuard配置
- `/etc/bird/bird.conf` - BGP路由配置
- `/etc/nginx/sites-available/ipv6-wireguard-manager` - Web服务器配置

### 配置示例

```bash
# 主配置
WIREGUARD_PORT=51820
WEB_PORT=8080
BGP_ENABLED=true
AUTO_UPDATE=true

# IPv6配置
IPV6_PREFIX=2001:db8::/64
IPV6_GATEWAY=2001:db8::1

# BGP配置
BGP_AS=65001
BGP_ROUTER_ID=192.168.1.1
```

## 🛠️ 开发指南

### 项目结构

```
ipv6-wireguard-manager/
├── modules/                 # 核心模块
│   ├── common_functions.sh  # 公共函数
│   ├── wireguard_config.sh  # WireGuard配置
│   ├── bird_config.sh       # BGP配置
│   └── web_management.sh    # Web管理
├── config/                  # 配置文件
├── examples/                # 配置示例
├── docs/                    # 文档
└── scripts/                 # 工具脚本
```

### 模块开发

```bash
# 创建新模块
cp modules/template.sh modules/my_module.sh

# 模块依赖
# 在 enhanced_module_loader.sh 中添加依赖关系

# 测试模块
bash modules/my_module.sh
```

## 🔍 故障排除

### 常见问题

1. **安装失败**
   ```bash
   # 检查系统要求
   ./install.sh --check-requirements
   
   # 查看详细日志
   tail -f /var/log/ipv6-wireguard-manager/install.log
   ```

2. **WireGuard连接失败**
   ```bash
   # 检查配置
   wg show
   
   # 重启服务
   systemctl restart wg-quick@wg0
   ```

3. **BGP路由问题**
   ```bash
   # 检查BIRD状态
   birdc show protocols
   
   # 查看路由表
   birdc show route
   ```

### 日志位置

- 主日志: `/var/log/ipv6-wireguard-manager/manager.log`
- 错误日志: `/var/log/ipv6-wireguard-manager/error.log`
- 安装日志: `/var/log/ipv6-wireguard-manager/install.log`

## 📊 性能监控

### 系统监控

```bash
# 查看系统状态
sudo ./ipv6-wireguard-manager.sh --monitor

# 资源使用情况
sudo ./ipv6-wireguard-manager.sh --resources

# 性能统计
sudo ./ipv6-wireguard-manager.sh --stats
```

### Web监控

访问Web界面的"监控"页面查看：
- 系统资源使用
- 网络流量统计
- 客户端连接状态
- 服务运行状态

## 🔄 更新升级

### 自动更新

```bash
# 启用自动更新
sudo ./ipv6-wireguard-manager.sh --enable-auto-update

# 手动检查更新
sudo ./ipv6-wireguard-manager.sh --check-update

# 执行更新
sudo ./ipv6-wireguard-manager.sh --update
```

### 版本管理

```bash
# 查看当前版本
sudo ./ipv6-wireguard-manager.sh --version

# 查看更新历史
sudo ./ipv6-wireguard-manager.sh --changelog
```

## 🗑️ 卸载

```bash
# 完全卸载
sudo ./uninstall.sh

# 保留配置文件
sudo ./uninstall.sh --keep-config
```

## 🧪 测试和开发

### 运行测试
```bash
# 运行所有测试
make test

# 运行特定测试
make test-unit          # 单元测试
make test-integration   # 集成测试
make test-performance   # 性能测试
make test-compatibility # 兼容性测试

# 生成覆盖率报告
make test-coverage

# 在Docker中运行测试
make docker-test
```

### 开发环境
```bash
# 设置开发环境
make dev-setup

# 代码质量检查
make lint

# 构建项目
make build

# 运行CI检查
make ci
```

### Docker开发
```bash
# 构建Docker镜像
make docker-build

# 运行容器
make docker-run

# 停止容器
make docker-stop
```

### 健康检查
```bash
# 系统健康检查
sudo ./ipv6-wireguard-manager.sh --health-check

# 查看版本信息
sudo ./ipv6-wireguard-manager.sh --version

# 查看帮助信息
sudo ./ipv6-wireguard-manager.sh --help
```

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 运行测试确保代码质量 (`make test`)
4. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
5. 推送到分支 (`git push origin feature/AmazingFeature`)
6. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [WireGuard](https://www.wireguard.com/) - 现代VPN协议
- [BIRD](https://bird.network.cz/) - BGP路由守护进程
- [Nginx](https://nginx.org/) - Web服务器

## 📞 支持

- 📧 邮箱: support@example.com
- 🐛 问题报告: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- 💬 讨论: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

---

**注意**: 请在生产环境中使用前仔细测试所有功能，并确保遵循最佳安全实践。