# IPv6 WireGuard Manager

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.8+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green.svg)](https://fastapi.tiangolo.com)
[![Docker](https://img.shields.io/badge/docker-supported-blue.svg)](https://docker.com)

一个现代化的企业级IPv6 WireGuard VPN管理系统，提供完整的VPN服务器和客户端管理功能。

## ✨ 主要特性

### 🔐 VPN管理
- **WireGuard服务器管理** - 创建、配置和管理WireGuard服务器
- **客户端管理** - 批量创建、配置和管理VPN客户端
- **IPv6支持** - 完整的IPv6网络支持和管理
- **BGP集成** - 支持BGP路由协议和网络配置
- **网络监控** - 实时网络状态监控和统计

### 🛡️ 安全特性
- **JWT认证** - 基于JWT的安全认证系统
- **RBAC权限控制** - 基于角色的访问控制
- **API安全** - 速率限制、CORS保护、安全头
- **审计日志** - 完整的操作审计和日志记录

### 📊 监控和运维
- **实时监控** - 系统性能、网络状态实时监控
- **异常监控** - 智能异常检测和告警系统
- **日志聚合** - 结构化日志记录和分析
- **健康检查** - 全面的系统健康状态检查

### 🔧 技术特性
- **现代化架构** - FastAPI + PHP 前后端分离
- **容器化部署** - Docker和Docker Compose支持
- **配置管理** - 统一配置管理和环境变量支持
- **API标准化** - RESTful API设计和版本控制
- **数据库优化** - 连接池、健康检查、性能优化
- **API路径构建器** - 统一的API路径管理，支持前后端一致性

## 🚀 快速开始

### 环境要求

- **Python**: 3.8+
- **PHP**: 8.1+
- **MySQL**: 8.0+
- **Docker**: 20.10+ (可选)
- **系统**: Linux/macOS/Windows

### 安装方式

#### 1. 自动安装脚本

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或使用自定义路径
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- \
  --install-dir /opt/ipv6-wireguard-manager \
  --frontend-dir /var/www/html \
  --config-dir /etc/wireguard \
  --log-dir /var/log/ipv6-wireguard-manager
```

#### 2. Docker部署

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 配置环境变量
cp env.template .env
# 编辑 .env 文件

# 启动服务
docker-compose up -d
```

#### 3. 手动安装

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 安装后端依赖
cd backend
pip install -r requirements.txt

# 安装前端依赖
cd ../php-frontend
composer install

# 配置数据库
mysql -u root -p < migrations/init.sql

# 启动服务
cd ../backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## 📖 详细文档

### 📚 核心文档
- [安装指南](INSTALLATION_GUIDE.md) - 详细的安装和配置说明
- [部署指南](docs/DEPLOYMENT_GUIDE.md) - 生产环境部署指南
- [API文档](docs/API_DOCUMENTATION.md) - 完整的API参考文档
- [用户手册](docs/USER_MANUAL.md) - 用户操作指南
- [开发者指南](docs/DEVELOPER_GUIDE.md) - 开发者文档
- [API路径构建器使用指南](docs/API_PATH_BUILDER_USAGE.md) - API路径构建器详细使用说明

### 🔧 配置文档
- [环境配置](docs/ENVIRONMENT_CONFIGURATION.md) - 环境变量配置说明

## 🏗️ 项目架构

### 后端架构
```
backend/
├── app/
│   ├── core/                 # 核心模块
│   │   ├── api_router.py    # API路由管理
│   │   ├── api_paths.py     # API路径常量
│   │   ├── config.py        # 配置管理
│   │   ├── database.py      # 数据库管理
│   │   ├── error_handling.py # 错误处理
│   │   ├── logging.py       # 日志记录
│   │   └── exception_monitoring.py # 异常监控
│   ├── api/                 # API路由
│   ├── models/              # 数据模型
│   ├── services/            # 业务逻辑
│   └── utils/               # 工具函数
├── migrations/              # 数据库迁移
├── tests/                   # 测试文件
└── requirements.txt         # 依赖包
```

### 前端架构
```
php-frontend/
├── config/                  # 配置文件
│   ├── api_endpoints.js    # API端点配置
│   ├── environment.php     # 环境配置
│   └── api_config.php     # API配置
├── includes/               # 公共文件
│   ├── ApiPathBuilder/     # API路径构建器
│   │   ├── APIPathBuilder.php # 后端API路径构建器
│   │   └── ApiPathBuilder.js # 前端API路径构建器
│   ├── ApiPathManager.php  # API路径管理
│   └── EnhancedApiClient.php # API客户端
├── assets/                 # 静态资源
├── pages/                  # 页面文件
└── services/               # 服务文件
```

## 🔌 API接口

### 认证接口
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/logout` - 用户登出
- `POST /api/v1/auth/refresh` - 刷新令牌
- `GET /api/v1/auth/me` - 获取当前用户信息

### WireGuard管理
- `GET /api/v1/wireguard/servers` - 获取服务器列表
- `POST /api/v1/wireguard/servers` - 创建服务器
- `GET /api/v1/wireguard/servers/{id}` - 获取服务器详情
- `PUT /api/v1/wireguard/servers/{id}` - 更新服务器
- `DELETE /api/v1/wireguard/servers/{id}` - 删除服务器

### 客户端管理
- `GET /api/v1/wireguard/clients` - 获取客户端列表
- `POST /api/v1/wireguard/clients` - 创建客户端
- `GET /api/v1/wireguard/clients/{id}/config` - 获取客户端配置
- `GET /api/v1/wireguard/clients/{id}/qr-code` - 获取二维码

### 监控接口
- `GET /api/v1/monitoring/dashboard` - 监控仪表板
- `GET /api/v1/exceptions/summary` - 异常摘要
- `GET /api/v1/alerts/active` - 活跃告警
- `GET /api/v1/health` - 健康检查

## 🐳 Docker支持

### 开发环境
```bash
docker-compose up -d
```

### 生产环境
```bash
docker-compose -f docker-compose.production.yml up -d
```

### 微服务架构
```bash
docker-compose -f docker-compose.microservices.yml up -d
```

## 🔧 配置说明

### 环境变量
```bash
# 数据库配置
DATABASE_URL=mysql://user:password@localhost:3306/ipv6wgm

# API配置
API_V1_STR=/api/v1
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=11520

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# 路径配置
INSTALL_DIR=/opt/ipv6-wireguard-manager
FRONTEND_DIR=/var/www/html
CONFIG_DIR=/etc/wireguard
LOG_DIR=/var/log/ipv6-wireguard-manager
```

### 配置文件
- `backend/app/core/config.py` - 主配置文件
- `php-frontend/config/api_config.php` - 前端API配置
- `env.template` - 环境变量模板

## 📊 监控和日志

### 监控功能
- **系统监控** - CPU、内存、磁盘使用率
- **网络监控** - 带宽使用、连接数统计
- **应用监控** - API响应时间、错误率
- **数据库监控** - 连接数、查询性能

### 日志功能
- **结构化日志** - JSON格式日志记录
- **日志轮转** - 自动日志轮转和清理
- **敏感信息过滤** - 自动过滤密码、令牌等敏感信息
- **异常监控** - 智能异常检测和告警

### 告警功能
- **异常告警** - 异常频率过高告警
- **性能告警** - 系统性能异常告警
- **安全告警** - 安全事件告警
- **自定义告警** - 可配置的告警规则

## 🧪 测试

### 运行测试
```bash
# 后端测试
cd backend
python -m pytest tests/

# 前端测试
cd php-frontend
php -l *.php

# 集成测试
python test_api_standardization.py
python test_config_management.py
python test_database_optimization.py
python test_error_handling_logging.py
```

### 测试覆盖
- **单元测试** - 核心功能单元测试
- **集成测试** - API接口集成测试
- **性能测试** - 系统性能压力测试
- **安全测试** - 安全漏洞扫描测试
- **API路径构建器测试** - API路径构建器功能测试

## 🤝 贡献指南

### 开发环境设置
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 创建开发分支
git checkout -b feature/your-feature

# 安装依赖
cd backend && pip install -r requirements.txt
cd ../php-frontend && composer install
```

### 代码规范
- **Python**: 遵循PEP 8规范
- **PHP**: 遵循PSR-12规范
- **提交信息**: 使用约定式提交规范
- **文档**: 使用Markdown格式

### 提交流程
1. Fork项目
2. 创建功能分支
3. 提交代码
4. 创建Pull Request
5. 代码审查
6. 合并代码

## 📄 许可证

本项目采用 [MIT许可证](LICENSE)。

## 🆘 支持

### 获取帮助
- **文档**: [完整文档](https://github.com/ipzh/ipv6-wireguard-manager/tree/main/docs)
- **Issues**: [提交问题和建议](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **讨论**: [参与社区讨论](https://github.com/ipzh/ipv6-wireguard-manager/discussions)
- **邮件**: 发送邮件到 support@example.com

### 常见问题
- [安装问题](docs/DEPLOYMENT_GUIDE.md#troubleshooting) - 安装和部署问题
- [配置问题](docs/ENVIRONMENT_CONFIGURATION.md) - 环境配置问题
- [API问题](docs/API_DOCUMENTATION.md#troubleshooting) - API使用问题
- [开发问题](docs/DEVELOPER_GUIDE.md#troubleshooting) - 开发环境问题

## 🗺️ 路线图

### 即将发布
- [ ] WebSocket实时通信
- [ ] 移动端应用
- [ ] 多租户支持
- [ ] 插件系统

### 长期计划
- [ ] 云原生部署
- [ ] 机器学习集成
- [ ] 区块链集成
- [ ] 边缘计算支持

---

**IPv6 WireGuard Manager** - 现代化的企业级VPN管理解决方案 🚀