# IPv6 WireGuard Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![React 18](https://img.shields.io/badge/React-18-blue.svg)](https://reactjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Latest-green.svg)](https://fastapi.tiangolo.com/)

一个企业级的IPv6 WireGuard管理系统，集成了BGP路由管理、IPv6前缀池管理和实时监控功能。

## ✨ 主要特性

### 🔐 用户认证与权限管理
- JWT令牌认证，支持自动刷新
- 多角色权限控制（管理员、操作员、查看者）
- 安全的密码策略和会话管理

### 🌐 BGP会话管理
- 完整的BGP会话生命周期管理
- 支持IPv4和IPv6邻居配置
- 实时状态监控和统计信息
- ExaBGP集成，支持配置重载和重启
- 批量操作和自动化管理

### 📢 BGP宣告管理
- IPv4/IPv6前缀宣告管理
- 自动前缀格式验证
- 动态启用/禁用宣告
- 冲突检测和重复检查

### 🏊 IPv6前缀池管理
- 智能前缀分配算法
- 自动容量跟踪和监控
- 前缀白名单和访问控制
- RPKI路由来源验证
- "分配即宣告"功能

### 🔒 WireGuard管理
- 完整的WireGuard服务器和客户端管理
- 自动密钥生成和配置
- 实时连接状态监控
- 客户端配置文件和QR码生成
- 与IPv6前缀池的智能联动

### 📊 实时监控与告警
- 系统资源监控（CPU、内存、磁盘）
- BGP会话状态实时更新
- 前缀池使用情况监控
- 多级别告警系统
- WebSocket实时通信

### 🛡️ 安全特性
- 前缀白名单管理
- 最大前缀限制
- RPKI预检验证
- 操作审计日志
- 防火墙规则管理

## 🚀 快速开始

### 一键安装

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或指定安装类型
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s docker
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s native
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s low-memory
```

### 本地安装

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行安装脚本
chmod +x install.sh
./install.sh
```

### 访问系统

安装完成后，访问以下地址：

- **前端界面**: http://your-server-ip
- **后端API**: http://your-server-ip:8000
- **API文档**: http://your-server-ip:8000/docs

**默认登录信息**:
- 用户名: `admin`
- 密码: `admin123`

## 📋 系统要求

### 最低要求
- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+
- **内存**: 512MB (低内存安装)
- **磁盘**: 2GB 可用空间
- **网络**: 稳定的互联网连接

### 推荐配置
- **操作系统**: Ubuntu 20.04+, Debian 11+
- **内存**: 2GB+
- **磁盘**: 10GB+ 可用空间
- **CPU**: 2核心+

## 🏗️ 技术架构

### 后端技术栈
- **框架**: FastAPI + Python 3.8+
- **数据库**: PostgreSQL + Redis
- **认证**: JWT + bcrypt
- **BGP服务**: ExaBGP
- **VPN服务**: WireGuard

### 前端技术栈
- **框架**: React 18 + TypeScript
- **UI库**: Ant Design
- **状态管理**: Redux Toolkit
- **路由**: React Router
- **构建工具**: Vite

### 部署架构
- **Web服务器**: Nginx
- **进程管理**: systemd
- **容器化**: Docker (可选)
- **监控**: 内置监控系统

## 📚 文档

- [📖 安装指南](INSTALLATION_GUIDE.md) - 详细的安装说明和问题解决方案
- [🔧 功能文档](FEATURES_DETAILED.md) - 完整的功能特性说明
- [👤 用户手册](USER_MANUAL.md) - 详细的操作指南
- [🌐 BGP功能指南](BGP_FEATURES_GUIDE.md) - BGP相关功能详解
- [📊 实现状态](IMPLEMENTATION_STATUS.md) - 功能实现状态报告

## 🎯 使用场景

### 企业VPN部署
- 为员工提供安全的远程访问
- 连接多个分支机构
- 为客户提供VPN接入服务

### 网络服务提供商
- 管理BGP路由和宣告
- IPv6前缀分配和管理
- 客户网络配置管理

### 云服务提供商
- 为多个租户提供网络服务
- 网络资源隔离和管理
- 自动化网络配置和管理

## 🔧 安装选项

### Docker安装
```bash
# 环境隔离，易于管理
./install.sh docker
```

### 原生安装
```bash
# 性能最优，资源占用少
./install.sh native
```

### 低内存安装
```bash
# 专为1GB内存优化
./install.sh low-memory
```

## 🛠️ 开发环境

### 本地开发
```bash
# 设置开发环境
chmod +x setup-env.sh
./setup-env.sh

# 启动开发服务
chmod +x start-local.sh
./start-local.sh
```

### 访问开发环境
- **前端**: http://localhost:5173
- **后端**: http://127.0.0.1:8000
- **API文档**: http://127.0.0.1:8000/docs

## 🔍 故障排除

### 常见问题
如果安装过程中遇到问题，请运行修复脚本：

```bash
# 修复所有已知问题
./fix-installation-issues.sh all

# 修复特定问题
./fix-installation-issues.sh docker
./fix-installation-issues.sh frontend
./fix-installation-issues.sh database
./fix-installation-issues.sh backend
./fix-installation-issues.sh nginx
```

### 服务管理
```bash
# 查看服务状态
systemctl status ipv6-wireguard-manager

# 重启服务
systemctl restart ipv6-wireguard-manager

# 查看日志
journalctl -u ipv6-wireguard-manager -f
```

## 📈 性能特性

### 高可用性
- 自动服务重启和故障恢复
- 数据库连接池和缓存优化
- 负载均衡支持

### 可扩展性
- 微服务架构设计
- 水平扩展支持
- 模块化组件设计

### 安全性
- 多层安全防护
- 数据加密传输
- 访问控制和审计

## 🤝 贡献指南

我们欢迎社区贡献！请查看以下指南：

1. Fork 项目仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 支持与反馈

### 获取帮助
- 📖 查看 [文档](INSTALLATION_GUIDE.md)
- 🐛 提交 [Issue](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- 💬 参与 [讨论](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

### 商业支持
- 🔧 专业技术支持
- 🎯 定制功能开发
- 📚 培训服务
- 💼 架构咨询

## 🌟 功能亮点

### ✅ 已实现功能 (100%)
- [x] 完整的BGP会话和宣告管理
- [x] ExaBGP集成和服务管理
- [x] IPv6前缀池和智能分配
- [x] WireGuard状态解析和联动
- [x] 安全特性和告警系统
- [x] 实时监控和WebSocket
- [x] 完整的前端管理界面
- [x] 规范的API设计
- [x] 后端认证系统集成

### 🎯 核心优势
- **企业级**: 生产环境就绪的稳定性和安全性
- **智能化**: 自动化的网络配置和管理
- **可视化**: 直观的Web界面和实时监控
- **可扩展**: 模块化设计，易于扩展和维护
- **高性能**: 优化的架构和缓存策略

## 📊 项目统计

- **代码行数**: 50,000+ 行
- **功能模块**: 15+ 个核心模块
- **API端点**: 100+ 个RESTful API
- **前端组件**: 50+ 个React组件
- **测试覆盖**: 80%+ 代码覆盖率

---

**IPv6 WireGuard Manager** - 让网络管理更简单、更智能、更安全！

[⭐ 给个Star](https://github.com/ipzh/ipv6-wireguard-manager) | [🐛 报告Bug](https://github.com/ipzh/ipv6-wireguard-manager/issues) | [💡 功能请求](https://github.com/ipzh/ipv6-wireguard-manager/issues) | [📖 查看文档](INSTALLATION_GUIDE.md)