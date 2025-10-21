# IPv6 WireGuard Manager 安装部署指南

## 📋 概述

本指南提供了IPv6 WireGuard Manager的完整安装部署方案，支持Docker、原生安装、一键安装等多种方式。

## 🎯 安装方式选择

| 安装方式 | 适用场景 | 复杂度 | 推荐度 |
|---------|---------|--------|--------|
| 一键安装 | 快速体验、测试环境 | ⭐ | ⭐⭐⭐⭐⭐ |
| Docker部署 | 生产环境、容器化部署 | ⭐⭐ | ⭐⭐⭐⭐ |
| 原生安装 | 定制化部署、性能优化 | ⭐⭐⭐ | ⭐⭐⭐ |
| 手动配置 | 高级用户、特殊需求 | ⭐⭐⭐⭐ | ⭐⭐ |

## 🚀 方式一：一键安装（推荐）

### 快速安装
```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者下载后运行
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
./install.sh
```

### 安装选项
```bash
# 仅Docker部署
./install.sh --docker-only

# 仅原生部署
./install.sh --native-only

# 跳过依赖检查
./install.sh --skip-deps

# 跳过配置步骤
./install.sh --skip-config

# 强制安装（覆盖现有配置）
./install.sh --force
```

## 🐳 方式二：Docker部署

### 基础Docker部署
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 直接启动（自动生成模式）
docker-compose up -d

# 查看自动生成的凭据
docker-compose logs backend | grep "自动生成的"
```

### 生产环境部署
```bash
# 使用生产环境配置
docker-compose -f docker-compose.production.yml up -d

# 使用微服务架构
docker-compose -f docker-compose.microservices.yml up -d

# 使用低内存配置
docker-compose -f docker-compose.low-memory.yml up -d
```

### 手动配置
```bash
# 复制环境配置
cp env.template .env

# 编辑配置文件
vim .env
# 设置您的密钥和密码

# 启动服务
docker-compose up -d
```

## 🖥️ 方式三：原生安装

### 系统要求
- **操作系统**: Ubuntu 20.04+, CentOS 8+, Debian 11+
- **架构**: x86_64, ARM64
- **CPU**: 2核心以上
- **内存**: 4GB以上
- **存储**: 20GB以上可用空间
- **网络**: 支持IPv6的网络环境

### 快速原生安装
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行原生安装脚本
./scripts/install_native.sh

# 或使用模块化安装脚本
./install.sh --native-only
```

### 分步安装
```bash
# 1. 环境检查
./install.sh environment

# 2. 安装依赖
./install.sh dependencies

# 3. 配置系统
./install.sh configuration

# 4. 部署应用
./install.sh deployment

# 5. 启动服务
./install.sh service

# 6. 验证安装
./install.sh verification
```

### 依赖安装
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget nginx mysql-server redis-server
sudo apt install -y php8.1 php8.1-fpm php8.1-mysql php8.1-mbstring php8.1-json php8.1-curl
sudo apt install -y python3 python3-pip python3-venv wireguard-tools

# CentOS/RHEL
sudo yum update -y
sudo yum install -y git curl wget nginx mysql-server redis
sudo yum install -y php php-fpm php-mysql php-mbstring php-json php-curl
sudo yum install -y python3 python3-pip wireguard-tools
```

## 🔧 配置管理

### 环境变量配置
```bash
# 复制配置模板
cp env.template .env

# 编辑配置文件
vim .env
```

### 主要配置项
```bash
# 应用配置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.1.0"
DEBUG=false
ENVIRONMENT="production"

# 服务器配置
SERVER_HOST="0.0.0.0"
SERVER_PORT=8000
SECRET_KEY="your-secret-key-here"

# 数据库配置
DATABASE_URL="mysql://ipv6wgm:password@localhost:3306/ipv6wgm"

# Redis配置
REDIS_URL="redis://localhost:6379/0"

# 管理员配置
FIRST_SUPERUSER="admin"
FIRST_SUPERUSER_PASSWORD="admin123"
```

### 数据库配置
```bash
# MySQL配置
sudo mysql_secure_installation

# 创建数据库和用户
mysql -u root -p
CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Nginx配置
```bash
# 创建Nginx站点配置
sudo vim /etc/nginx/sites-available/ipv6wgm

# 站点配置内容
server {
    listen 80;
    server_name your_domain_or_ip;
    
    root /var/www/html/ipv6wgm-frontend/public;
    index index.php index.html;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
    
    location /api/v1/ {
        proxy_pass http://127.0.0.1:8000/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# 启用站点
sudo ln -s /etc/nginx/sites-available/ipv6wgm /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 🚀 服务管理

### 启动服务
```bash
# Docker环境
docker-compose up -d

# 原生环境
sudo systemctl start ipv6-wireguard-manager
sudo systemctl start nginx
sudo systemctl start mysql
sudo systemctl start redis
```

### 检查服务状态
```bash
# Docker环境
docker-compose ps

# 原生环境
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status redis
```

### 查看日志
```bash
# Docker环境
docker-compose logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mysql

# 原生环境
sudo journalctl -u ipv6-wireguard-manager -f
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/mysql/error.log
```

### 重启服务
```bash
# Docker环境
docker-compose restart

# 原生环境
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl restart nginx
sudo systemctl restart mysql
sudo systemctl restart redis
```

## 🌐 访问系统

### 主要访问地址
- **Web界面**: http://localhost
- **API接口**: http://localhost/api/v1
- **API文档**: http://localhost/docs
- **健康检查**: http://localhost/health

### 监控面板
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **指标收集**: http://localhost/metrics

### 默认凭据
- **管理员用户名**: admin
- **管理员密码**: admin123 (首次登录后请修改)
- **数据库用户**: ipv6wgm
- **数据库密码**: ipv6wgm_password

## 🔧 故障排除

### 常见问题

#### 1. 端口冲突
```bash
# 检查端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :3306
netstat -tulpn | grep :8000

# 修改端口配置
vim .env
# 修改 SERVER_PORT=8080
```

#### 2. 数据库连接失败
```bash
# 检查数据库服务
docker-compose logs mysql
sudo systemctl status mysql

# 检查数据库连接
mysql -u ipv6wgm -p -h localhost ipv6wgm

# 重置数据库
docker-compose down -v
docker-compose up -d
```

#### 3. 权限问题
```bash
# 修复文件权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 修复WireGuard权限
sudo chown -R root:root /etc/wireguard
sudo chmod 600 /etc/wireguard/*.key
```

#### 4. 网络问题
```bash
# 检查防火墙
sudo ufw status
sudo firewall-cmd --list-all

# 检查IPv6支持
ip -6 addr show
ping6 -c 4 2001:db8::1

# 检查WireGuard
sudo wg show
sudo systemctl status wg-quick@wg0
```

#### 5. 服务启动失败
```bash
# 检查依赖
python3 --version
php --version
mysql --version
redis-server --version

# 检查配置文件
python3 -c "from backend.app.core.unified_config import settings; print('Config OK')"

# 检查数据库迁移
cd backend && alembic upgrade head
```

### 日志分析
```bash
# 应用日志
tail -f logs/app.log
tail -f logs/error.log

# 系统日志
journalctl -u ipv6-wireguard-manager -f
journalctl -u nginx -f
journalctl -u mysql -f

# Docker日志
docker-compose logs -f backend
docker-compose logs -f frontend
```

### 性能优化
```bash
# 数据库优化
mysql -u root -p
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Slow_queries';

# 缓存优化
redis-cli info memory
redis-cli config get maxmemory
redis-cli monitor

# 系统资源
htop
df -h
free -h
iostat -x 1
```

## 📊 验证安装

### 功能验证
```bash
# 检查API健康状态
curl http://localhost/api/v1/health

# 检查前端访问
curl http://localhost/

# 检查数据库连接
python3 -c "
from backend.app.core.database import get_db
db = next(get_db())
print('Database connection OK')
"

# 检查Redis连接
redis-cli ping
```

### 性能测试
```bash
# API性能测试
curl -w "@curl-format.txt" -o /dev/null -s http://localhost/api/v1/health

# 数据库性能测试
mysql -u root -p -e "SELECT COUNT(*) FROM information_schema.tables;"

# 系统资源监控
htop
```

## 🔄 升级和维护

### 系统升级
```bash
# 备份数据
./scripts/backup/backup_manager.py --backup

# 更新代码
git pull origin main

# 更新依赖
pip install -r backend/requirements.txt

# 数据库迁移
cd backend && alembic upgrade head

# 重启服务
docker-compose restart
# 或
sudo systemctl restart ipv6-wireguard-manager
```

### 数据备份
```bash
# 自动备份
./scripts/backup/backup_manager.py --backup

# 手动备份
mysqldump -u root -p ipv6wgm > backup_$(date +%Y%m%d_%H%M%S).sql

# 恢复备份
mysql -u root -p ipv6wgm < backup_20240101_120000.sql
```

## 📞 技术支持

### 获取帮助
- **文档**: [docs/](docs/)
- **问题反馈**: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **讨论**: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

### 社区支持
- **技术交流**: 参与社区讨论
- **经验分享**: 分享部署经验
- **问题解答**: 帮助其他用户

---

**安装指南版本**: 3.1.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队
