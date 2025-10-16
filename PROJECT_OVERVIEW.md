# IPv6 WireGuard Manager - 项目概览

## 🎯 项目简介

IPv6 WireGuard Manager 是一个现代化的企业级VPN管理系统，专为IPv4/IPv6双栈网络环境设计。系统采用前后端分离架构，提供完整的WireGuard、BGP、IPv6前缀管理功能。

## 🏗️ 系统架构

### 技术栈
- **后端**: Python 3.11+ + FastAPI + SQLAlchemy + MySQL
- **前端**: PHP 8.1+ + Bootstrap 5 + jQuery
- **数据库**: MySQL 8.0+
- **Web服务器**: Nginx 1.24+
- **缓存**: Redis 7+ (可选)
- **容器化**: Docker + Docker Compose (可选)

### 架构特点
- **微服务架构**: 模块化设计，易于扩展和维护
- **异步处理**: 支持高并发请求处理
- **双栈支持**: 完整的IPv4/IPv6双栈网络支持
- **安全加固**: 内置安全机制和访问控制
- **监控告警**: 实时系统监控和智能告警
- **自动备份**: 定时数据备份和恢复机制

## 🚀 核心功能

### 1. WireGuard管理
- **服务器管理**: 创建、配置、启动/停止WireGuard服务器
- **客户端管理**: 客户端配置生成、QR码生成、连接管理
- **配置管理**: 配置文件编辑、备份、恢复
- **状态监控**: 实时连接状态、流量统计、性能监控

### 2. BGP管理
- **会话管理**: BGP会话配置、启动/停止、状态监控
- **宣告管理**: 路由宣告配置、前缀管理、策略控制
- **邻居管理**: BGP邻居配置、连接状态监控
- **路由监控**: 路由表查看、路由变化告警

### 3. IPv6前缀管理
- **前缀池管理**: IPv6前缀池创建、配置、分配
- **前缀分配**: 自动前缀分配、手动分配、回收管理
- **统计报告**: 前缀使用统计、分配历史、利用率分析
- **路由配置**: 自动路由配置、前缀宣告

### 4. 系统监控
- **实时监控**: CPU、内存、磁盘、网络使用率
- **性能指标**: 系统性能指标收集和分析
- **告警管理**: 智能告警规则、告警通知、告警历史
- **日志分析**: 系统日志收集、分析、搜索

### 5. 用户管理
- **用户认证**: 用户登录、权限验证、会话管理
- **角色管理**: 角色定义、权限分配、访问控制
- **活动日志**: 用户操作日志、登录历史、安全审计
- **批量操作**: 批量用户管理、权限批量分配

### 6. 网络管理
- **接口管理**: 网络接口配置、状态监控
- **路由管理**: 路由表管理、路由配置、路由监控
- **防火墙**: 防火墙规则配置、状态监控
- **网络诊断**: 网络连通性测试、性能测试

## 📁 项目结构

```
ipv6-wireguard-manager/
├── backend/                    # Python后端
│   ├── app/
│   │   ├── api/               # API路由
│   │   ├── core/              # 核心配置
│   │   ├── models/            # 数据模型
│   │   ├── schemas/           # 数据模式
│   │   ├── services/          # 业务逻辑
│   │   └── utils/             # 工具函数
│   ├── scripts/               # 脚本文件
│   └── tests/                 # 测试文件
├── php-frontend/              # PHP前端
│   ├── classes/               # 核心类
│   ├── config/                # 配置文件
│   ├── controllers/           # 控制器
│   ├── views/                 # 视图文件
│   └── index.php              # 入口文件
├── docker/                    # Docker配置
├── monitoring/                # 监控配置
├── install.sh                 # 安装脚本
├── install_full.sh            # 完整安装脚本
└── docker-compose.yml         # Docker编排
```

## 🔧 安装部署

### 快速安装
```bash
# 完整功能安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install_full.sh | bash -s -- --enable-all

# 生产环境安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install_full.sh | bash -s -- --production --enable-security
```

### 安装选项
- **安装类型**: native, docker, minimal, full
- **可选功能**: 监控、日志、备份、安全、优化
- **环境模式**: 开发、测试、生产
- **系统支持**: Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux, openSUSE

## 🌐 访问地址

- **Web界面**: http://your-server-ip/
- **API文档**: http://your-server-ip:8000/docs
- **健康检查**: http://your-server-ip:8000/health
- **IPv6访问**: http://[your-ipv6-address]/

## 👤 默认账户

- **用户名**: admin
- **密码**: admin123

> ⚠️ 首次登录后请立即修改默认密码！

## 📊 系统要求

### 最低要求
- **内存**: 512MB
- **磁盘**: 2GB
- **CPU**: 1核心
- **系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+

### 推荐配置
- **内存**: 2GB+
- **磁盘**: 10GB+
- **CPU**: 2核心+
- **系统**: Ubuntu 20.04+, Debian 11+, CentOS 8+

## 🔒 安全特性

- **访问控制**: 基于角色的权限管理
- **数据加密**: 敏感数据加密存储
- **安全头**: 完整的安全HTTP头配置
- **防火墙**: 内置防火墙规则配置
- **SSL/TLS**: 支持HTTPS加密传输
- **审计日志**: 完整的操作审计日志

## 📈 性能优化

- **连接池**: 数据库连接池优化
- **缓存机制**: Redis缓存支持
- **异步处理**: 异步请求处理
- **负载均衡**: 多进程负载均衡
- **资源限制**: 智能资源使用限制
- **监控告警**: 性能监控和告警

## 🛠️ 管理命令

```bash
# 服务管理
ipv6-wireguard-manager start      # 启动服务
ipv6-wireguard-manager stop       # 停止服务
ipv6-wireguard-manager restart    # 重启服务
ipv6-wireguard-manager status     # 查看状态

# 系统管理
ipv6-wireguard-manager logs       # 查看日志
ipv6-wireguard-manager update     # 更新系统
ipv6-wireguard-manager backup     # 创建备份
ipv6-wireguard-manager monitor    # 系统监控
```

## 📚 文档资源

- **安装指南**: [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)
- **快速安装**: [QUICK_INSTALL_GUIDE.md](QUICK_INSTALL_GUIDE.md)
- **API文档**: [API_REFERENCE.md](API_REFERENCE.md)
- **部署配置**: [DEPLOYMENT_CONFIG.md](DEPLOYMENT_CONFIG.md)
- **功能总结**: [INSTALLATION_FEATURES_SUMMARY.md](INSTALLATION_FEATURES_SUMMARY.md)

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 技术支持

- **项目地址**: https://github.com/ipzh/ipv6-wireguard-manager
- **问题反馈**: https://github.com/ipzh/ipv6-wireguard-manager/issues
- **文档**: https://github.com/ipzh/ipv6-wireguard-manager/wiki

## 🎉 更新日志

### v3.0.0 (最新)
- ✅ 完整的PHP前端重构
- ✅ 企业级功能实现
- ✅ IPv4/IPv6双栈支持
- ✅ 智能安装脚本
- ✅ 安全加固和性能优化
- ✅ 完整的监控和日志系统
- ✅ 自动备份和恢复机制

---

**IPv6 WireGuard Manager** - 现代化的企业级VPN管理解决方案 🚀
