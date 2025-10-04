# IPv6 WireGuard Manager

一个功能强大的IPv6 WireGuard管理工具，支持BGP路由、Web界面、OAuth认证、监控告警和自动化管理。

## ✨ 核心特性

### 🚀 基础功能
- **一键安装**: 支持多种安装方式，快速部署
- **IPv6支持**: 完整的IPv6网络配置和管理
- **BGP集成**: 支持BIRD BGP路由配置
- **客户端管理**: 自动生成和管理客户端配置
- **防火墙管理**: 集成UFW、Firewalld、nftables、iptables

### 🖥️ Web管理界面
- **现代化界面**: 响应式Web管理界面
- **REST API**: 完整的RESTful API支持
- **WebSocket**: 实时状态推送和日志流
- **API文档**: 自动生成HTML格式API文档
- **健康检查**: 系统健康状态监控

### 🔐 认证与安全
- **OAuth 2.0**: 完整的OAuth 2.0授权码流程
- **多因素认证**: TOTP和备份代码支持
- **RBAC权限**: 基于角色的访问控制
- **安全审计**: 完整的审计日志和事件管理
- **安全扫描**: 自动安全漏洞检测
- **SSL/TLS**: 完整的SSL/TLS配置支持

### 📊 监控与告警
- **系统监控**: 内存、CPU、磁盘、网络使用率
- **温度监控**: 系统温度实时监控
- **多渠道告警**: 邮件、Webhook、Slack告警
- **告警冷却**: 防止告警风暴的冷却机制
- **历史统计**: 告警统计和历史记录
- **后台监控**: 持续后台监控服务

### 🔧 高级功能
- **智能缓存**: 自适应、激进、保守缓存策略
- **性能优化**: 并行处理、资源优化
- **配置热重载**: 无需重启的配置更新
- **依赖管理**: 循环依赖检测和冲突解决
- **模块化架构**: 30+个独立功能模块
- **错误处理**: 完善的错误处理和恢复机制

### 🧪 测试与质量
- **自动化测试**: 单元测试、集成测试、性能测试
- **Windows兼容**: WSL、MSYS2、PowerShell、Git Bash支持
- **代码质量**: ShellCheck检查、语法验证
- **CI/CD**: GitHub Actions自动化流水线
- **覆盖率报告**: 测试覆盖率统计

### 🐳 部署支持
- **Docker支持**: 容器化部署和管理
- **跨平台**: Linux、Windows (WSL)、macOS
- **自动更新**: 支持自动检查和更新
- **备份恢复**: 配置备份和恢复功能

## 🗺️ 功能地图（快速总览）

- **WireGuard 管理**: `modules/wireguard_config.sh`（服务器与客户端配置）
- **客户端管理**: `modules/client_management.sh`（添加/删除/生成配置）
- **BGP 路由**: `modules/bird_config.sh`（BIRD 配置与邻居管理）
- **防火墙管理**: `modules/firewall_management.sh`（iptables/nftables/ufw 规则）
- **Web 管理界面**: `modules/web_management.sh` 与 `modules/web_interface_enhanced.sh`
- **认证与权限**: `modules/oauth_authentication.sh` 与 `modules/security_functions.sh`
- **系统监控与告警**: `modules/system_monitoring.sh`、`modules/monitoring_alerting.sh`
- **错误处理与恢复**: `modules/unified_error_handling.sh`、`modules/advanced_error_handling.sh`
- **性能与缓存优化**: `modules/performance_optimizer.sh`、`modules/smart_caching.sh`、`modules/lazy_loading.sh`
- **备份与更新**: `modules/backup_restore.sh`、`modules/update_management.sh`

> 完整功能明细请参考 `FEATURES_OVERVIEW.md`。

## 📚 文档导航

- `docs/COMBINED_GUIDE.md` — 综合指南（快速开始 + 功能总览）
- `FEATURES_OVERVIEW.md` — 功能特性总览（模块级详细说明）
- `QUICK_START_GUIDE.md` — 快速开始与常用操作
- `docs/INSTALLATION.md` — 安装与环境依赖
- `docs/USAGE.md` — 使用与配置指南
- `docs/API.md` — API 文档与示例
- `docs/TESTING.md` — 测试指南与测试套件说明

## 🏗️ 架构特性

### 模块化设计
- **30+功能模块**: 独立的功能模块，清晰的依赖关系
- **智能加载**: 按需加载和依赖解析
- **循环依赖检测**: 自动检测和预防循环依赖
- **版本管理**: 模块版本兼容性检查

### 安全架构
- **多层防护**: 输入验证、权限控制、审计日志
- **认证体系**: OAuth 2.0 + MFA + RBAC
- **安全扫描**: 自动漏洞检测和安全评估
- **加密存储**: 敏感信息加密存储

### 监控架构
- **多维度监控**: 系统资源、网络、温度
- **实时告警**: 多渠道告警通知
- **历史分析**: 监控数据历史分析
- **性能优化**: 智能缓存和资源优化

### 测试架构
- **统一框架**: 单元测试、集成测试、性能测试
- **兼容性测试**: Windows环境兼容性测试
- **自动化测试**: 持续集成和自动化测试
- **质量保证**: 代码质量检查和验证

## 🪟 Windows 环境注意事项

- 建议在 **WSL (Ubuntu/Debian)** 中运行，以获得与 Linux 环境一致的兼容性。
- 如果在原生 PowerShell 中操作：
  - 确保 `git.exe` 已加入系统 `PATH`（常见路径如 `D:\Program Files\Git\cmd\git.exe`）。
  - 使用 `Git Bash` 或 `WSL` 执行 Shell 脚本，以避免路径与权限差异导致的问题。
  - 如遇 "git 不是可识别的命令"，请将 Git 安装目录添加到系统环境变量 `PATH`，然后重新打开终端。

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

#### 功能特性
- **仪表板**: 系统状态总览和关键指标
- **客户端管理**: 添加、删除、配置客户端
- **网络配置**: IPv6和BGP路由配置
- **监控面板**: 实时系统资源监控
- **安全中心**: OAuth认证、RBAC权限管理
- **日志查看**: 实时日志流和历史日志
- **系统设置**: 配置管理和系统维护

#### 认证方式
- **OAuth 2.0**: 支持第三方OAuth提供商
- **多因素认证**: TOTP和备份代码
- **RBAC权限**: 基于角色的访问控制
- **会话管理**: 安全的会话超时和刷新

#### API接口
- **REST API**: 完整的RESTful API
- **WebSocket**: 实时数据推送
- **API文档**: 自动生成的API文档
- **健康检查**: 系统健康状态API

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
- `/etc/ipv6-wireguard-manager/oauth_clients.db` - OAuth客户端数据库
- `/etc/ipv6-wireguard-manager/mfa_secrets.db` - MFA密钥数据库
- `/etc/ipv6-wireguard-manager/rbac_roles.db` - RBAC角色数据库
- `/etc/ipv6-wireguard-manager/audit_logs.db` - 审计日志数据库
- `/etc/ipv6-wireguard-manager/alert_config.conf` - 告警配置
- `/etc/ipv6-wireguard-manager/cache_config.json` - 缓存配置

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

# OAuth认证配置
OAUTH_ENABLED=true
OAUTH_CLIENT_ID=web-manager
OAUTH_CLIENT_SECRET=your-secret-key
OAUTH_REDIRECT_URI=http://localhost:8080/callback

# MFA配置
MFA_ENABLED=true
MFA_ISSUER=IPv6-WireGuard-Manager
MFA_ALGORITHM=SHA1
MFA_DIGITS=6
MFA_PERIOD=30

# RBAC配置
RBAC_ENABLED=true
DEFAULT_ROLE=user
ADMIN_ROLE=admin

# 监控告警配置
ALERT_ENABLED=true
EMAIL_ALERTS=true
WEBHOOK_ALERTS=false
SLACK_ALERTS=false
MEMORY_THRESHOLD=80
CPU_THRESHOLD=90
DISK_THRESHOLD=90
TEMP_THRESHOLD=80

# 缓存配置
CACHE_ENABLED=true
CACHE_STRATEGY=adaptive
CACHE_TTL=300
CACHE_MAX_SIZE=1000

# 性能优化配置
PARALLEL_PROCESSING=true
SMART_SLEEP_ENABLED=true
SLEEP_SHORT=0.1
SLEEP_MEDIUM=1
SLEEP_LONG=2
```

## 🛠️ 开发指南

### 项目结构

```
ipv6-wireguard-manager/
├── modules/                          # 核心模块 (30+ 个模块)
│   ├── common_functions.sh           # 公共函数库
│   ├── wireguard_config.sh           # WireGuard配置管理
│   ├── bird_config.sh                # BGP路由配置
│   ├── web_management.sh             # Web管理界面
│   ├── oauth_authentication.sh       # OAuth 2.0认证
│   ├── security_functions.sh         # 安全功能
│   ├── security_audit_monitoring.sh  # 安全审计监控
│   ├── resource_monitoring.sh        # 资源监控告警
│   ├── smart_caching.sh              # 智能缓存系统
│   ├── enhanced_module_loader.sh     # 增强模块加载器
│   ├── unified_error_handling.sh     # 统一错误处理
│   ├── advanced_performance_optimization.sh # 高级性能优化
│   ├── config_hot_reload.sh          # 配置热重载
│   ├── user_interface.sh             # 用户界面
│   ├── update_management.sh          # 更新管理
│   ├── backup_restore.sh             # 备份恢复
│   ├── firewall_management.sh        # 防火墙管理
│   ├── client_management.sh          # 客户端管理
│   └── ...                           # 其他功能模块
├── tests/                            # 测试套件
│   ├── comprehensive_test_suite.sh   # 综合测试套件
│   ├── windows_compatibility_test.sh # Windows兼容性测试
│   ├── automated-testing.sh          # 自动化测试
│   └── test_cases.sh                 # 测试用例
├── config/                           # 配置文件
├── examples/                         # 配置示例
├── docs/                             # 文档
├── scripts/                          # 工具脚本
├── CHANGELOG.md                      # 更新日志
└── README.md                         # 项目说明
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
make test-windows       # Windows兼容性测试

# 运行综合测试套件
./tests/comprehensive_test_suite.sh

# 运行Windows兼容性测试
./tests/windows_compatibility_test.sh

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

# OAuth认证管理
sudo ./ipv6-wireguard-manager.sh --oauth-setup

# 监控告警配置
sudo ./ipv6-wireguard-manager.sh --alert-config

# 依赖管理
sudo ./ipv6-wireguard-manager.sh --dependency-check

# 性能优化
sudo ./ipv6-wireguard-manager.sh --optimize

# 缓存管理
sudo ./ipv6-wireguard-manager.sh --cache-stats
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

## 📊 功能对比

| 功能特性 | 基础版本 | 增强版本 | 企业版本 |
|---------|---------|---------|---------|
| WireGuard管理 | ✅ | ✅ | ✅ |
| IPv6支持 | ✅ | ✅ | ✅ |
| BGP路由 | ✅ | ✅ | ✅ |
| Web界面 | ✅ | ✅ | ✅ |
| 客户端管理 | ✅ | ✅ | ✅ |
| OAuth 2.0认证 | ❌ | ✅ | ✅ |
| 多因素认证 | ❌ | ✅ | ✅ |
| RBAC权限 | ❌ | ✅ | ✅ |
| 监控告警 | 基础 | 增强 | 企业级 |
| 安全审计 | ❌ | ✅ | ✅ |
| 智能缓存 | ❌ | ✅ | ✅ |
| 性能优化 | 基础 | 增强 | 企业级 |
| 依赖管理 | ❌ | ✅ | ✅ |
| Windows兼容 | ❌ | ✅ | ✅ |
| 技术支持 | 社区 | 社区 | 商业 |

## 🎯 使用场景

### 个人用户
- 家庭网络VPN搭建
- 个人设备远程访问
- 学习IPv6和WireGuard技术

### 中小企业
- 分支机构网络连接
- 远程办公支持
- 网络安全防护

### 企业级应用
- 大规模VPN部署
- 高可用性要求
- 企业级安全认证
- 合规性要求

## 📈 性能指标

### 系统性能
- **并发连接**: 支持1000+并发客户端
- **吞吐量**: 1Gbps+网络吞吐量
- **延迟**: <10ms内网延迟
- **CPU使用**: <5%空闲时CPU使用率
- **内存占用**: <100MB基础内存占用

### 功能性能
- **启动时间**: <30秒完整启动
- **配置更新**: <5秒热重载配置
- **缓存命中率**: >90%智能缓存命中率
- **告警响应**: <10秒告警响应时间
- **API响应**: <100ms API平均响应时间

## 🔒 安全特性

### 认证安全
- OAuth 2.0 + OpenID Connect
- TOTP多因素认证
- 基于角色的访问控制
- 会话管理和超时控制
- 密码策略和强度检查

### 网络安全
- WireGuard现代加密协议
- IPv6安全配置
- 防火墙规则管理
- 网络隔离和访问控制
- DDoS防护和流量限制

### 系统安全
- 安全审计日志
- 漏洞扫描和检测
- 敏感信息加密存储
- 权限最小化原则
- 安全更新和补丁管理

## 📞 支持

- 📧 邮箱: support@example.com
- 🐛 问题报告: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- 💬 讨论: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)
- 📖 文档: [项目文档](https://github.com/ipzh/ipv6-wireguard-manager/wiki)
- 🎥 视频教程: [YouTube频道](https://youtube.com/example)

## 🏆 项目亮点

- **🚀 现代化**: 采用最新的技术和架构设计
- **🔒 安全性**: 企业级安全认证和防护
- **📊 可观测性**: 完整的监控、告警和日志系统
- **🧪 质量保证**: 全面的测试覆盖和CI/CD流水线
- **🌍 跨平台**: 支持Linux、Windows、macOS
- **📈 高性能**: 智能缓存和性能优化
- **🔧 易维护**: 模块化架构和依赖管理
- **📚 文档完善**: 详细的使用文档和开发指南

---

**注意**: 请在生产环境中使用前仔细测试所有功能，并确保遵循最佳安全实践。建议在测试环境中充分验证后再部署到生产环境。

## 📄 文档更新与清理

- 新增 `docs/FEATURES_VALIDATION_REPORT.md`，用于快速验证模块化、缓存与安全框架的实现状态与检查方法。
- 引入 `modules/module_metadata_checker.sh` 以在加载前提示补齐模块头（`# Module:`、`# Version:`、`# Depends:`）。
- 提供统一缓存 API：`modules/cache_api.sh`，在模块中使用 `cache_get`、`cache_set`、`cache_invalidate` 统一调用底层缓存实现。
- 清理冗余里程碑与重复报告文档以简化仓库结构（详见提交记录）。

### 运行校验与使用缓存 API

```bash
# 模块元数据校验（提示缺失但不阻断加载）
bash modules/module_metadata_checker.sh || true

# 统一缓存API示例
source modules/cache_api.sh
cache_set "wg_status" "running" 300
cache_get "wg_status"
cache_invalidate "wg_status"

# 执行并缓存命令（统一入口）
cache_exec "echo hello" "hello_key" 60 false

# 查看缓存统计并清理
cache_stats
cache_clear
```

### 测试与CI集成

- 单元测试入口：`bash tests/run_tests.sh`
- 新增测试用例：
  - `tests/cache_api_tests.sh`：验证 `cache_set/get/invalidate` 与 TTL 过期。
  - `tests/cache_stats_tests.sh`：基本校验 `cache_stats` 输出。
  - `tests/metadata_validation_tests.sh`：对模块目录与错误示例进行元数据校验。
- CI 已集成模块元数据校验（`modules/module_metadata_checker.sh`），构建时缺失 `# Module:`、`# Version:`、`# Depends:` 将失败。