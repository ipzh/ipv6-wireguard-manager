# IPv6 WireGuard Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Node.js 18+](https://img.shields.io/badge/node.js-18+-green.svg)](https://nodejs.org/)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)
[![CI/CD](https://github.com/ipzh/ipv6-wireguard-manager/workflows/CI%2FCD%20Pipeline/badge.svg)](https://github.com/ipzh/ipv6-wireguard-manager/actions)

现代化的企业级IPv6 WireGuard VPN管理系统，支持BGP路由、IPv6前缀池管理、实时监控和智能告警。

## 🌟 主要特性

### 🔐 用户认证与权限管理
- JWT令牌认证机制
- 基于角色的权限控制（RBAC）
- 用户管理界面
- 会话管理和安全策略

### 🌐 WireGuard管理
- 服务器配置管理
- 客户端管理
- 密钥生成和管理
- 配置文件导出
- 实时连接状态监控
- 流量统计和分析

### 🛣️ BGP路由管理
- BGP会话管理
- 路由宣告控制
- 前缀过滤
- 路由策略配置
- 自动化路由管理

### 📊 IPv6前缀池管理
- 前缀分配和回收
- 客户端关联
- 自动宣告配置
- 白名单和RPKI支持
- 智能分配算法

### 📈 实时监控与告警
- 系统指标实时监控
- WireGuard状态监控
- 网络流量分析
- 智能异常检测（机器学习）
- 自动化故障修复
- 多级告警系统

### 🔒 企业级安全
- 端到端数据加密
- API密钥管理
- 速率限制和IP封禁
- 可疑活动检测
- 完整审计日志
- CSRF保护

### 🎨 现代化界面
- React + TypeScript + Ant Design
- 响应式设计
- 实时数据可视化
- 高级仪表板
- 移动端适配

### 🚀 生产级部署
- Docker容器化部署
- Kubernetes支持
- CI/CD自动化流水线
- 监控和日志系统
- 备份和恢复

## 🚀 快速开始

### 一键安装（推荐）

```bash
# 一键安装（自动选择最佳安装方式）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 安装选项

- **Docker安装**（推荐新手）：环境隔离，易于管理
- **原生安装**（推荐VPS）：性能最优，资源占用少
- **低内存安装**（1GB内存）：专为小内存服务器优化

### 系统要求

- **操作系统**：Ubuntu 18.04+, Debian 10+, CentOS 7+
- **内存**：最低1GB，推荐2GB+
- **存储**：最低2GB可用空间
- **网络**：支持IPv4和IPv6

## 📚 详细文档

- [安装指南](INSTALLATION_GUIDE.md) - 详细的安装步骤和配置说明
- [快速开始](QUICK_START.md) - 5分钟快速部署和使用指南
- [用户手册](USER_MANUAL.md) - 完整的功能使用说明
- [功能详解](FEATURES_DETAILED.md) - 所有功能的详细说明
- [API参考](API_REFERENCE.md) - 完整的API接口文档
- [开发指南](DEVELOPMENT_GUIDE.md) - 开发环境搭建和代码规范
- [部署文档](DEPLOYMENT-README.md) - 性能优化与生产部署指南

## 🏗️ 系统架构

### 技术栈

**后端**
- FastAPI (Python 3.11+)
- PostgreSQL 15+
- Redis 7+
- SQLAlchemy (异步ORM)
- Pydantic (数据验证)

**前端**
- React 18
- TypeScript
- Ant Design
- Recharts (数据可视化)
- WebSocket (实时通信)

**部署**
- Docker & Docker Compose
- Nginx (反向代理)
- Systemd (服务管理)
- Prometheus + Grafana (监控)

### 架构图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端界面      │    │   后端API       │    │   数据库        │
│   React + TS    │◄──►│   FastAPI       │◄──►│   PostgreSQL    │
│   Ant Design    │    │   Python 3.11   │    │   Redis         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx代理     │    │   WireGuard     │    │   监控系统      │
│   静态文件      │    │   服务管理      │    │   Prometheus    │
│   SSL终端       │    │   BGP管理       │    │   Grafana       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 配置说明

### 环境变量

```bash
# 数据库配置
DATABASE_URL=postgresql://user:password@localhost:5432/ipv6wgm
REDIS_URL=redis://localhost:6379/0

# 安全配置
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 应用配置
DEBUG=false
LOG_LEVEL=INFO
SERVER_HOST=127.0.0.1
SERVER_PORT=8000

# WireGuard配置
WIREGUARD_CONFIG_DIR=/etc/wireguard
WIREGUARD_INTERFACE=wg0
```

### 配置文件

主要配置文件位置：
- 应用配置：`/opt/ipv6-wireguard-manager/.env`
- Nginx配置：`/etc/nginx/sites-available/ipv6-wireguard-manager`
- 服务配置：`/etc/systemd/system/ipv6-wireguard-manager.service`

## 📊 监控和告警

### 监控指标

- **系统指标**：CPU、内存、磁盘、网络使用率
- **WireGuard指标**：连接数、流量统计、连接状态
- **应用指标**：API响应时间、错误率、并发数
- **业务指标**：用户数、BGP会话数、前缀分配数

### 告警规则

- **系统告警**：资源使用率过高、服务异常
- **网络告警**：连接中断、流量异常
- **安全告警**：异常访问、攻击检测
- **业务告警**：配置错误、性能下降

### 智能分析

- **异常检测**：基于机器学习的异常模式识别
- **趋势分析**：历史数据分析和趋势预测
- **自动修复**：常见问题的自动化修复
- **智能建议**：基于分析结果的优化建议

## 🔒 安全特性

### 数据保护
- 敏感数据端到端加密
- 数据库连接加密
- 配置文件权限控制
- 备份数据加密

### 访问控制
- JWT令牌认证
- API密钥管理
- 基于角色的权限控制
- 速率限制和IP封禁

### 安全监控
- 实时安全事件监控
- 可疑活动检测
- 完整审计日志
- 安全告警通知

## 🚀 部署选项

### Docker部署

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 启动服务
docker-compose -f docker-compose.production.yml up -d
```

### Kubernetes部署

```bash
# 应用Kubernetes配置
kubectl apply -f k8s/
```

### 传统部署

```bash
# 使用安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

## 🔄 CI/CD流水线

项目包含完整的CI/CD流水线：

- **代码质量检查**：linting、格式化、类型检查
- **自动化测试**：单元测试、集成测试
- **安全扫描**：漏洞扫描、依赖检查
- **自动部署**：测试环境、生产环境
- **监控告警**：部署状态通知

## 📈 性能优化

### 数据库优化
- 连接池配置
- 查询优化
- 索引优化
- 缓存策略

### 应用优化
- 异步处理
- 内存管理
- 并发控制
- 资源限制

### 系统优化
- 内核参数调优
- 网络配置优化
- 文件系统优化
- 监控和调优

## 🤝 贡献指南

我们欢迎社区贡献！请查看 [开发指南](DEVELOPMENT_GUIDE.md) 了解如何参与开发。

### 贡献方式
- 报告Bug
- 提出新功能
- 提交代码
- 改进文档
- 分享使用经验

### 开发环境
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 安装依赖
pip install -r backend/requirements.txt
cd frontend && npm install

# 启动开发环境
docker-compose -f docker-compose.dev.yml up -d
```

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 支持

- **文档**：查看项目文档获取详细说明
- **Issues**：在GitHub上提交问题
- **讨论**：参与社区讨论
- **邮件**：发送邮件到 support@ipv6-wireguard-manager.com

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者和用户！

---

**IPv6 WireGuard Manager** - 让IPv6 VPN管理变得简单而强大！