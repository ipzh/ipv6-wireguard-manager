# IPv6 WireGuard Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Node.js 18+](https://img.shields.io/badge/node.js-18+-green.svg)](https://nodejs.org/)
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
- ✅ **多Linux发行版支持** - 支持所有主流Linux发行版
- ✅ **性能优化** - 企业级性能优化配置
- ✅ **健康检查** - 全面的健康检查和自动恢复

## 🚀 快速开始

### 一键安装

```bash
# 一键安装（自动选择最佳安装方式）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 测试安装是否成功
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/test_installation.sh | bash
```

### 安装选项

```bash
# Docker安装（推荐新手）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s docker

# 原生安装（推荐VPS）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s native

# 最小化安装（低内存）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s minimal
```

### 自定义安装

```bash
# 指定安装目录和端口
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --dir /opt/my-app --port 8080

# 生产环境安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --production native

# 静默安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent --performance
```

## 📋 系统要求

### 最低要求
- **操作系统**: Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+, Fedora 38+, Arch Linux, openSUSE 15+)
- **内存**: 512MB RAM (最小化安装)
- **存储**: 1GB 可用空间
- **网络**: IPv4网络连接

### 推荐配置
- **内存**: 2GB+ RAM
- **存储**: 5GB+ 可用空间
- **网络**: IPv6/IPv4双栈网络
- **CPU**: 2+ 核心

### 支持的发行版

| 发行版 | 版本 | 包管理器 | 支持状态 |
|--------|------|----------|----------|
| Ubuntu | 20.04+ | APT | ✅ 完全支持 |
| Debian | 11+ | APT | ✅ 完全支持 |
| CentOS | 8+ | YUM | ✅ 完全支持 |
| RHEL | 8+ | YUM | ✅ 完全支持 |
| Fedora | 38+ | DNF | ✅ 完全支持 |
| Arch Linux | Latest | Pacman | ✅ 完全支持 |
| openSUSE | 15+ | Zypper | ✅ 完全支持 |

## 🐳 Docker部署

### 开发环境

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 启动开发环境
docker-compose up -d
```

### 生产环境

```bash
# 启动生产环境
docker-compose -f docker-compose.production.yml up -d
```

### Docker配置

项目支持IPv6双栈网络：

```yaml
networks:
  ipv6wgm-network:
    driver: bridge
    enable_ipv6: true
    ipam:
      config:
        - subnet: 172.18.0.0/16    # IPv4子网
        - subnet: 2001:db8::/64    # IPv6子网
```

## 🛠️ 手动安装

### 1. 安装系统依赖

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3.11 python3.11-venv nodejs npm postgresql redis-server nginx

# CentOS/RHEL
sudo yum update -y
sudo yum install -y python3 nodejs npm postgresql-server redis nginx

# Fedora
sudo dnf update -y
sudo dnf install -y python3 nodejs npm postgresql-server redis nginx

# Arch Linux
sudo pacman -S python nodejs npm postgresql redis nginx

# openSUSE
sudo zypper refresh
sudo zypper install -y python3 nodejs npm postgresql redis nginx
```

### 2. 克隆项目

```bash
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
```

### 3. 安装后端依赖

```bash
cd backend
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4. 安装前端依赖

```bash
cd ../frontend
npm install
npm run build
```

### 5. 配置数据库

```bash
# PostgreSQL
sudo -u postgres createdb ipv6wgm
sudo -u postgres createuser ipv6wgm
sudo -u postgres psql -c "ALTER USER ipv6wgm PASSWORD 'password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;"
```

### 6. 启动服务

```bash
# 启动后端
cd backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000

# 启动前端（新终端）
cd frontend
npm run dev
```

## 🔧 配置说明

### 环境变量

#### 后端配置

```bash
# 数据库配置
DATABASE_URL=postgresql://ipv6wgm:password@localhost:5432/ipv6wgm
REDIS_URL=redis://localhost:6379/0

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
DEBUG=false

# 安全配置
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=10080
```

#### 前端配置

```bash
# API配置（自动检测，无需修改）
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8000

# 应用配置
VITE_APP_NAME=IPv6 WireGuard Manager
VITE_APP_VERSION=3.0.0
VITE_DEBUG=false
```

### 网络配置

项目自动支持IPv6/IPv4双栈网络：

- **后端**: 监听所有接口 (`0.0.0.0`)
- **前端**: 自动检测网络协议
- **CORS**: 支持IPv6和IPv4访问
- **Nginx**: 同时监听IPv4和IPv6端口

## 📖 使用指南

### 访问系统

安装完成后，访问以下地址：

- **前端界面**: http://localhost
- **API文档**: http://localhost/api/v1/docs
- **健康检查**: http://localhost:8000/health

### 默认登录

- **用户名**: admin
- **密码**: admin123

### 管理命令

```bash
# 服务管理
sudo systemctl start ipv6-wireguard-manager
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl status ipv6-wireguard-manager

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f

# 启动脚本
./start.sh                    # 自动模式
./start.sh -m dev             # 开发模式
./start.sh -m prod -w 8       # 生产模式，8个工作进程
```

## 🔍 故障排除

### 常见问题

#### 1. 前端无法访问

```bash
# 检查Nginx状态
sudo systemctl status nginx

# 检查端口监听
sudo netstat -tuln | grep :80

# 检查防火墙
sudo ufw status
```

#### 2. 后端API连接失败

```bash
# 检查后端服务
sudo systemctl status ipv6-wireguard-manager

# 检查端口监听
sudo netstat -tuln | grep :8000

# 检查数据库连接
sudo systemctl status postgresql
```

#### 3. IPv6连接问题

```bash
# 检查IPv6支持
ping6 -c 1 2001:4860:4860::8888

# 检查IPv6配置
ip -6 addr show

# 检查Nginx IPv6配置
sudo nginx -t
```

### 诊断工具

项目提供了多个诊断工具：

```bash
# 系统兼容性检查
./check-linux-compatibility.sh

# 双栈支持验证
./verify-dual-stack-support.sh

# 数据库健康检查
python3 -c "from backend.app.core.database_health import get_database_health; print(get_database_health())"
```

## 📚 开发指南

### 项目结构

```
ipv6-wireguard-manager/
├── backend/                 # 后端代码
│   ├── app/
│   │   ├── api/            # API路由
│   │   ├── core/           # 核心配置
│   │   ├── models/         # 数据模型
│   │   └── services/       # 业务逻辑
│   ├── requirements.txt    # Python依赖
│   └── Dockerfile         # Docker配置
├── frontend/               # 前端代码
│   ├── src/
│   │   ├── components/     # React组件
│   │   ├── pages/         # 页面组件
│   │   ├── services/      # API服务
│   │   └── utils/         # 工具函数
│   ├── package.json       # Node.js依赖
│   └── Dockerfile         # Docker配置
├── docker-compose.yml     # 开发环境
├── docker-compose.production.yml  # 生产环境
├── install.sh             # 安装脚本
└── README.md              # 项目文档
```

### 开发环境设置

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 启动开发环境
docker-compose up -d

# 或者手动启动
cd backend && python3.11 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
cd ../frontend && npm install && npm run dev
```

### API文档

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI Schema**: http://localhost:8000/openapi.json

## 🔧 故障排除

### 常见问题

1. **安装后前端空白页面**:
   ```bash
   # 检查服务状态
   systemctl status ipv6-wireguard-manager nginx
   
   # 查看日志
   journalctl -u ipv6-wireguard-manager -f
   ```

2. **数据库连接失败**:
   ```bash
   # 检查数据库服务
   systemctl status mysql redis-server
   
   # 运行环境检查
   cd /opt/ipv6-wireguard-manager/backend
   python scripts/check_environment.py
   ```

3. **依赖安装失败**:
   ```bash
   # 重新安装依赖
   cd /opt/ipv6-wireguard-manager/backend
   source venv/bin/activate
   pip install -r requirements-minimal.txt
   ```

4. **端口冲突**:
   ```bash
   # 检查端口占用
   netstat -tlnp | grep -E ':(80|8000|3306|6379)'
   
   # 修改配置
   nano /opt/ipv6-wireguard-manager/backend/.env
   ```

### 测试安装

```bash
# 运行完整测试
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/test_installation.sh | bash

# 手动测试
curl http://localhost:8000/health
curl http://localhost/
```

## 🤝 贡献指南

我们欢迎所有形式的贡献！

### 如何贡献

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

### 开发规范

- 代码风格: 遵循项目现有的代码风格
- 提交信息: 使用清晰的提交信息
- 测试: 确保新功能有相应的测试
- 文档: 更新相关文档

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者和用户！

## 📞 支持

- **项目地址**: https://github.com/ipzh/ipv6-wireguard-manager
- **问题反馈**: https://github.com/ipzh/ipv6-wireguard-manager/issues
- **讨论区**: https://github.com/ipzh/ipv6-wireguard-manager/discussions

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给我们一个星标！**

Made with ❤️ by the IPv6 WireGuard Manager Team

</div>