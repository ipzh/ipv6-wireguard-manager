# IPv6 WireGuard Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![PHP 8.1+](https://img.shields.io/badge/php-8.1+-green.svg)](https://www.php.net/)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)
[![IPv6](https://img.shields.io/badge/IPv6-supported-orange.svg)](https://en.wikipedia.org/wiki/IPv6)
[![Linux](https://img.shields.io/badge/Linux-supported-lightgrey.svg)](https://www.linux.org/)

> 🚀 **企业级IPv6 WireGuard VPN管理系统** - 支持IPv6/IPv4双栈网络，集成BGP路由、智能前缀池管理和实时监控功能

## ✨ 核心特性

### 🌐 双栈网络支持
- ✅ **IPv6/IPv4双栈网络** - 同时支持IPv6和IPv4协议
- ✅ **自动协议检测** - 智能检测和适配网络环境
- ✅ **多主机部署** - 支持在任何主机上部署，无需修改配置
- ✅ **零配置部署** - 自动检测系统环境并选择最佳安装方式

### 🔐 企业级安全
- ✅ **JWT令牌认证** - 安全的用户认证机制
- ✅ **基于角色的权限控制** - 细粒度的权限管理
- ✅ **用户会话管理** - 完整的用户生命周期管理
- ✅ **安全配置** - 生产级安全配置和最佳实践

### 🛡️ WireGuard VPN管理
- ✅ **服务器和客户端配置** - 完整的WireGuard配置管理
- ✅ **密钥管理** - 安全的密钥生成、存储和管理
- ✅ **配置文件导出** - 支持多种格式的配置文件导出
- ✅ **实时连接监控** - 实时监控VPN连接状态和性能

### 🛣️ BGP路由管理
- ✅ **BGP会话配置** - 完整的BGP会话管理
- ✅ **路由宣告控制** - 智能的路由宣告和过滤
- ✅ **自动化路由管理** - 自动化的路由策略管理
- ✅ **ExaBGP集成** - 与ExaBGP的深度集成

### 📊 IPv6前缀池管理
- ✅ **智能前缀分配** - 自动化的IPv6前缀分配和回收
- ✅ **自动BGP宣告** - 自动化的BGP路由宣告
- ✅ **白名单支持** - 灵活的前缀白名单管理
- ✅ **RPKI支持** - RPKI验证和路由安全

### 📈 监控和告警
- ✅ **实时系统监控** - 全面的系统性能监控
- ✅ **智能异常检测** - 基于机器学习的异常检测
- ✅ **多级告警系统** - 灵活的告警策略和通知
- ✅ **性能分析** - 详细的性能分析和报告

### 🚀 生产就绪
- ✅ **Docker容器化** - 完整的Docker支持
- ✅ **自动化部署** - 一键安装和配置
- ✅ **高可用性** - 支持集群和负载均衡
- ✅ **监控集成** - 与Prometheus、Grafana集成

## 🚀 快速开始

### 一键安装（推荐）

```bash
# 智能安装（自动检测系统并选择最佳安装方式）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 静默安装（推荐生产环境）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent

# 指定安装类型
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type minimal --silent
```

### 安装选项

```bash
# 原生安装（推荐开发环境）
./install.sh --type native

# 最小化安装（低内存环境）
./install.sh --type minimal

# 生产环境安装
./install.sh --production --silent

# 自定义配置
./install.sh --dir /opt/ipv6-wireguard-manager --port 8080 --api-port 9000

# 跳过某些步骤
./install.sh --skip-deps --skip-db
```

## 📁 安装目录结构

安装完成后，系统将使用以下目录结构：

```
/opt/ipv6-wireguard-manager/          # 后端安装目录
├── backend/                          # 后端Python代码
├── php-frontend/                     # 前端源码（备份）
├── venv/                             # Python虚拟环境
├── logs/                              # 后端日志
├── config/                            # 配置文件
├── data/                              # 数据文件
└── .env                               # 环境配置文件

/var/www/html/                        # 前端Web目录
├── classes/                          # PHP类文件
├── controllers/                       # 控制器
├── views/                            # 视图模板
├── config/                           # 配置文件
├── logs/                              # 前端日志（777权限）
├── assets/                           # 静态资源
├── index.php                         # 主入口文件
└── index_jwt.php                     # JWT版本入口
```

## 🔧 权限配置

| 目录/文件 | 所有者 | 权限 | 说明 |
|-----------|--------|------|------|
| `/opt/ipv6-wireguard-manager/` | `ipv6wgm:ipv6wgm` | `755` | 后端安装目录 |
| `/var/www/html/` | `www-data:www-data` | `755` | 前端Web目录 |
| `/var/www/html/logs/` | `www-data:www-data` | `777` | 前端日志目录 |
| `/opt/ipv6-wireguard-manager/.env` | `ipv6wgm:ipv6wgm` | `600` | 环境配置文件 |

## 📋 系统要求

### 最低要求
- **内存**: 1GB
- **磁盘**: 3GB
- **CPU**: 1核心
- **系统**: 支持多种Linux发行版

### 推荐配置
- **内存**: 2GB+
- **磁盘**: 5GB+

### 支持的系统
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **Debian**: 9, 10, 11, 12
- **CentOS**: 7, 8, 9
- **RHEL**: 7, 8, 9
- **Fedora**: 30+
- **Arch Linux**: 最新版本
- **openSUSE**: 15+
- **Gentoo**: 需要手动配置
- **Alpine Linux**: 基础支持

## 🌐 访问地址

安装完成后，访问以下地址：

- **Web界面**: http://your-server-ip/
- **API文档**: http://your-server-ip:8000/docs
- **API健康检查**: http://your-server-ip:8000/api/v1/health
- **IPv6访问**: http://[your-ipv6-address]/

## 👤 默认账户

- **用户名**: admin
- **密码**: admin123
- **邮箱**: admin@example.com

> ⚠️ 首次登录后请立即修改默认密码！

## 🎯 核心功能

### WireGuard管理
- ✅ 服务器和客户端管理
- ✅ 配置文件生成和编辑
- ✅ 连接状态监控
- ✅ 流量统计和分析

### BGP管理
- ✅ BGP会话配置和管理
- ✅ 路由宣告管理
- ✅ 邻居状态监控
- ✅ 路由表查看

### IPv6前缀管理
- ✅ IPv6前缀池管理
- ✅ 前缀分配和回收
- ✅ 使用统计和报告
- ✅ 自动路由配置

### 系统监控
- ✅ 实时系统监控
- ✅ 性能指标收集
- ✅ 告警管理
- ✅ 日志分析

### 用户管理
- ✅ 用户认证和授权
- ✅ 角色和权限管理
- ✅ 活动日志记录
- ✅ 批量操作支持

### 网络管理
- ✅ 网络接口管理
- ✅ 路由表管理
- ✅ 防火墙配置
- ✅ 网络诊断工具

## 🔧 管理命令

IPv6 WireGuard Manager 提供了完整的CLI管理工具，安装后可直接使用：

```bash
# 服务管理
ipv6-wireguard-manager start      # 启动服务
ipv6-wireguard-manager stop       # 停止服务
ipv6-wireguard-manager restart    # 重启服务
ipv6-wireguard-manager status     # 查看状态

# 系统管理
ipv6-wireguard-manager logs       # 查看日志
ipv6-wireguard-manager logs -f    # 实时查看日志
ipv6-wireguard-manager update     # 更新系统
ipv6-wireguard-manager backup     # 创建备份
ipv6-wireguard-manager monitor    # 系统监控

# 帮助信息
ipv6-wireguard-manager help       # 显示帮助
ipv6-wireguard-manager version    # 显示版本
```

### 命令示例

```bash
# 查看服务状态
ipv6-wireguard-manager status

# 实时查看日志
ipv6-wireguard-manager logs -f

# 创建命名备份
ipv6-wireguard-manager backup --name daily-backup

# 系统监控
ipv6-wireguard-manager monitor
```

## 🛠️ 技术栈

- **后端**: Python 3.11+ + FastAPI + SQLAlchemy + MySQL
- **前端**: PHP 8.1+ + Bootstrap 5 + jQuery
- **数据库**: MySQL 8.0+
- **Web服务器**: Nginx 1.24+
- **缓存**: Redis 7+ (可选)
- **容器化**: Docker + Docker Compose (可选)

## 🔒 安全特性

- ✅ 基于角色的访问控制
- ✅ 数据加密存储
- ✅ 安全HTTP头配置
- ✅ 防火墙规则管理
- ✅ SSL/TLS支持
- ✅ 操作审计日志

## 📈 性能优化

- ✅ 数据库连接池优化
- ✅ Redis缓存支持
- ✅ 异步请求处理
- ✅ 多进程负载均衡
- ✅ 智能资源限制
- ✅ 性能监控告警

## 🚀 安装脚本功能

### 智能安装
- 自动检测系统环境
- 智能推荐安装类型
- 支持多种安装模式
- 完整的错误处理

### 可选功能
- Docker支持
- Redis缓存
- 系统监控
- 高级日志
- 自动备份
- 安全加固
- 性能优化
- SSL/TLS支持
- 防火墙配置

### 环境模式
- 开发环境
- 测试环境
- 生产环境
- 最小化环境

## 📚 文档

- [安装指南](INSTALLATION_GUIDE.md) - 详细的安装说明
- [快速安装指南](QUICK_INSTALL_GUIDE.md) - 快速安装步骤
- [API参考文档](API_REFERENCE.md) - API接口文档
- [部署配置](DEPLOYMENT_CONFIG.md) - 部署配置说明
- [生产部署指南](PRODUCTION_DEPLOYMENT_GUIDE.md) - 生产环境部署
- [CLI管理指南](CLI_MANAGEMENT_GUIDE.md) - 命令行工具使用
- [API修复总结](API_INTEGRATION_SUMMARY.md) - API修复详情
- [安装脚本审计报告](INSTALL_SCRIPT_AUDIT_REPORT.md) - 脚本质量报告

## 🤝 贡献

欢迎贡献代码！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 支持

- **项目地址**: https://github.com/ipzh/ipv6-wireguard-manager
- **问题反馈**: https://github.com/ipzh/ipv6-wireguard-manager/issues
- **文档**: https://github.com/ipzh/ipv6-wireguard-manager/wiki

## 🎉 更新日志

### v3.0.0 (最新)
- ✅ 完整的API修复和优化
- ✅ 智能安装脚本
- ✅ 企业级功能实现
- ✅ IPv4/IPv6双栈支持
- ✅ 安全加固和性能优化
- ✅ 完整的监控和日志系统
- ✅ 自动备份和恢复机制
- ✅ 零错误安装体验

---

**IPv6 WireGuard Manager** - 现代化的企业级VPN管理解决方案 🚀