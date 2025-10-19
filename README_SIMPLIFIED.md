# IPv6 WireGuard Manager - 简化版

## 🚀 快速开始

### 一键安装
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 静默安装（推荐生产环境）
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent
```

### 手动安装
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行安装脚本
./install.sh --type native
```

## 📋 功能特性

### 核心功能
- ✅ **WireGuard管理** - 服务器配置、客户端管理
- ✅ **用户认证** - JWT令牌认证系统
- ✅ **网络监控** - 基础网络状态监控
- ✅ **健康检查** - 系统健康状态检查
- ✅ **IPv4/IPv6双栈** - 支持双栈网络配置
- ✅ **BGP路由管理** - BGP会话和路由宣告
- ✅ **IPv6前缀池** - 智能前缀分配和管理

### API端点
- `/api/v1/health` - 健康检查
- `/api/v1/auth/login` - 用户登录
- `/api/v1/users/` - 用户管理
- `/api/v1/wireguard/` - WireGuard管理
- `/api/v1/network/` - 网络管理
- `/api/v1/monitoring/` - 监控数据
- `/docs` - API文档

## 🛠️ 技术栈

### 后端
- **FastAPI** - 现代Python Web框架
- **MySQL** - 数据库
- **SQLAlchemy** - ORM
- **Uvicorn** - ASGI服务器

### 前端
- **PHP** - 服务器端渲染
- **Bootstrap** - UI框架
- **Nginx** - Web服务器

## 📁 项目结构

```
ipv6-wireguard-manager/
├── backend/                 # 后端API服务
│   ├── app/
│   │   ├── main.py         # 主应用入口
│   │   ├── core/           # 核心模块
│   │   ├── api/            # API端点
│   │   ├── models/         # 数据模型
│   │   └── services/       # 业务服务
│   ├── requirements.txt    # Python依赖
│   └── init_database_simple.py  # 数据库初始化
├── php-frontend/           # PHP前端
├── install.sh             # 主安装脚本
└── README.md              # 完整文档
```

## 🔧 配置说明

### 环境变量
```bash
# 数据库配置
DATABASE_URL=mysql+aiomysql://ipv6wgm:ipv6wgm_password@localhost:3306/ipv6wgm

# 应用配置
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=3.0.0
DEBUG=false
SECRET_KEY=<自动生成>

# API配置
API_V1_STR=/api/v1
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

### 默认登录
- 用户名: `admin`
- 密码: `admin123`
- 邮箱: `admin@example.com`

## 🚀 部署

### 生产环境
```bash
# 使用安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --production --silent

# 或手动部署
./install.sh --production
```

### Docker部署
```bash
# 使用Docker安装
./install.sh --type docker

# 或使用docker-compose
docker-compose up -d
```

## 📋 系统要求

### 最低要求
- **内存**: 1GB
- **磁盘**: 3GB
- **CPU**: 1核心

### 推荐配置
- **内存**: 2GB+
- **磁盘**: 5GB+

### 支持的系统
- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- Fedora 30+
- Arch Linux
- openSUSE 15+

## 🌐 访问地址

- **Web界面**: http://your-server-ip/
- **API文档**: http://your-server-ip:8000/docs
- **健康检查**: http://your-server-ip:8000/api/v1/health

## 🔧 管理命令

```bash
# 服务管理
ipv6-wireguard-manager start      # 启动服务
ipv6-wireguard-manager stop       # 停止服务
ipv6-wireguard-manager restart    # 重启服务
ipv6-wireguard-manager status     # 查看状态

# 系统管理
ipv6-wireguard-manager logs       # 查看日志
ipv6-wireguard-manager backup     # 创建备份
ipv6-wireguard-manager monitor    # 系统监控
```

## 📚 相关文档

- [完整文档](README.md) - 详细的功能说明
- [安装指南](INSTALLATION_GUIDE.md) - 安装步骤
- [API参考](API_REFERENCE.md) - API文档
- [部署配置](DEPLOYMENT_CONFIG.md) - 部署说明

## 📞 支持

- **GitHub Issues**: [提交问题](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **文档**: 查看 `/docs` 获取API文档
- **健康检查**: 访问 `/api/v1/health` 检查服务状态

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件