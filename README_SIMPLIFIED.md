# IPv6 WireGuard Manager - 简化版

## 🚀 快速开始

### 一键安装
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 手动安装
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 安装依赖
pip install -r requirements.txt

# 启动后端
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# 访问前端
# 打开浏览器访问 http://localhost
```

## 📋 功能特性

### 核心功能
- ✅ **WireGuard管理** - 服务器配置、客户端管理
- ✅ **用户认证** - 简单的登录认证系统
- ✅ **网络监控** - 基础网络状态监控
- ✅ **健康检查** - 系统健康状态检查
- ✅ **IPv4/IPv6双栈** - 支持双栈网络配置

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
- **MySQL** - 数据库（可选，支持模拟模式）
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
│   └── requirements.txt    # Python依赖
├── php-frontend/           # PHP前端
├── install.sh             # 安装脚本
└── README_SIMPLIFIED.md   # 简化文档
```

## 🔧 配置说明

### 环境变量
```bash
# 数据库配置（可选）
DATABASE_URL=mysql://user:password@localhost/dbname

# 应用配置
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=3.0.0
DEBUG=false
```

### 默认登录
- 用户名: `admin`
- 密码: `admin`

## 🚀 部署

### 生产环境
```bash
# 使用安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --production

# 或手动部署
./install.sh --production
```

### Docker部署
```bash
# 构建镜像
docker build -t ipv6-wireguard-manager .

# 运行容器
docker run -d -p 80:80 -p 8000:8000 ipv6-wireguard-manager
```

## 📞 支持

- **GitHub Issues**: [提交问题](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **文档**: 查看 `/docs` 获取API文档
- **健康检查**: 访问 `/api/v1/health` 检查服务状态

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件
