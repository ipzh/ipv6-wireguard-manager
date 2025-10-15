# IPv6 WireGuard Manager 安装指南

> 📖 **详细安装指南** - 支持所有主流Linux发行版，IPv6/IPv4双栈网络

## 📋 目录

- [系统要求](#系统要求)
- [快速安装](#快速安装)
- [详细安装步骤](#详细安装步骤)
- [Docker安装](#docker安装)
- [配置说明](#配置说明)
- [故障排除](#故障排除)
- [卸载指南](#卸载指南)

## 🖥️ 系统要求

### 最低要求

| 组件 | 要求 |
|------|------|
| **操作系统** | Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+, Fedora 38+, Arch Linux, openSUSE 15+) |
| **内存** | 512MB RAM (最小化安装) |
| **存储** | 1GB 可用空间 |
| **网络** | IPv4网络连接 |
| **CPU** | 1核心 |

### 推荐配置

| 组件 | 要求 |
|------|------|
| **内存** | 2GB+ RAM |
| **存储** | 5GB+ 可用空间 |
| **网络** | IPv6/IPv4双栈网络 |
| **CPU** | 2+ 核心 |

### 支持的发行版

| 发行版 | 版本 | 包管理器 | 支持状态 | 测试状态 |
|--------|------|----------|----------|----------|
| Ubuntu | 20.04+ | APT | ✅ 完全支持 | ✅ 已测试 |
| Debian | 11+ | APT | ✅ 完全支持 | ✅ 已测试 |
| CentOS | 8+ | YUM | ✅ 完全支持 | ✅ 已测试 |
| RHEL | 8+ | YUM | ✅ 完全支持 | ✅ 已测试 |
| Fedora | 38+ | DNF | ✅ 完全支持 | ✅ 已测试 |
| Arch Linux | Latest | Pacman | ✅ 完全支持 | ✅ 已测试 |
| openSUSE | 15+ | Zypper | ✅ 完全支持 | ✅ 已测试 |

## 🚀 快速安装

### 一键安装（推荐）

```bash
# 自动选择最佳安装方式
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 指定安装方式

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

## 📝 详细安装步骤

### 1. 系统准备

#### 检查系统信息

```bash
# 检查操作系统
cat /etc/os-release

# 检查内存
free -h

# 检查磁盘空间
df -h

# 检查网络连接
ping -c 1 8.8.8.8
ping6 -c 1 2001:4860:4860::8888  # IPv6测试（可选）
```

#### 更新系统

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y

# Fedora
sudo dnf update -y

# Arch Linux
sudo pacman -Syu

# openSUSE
sudo zypper refresh && sudo zypper update -y
```

### 2. 安装系统依赖

#### Ubuntu/Debian

```bash
# 安装基础依赖
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# 安装Python 3.11
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev

# 安装Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装PostgreSQL
sudo apt install -y postgresql-15 postgresql-contrib-15

# 安装Redis
sudo apt install -y redis-server

# 安装Nginx
sudo apt install -y nginx

# 安装WireGuard
sudo apt install -y wireguard
```

#### CentOS/RHEL

```bash
# 安装EPEL仓库
sudo yum install -y epel-release

# 安装基础依赖
sudo yum install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gcc \
    gcc-c++ \
    make \
    postgresql-devel \
    python3-devel \
    libffi-devel \
    openssl-devel

# 安装Python 3
sudo yum install -y python3 python3-pip python3-devel

# 安装Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 安装PostgreSQL
sudo yum install -y postgresql-server postgresql-contrib

# 安装Redis
sudo yum install -y redis

# 安装Nginx
sudo yum install -y nginx

# 安装WireGuard
sudo yum install -y wireguard-tools
```

#### Fedora

```bash
# 安装基础依赖
sudo dnf install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gcc \
    gcc-c++ \
    make \
    postgresql-devel \
    python3-devel \
    libffi-devel \
    openssl-devel

# 安装Python 3
sudo dnf install -y python3 python3-pip python3-devel

# 安装Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# 安装PostgreSQL
sudo dnf install -y postgresql-server postgresql-contrib

# 安装Redis
sudo dnf install -y redis

# 安装Nginx
sudo dnf install -y nginx

# 安装WireGuard
sudo dnf install -y wireguard-tools
```

#### Arch Linux

```bash
# 更新包列表
sudo pacman -Sy

# 安装基础依赖
sudo pacman -S --noconfirm \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    base-devel \
    postgresql-libs \
    libffi \
    openssl

# 安装Python
sudo pacman -S --noconfirm python python-pip

# 安装Node.js
sudo pacman -S --noconfirm nodejs npm

# 安装PostgreSQL
sudo pacman -S --noconfirm postgresql

# 安装Redis
sudo pacman -S --noconfirm redis

# 安装Nginx
sudo pacman -S --noconfirm nginx

# 安装WireGuard
sudo pacman -S --noconfirm wireguard-tools
```

#### openSUSE

```bash
# 更新包列表
sudo zypper refresh

# 安装基础依赖
sudo zypper install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    patterns-devel-C-C++ \
    postgresql-devel \
    python3-devel \
    libffi-devel \
    openssl-devel

# 安装Python 3
sudo zypper install -y python3 python3-pip python3-devel

# 安装Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo zypper install -y nodejs

# 安装PostgreSQL
sudo zypper install -y postgresql-server postgresql-contrib

# 安装Redis
sudo zypper install -y redis

# 安装Nginx
sudo zypper install -y nginx

# 安装WireGuard
sudo zypper install -y wireguard-tools
```

### 3. 下载项目

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
```

### 4. 安装后端

```bash
cd backend

# 创建虚拟环境
python3.11 -m venv venv
source venv/bin/activate

# 安装Python依赖
pip install --upgrade pip
pip install -r requirements.txt
```

### 5. 安装前端

```bash
cd ../frontend

# 安装Node.js依赖
npm install

# 构建前端
npm run build
```

### 6. 配置数据库

```bash
# 启动PostgreSQL
sudo systemctl enable postgresql
sudo systemctl start postgresql

# 创建数据库和用户
sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;"
sudo -u postgres psql -c "CREATE USER ipv6wgm WITH PASSWORD 'password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;"

# 启动Redis
sudo systemctl enable redis
sudo systemctl start redis
```

### 7. 配置Nginx

```bash
# 创建Nginx配置
sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket支持
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 启用站点
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
```

### 8. 创建系统服务

```bash
# 创建服务用户
sudo useradd -r -s /bin/false -d /opt/ipv6-wireguard-manager ipv6wgm

# 移动项目到安装目录
sudo mkdir -p /opt/ipv6-wireguard-manager
sudo cp -r . /opt/ipv6-wireguard-manager/
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager

# 创建systemd服务文件
sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null << 'EOF'
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=exec
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=/opt/ipv6-wireguard-manager/backend
Environment=PATH=/opt/ipv6-wireguard-manager/backend/venv/bin
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable ipv6-wireguard-manager
```

### 9. 启动服务

```bash
# 启动应用服务
sudo systemctl start ipv6-wireguard-manager

# 检查服务状态
sudo systemctl status ipv6-wireguard-manager
```

## 🐳 Docker安装

### 安装Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# CentOS/RHEL
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Fedora
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Arch Linux
sudo pacman -S docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# openSUSE
sudo zypper install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

### 安装Docker Compose

```bash
# 下载Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 设置执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

### 启动Docker服务

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 开发环境
docker-compose up -d

# 生产环境
docker-compose -f docker-compose.production.yml up -d
```

## ⚙️ 配置说明

### 环境变量配置

#### 后端配置

创建 `backend/.env` 文件：

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

# 性能配置
MAX_WORKERS=4
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30
```

#### 前端配置

创建 `frontend/.env` 文件：

```bash
# API配置（自动检测，无需修改）
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8000

# 应用配置
VITE_APP_NAME=IPv6 WireGuard Manager
VITE_APP_VERSION=3.0.0
VITE_DEBUG=false

# 功能开关
VITE_ENABLE_WEBSOCKET=true
VITE_ENABLE_MONITORING=true
VITE_ENABLE_BGP=true
```

### 网络配置

#### IPv6/IPv4双栈支持

项目自动支持IPv6/IPv4双栈网络：

- **后端**: 监听所有接口 (`0.0.0.0`)
- **前端**: 自动检测网络协议
- **CORS**: 支持IPv6和IPv4访问
- **Nginx**: 同时监听IPv4和IPv6端口

#### 防火墙配置

```bash
# UFW配置
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw enable

# iptables配置
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
```

## 🔧 故障排除

### 常见问题

#### 1. 前端无法访问

**症状**: 浏览器显示无法访问或空白页面

**解决方案**:

```bash
# 检查Nginx状态
sudo systemctl status nginx

# 检查端口监听
sudo netstat -tuln | grep :80

# 检查Nginx配置
sudo nginx -t

# 检查前端文件
ls -la /opt/ipv6-wireguard-manager/frontend/dist/

# 重启Nginx
sudo systemctl restart nginx
```

#### 2. 后端API连接失败

**症状**: 前端无法连接到后端API

**解决方案**:

```bash
# 检查后端服务
sudo systemctl status ipv6-wireguard-manager

# 检查端口监听
sudo netstat -tuln | grep :8000

# 检查后端日志
sudo journalctl -u ipv6-wireguard-manager -f

# 测试API连接
curl http://localhost:8000/health
```

#### 3. 数据库连接失败

**症状**: 后端无法连接数据库

**解决方案**:

```bash
# 检查PostgreSQL状态
sudo systemctl status postgresql

# 检查数据库连接
sudo -u postgres psql -c "SELECT 1;"

# 检查用户权限
sudo -u postgres psql -c "SELECT * FROM pg_user WHERE usename='ipv6wgm';"

# 检查数据库
sudo -u postgres psql -c "SELECT datname FROM pg_database WHERE datname='ipv6wgm';"
```

#### 4. IPv6连接问题

**症状**: IPv6地址无法访问

**解决方案**:

```bash
# 检查IPv6支持
ping6 -c 1 2001:4860:4860::8888

# 检查IPv6配置
ip -6 addr show

# 检查Nginx IPv6配置
sudo nginx -t

# 检查防火墙IPv6规则
sudo ip6tables -L
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

# 网络连接测试
curl -4 http://localhost:8000/health  # IPv4
curl -6 http://localhost:8000/health  # IPv6
```

### 日志查看

```bash
# 应用日志
sudo journalctl -u ipv6-wireguard-manager -f

# Nginx日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# PostgreSQL日志
sudo tail -f /var/log/postgresql/postgresql-15-main.log

# Redis日志
sudo tail -f /var/log/redis/redis-server.log
```

## 🗑️ 卸载指南

### 完全卸载

```bash
# 停止服务
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl disable ipv6-wireguard-manager

# 删除服务文件
sudo rm -f /etc/systemd/system/ipv6-wireguard-manager.service
sudo systemctl daemon-reload

# 删除Nginx配置
sudo rm -f /etc/nginx/sites-enabled/ipv6-wireguard-manager
sudo rm -f /etc/nginx/sites-available/ipv6-wireguard-manager
sudo systemctl restart nginx

# 删除应用文件
sudo rm -rf /opt/ipv6-wireguard-manager

# 删除服务用户
sudo userdel ipv6wgm

# 删除数据库（可选）
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ipv6wgm;"
sudo -u postgres psql -c "DROP USER IF EXISTS ipv6wgm;"
```

### 保留数据卸载

```bash
# 备份数据库
sudo -u postgres pg_dump ipv6wgm > ipv6wgm_backup.sql

# 停止服务
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl disable ipv6-wireguard-manager

# 删除服务文件
sudo rm -f /etc/systemd/system/ipv6-wireguard-manager.service
sudo systemctl daemon-reload

# 删除Nginx配置
sudo rm -f /etc/nginx/sites-enabled/ipv6-wireguard-manager
sudo rm -f /etc/nginx/sites-available/ipv6-wireguard-manager
sudo systemctl restart nginx

# 删除应用文件
sudo rm -rf /opt/ipv6-wireguard-manager

# 删除服务用户
sudo userdel ipv6wgm

# 注意：数据库和用户保留，可以稍后恢复
```

## 📞 获取帮助

如果遇到问题，可以通过以下方式获取帮助：

- **项目地址**: https://github.com/ipzh/ipv6-wireguard-manager
- **问题反馈**: https://github.com/ipzh/ipv6-wireguard-manager/issues
- **讨论区**: https://github.com/ipzh/ipv6-wireguard-manager/discussions
- **文档**: https://github.com/ipzh/ipv6-wireguard-manager/wiki

---

**🎉 安装完成后，访问 http://localhost 开始使用IPv6 WireGuard Manager！**
