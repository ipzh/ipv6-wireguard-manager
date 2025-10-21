# IPv6 WireGuard Manager 原生安装指南

## 📋 安装概述

本指南介绍如何在Linux/Unix系统上直接安装IPv6 WireGuard Manager，无需Docker容器化部署。

## 🚀 快速安装

### 一键安装（推荐）
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行原生安装脚本
./scripts/install.sh --native-only

# 或分步安装
./scripts/install.sh --native-only environment dependencies configuration deployment
```

### 手动安装
```bash
# 1. 环境检查
./scripts/install.sh environment

# 2. 安装依赖
./scripts/install.sh dependencies

# 3. 配置系统
./scripts/install.sh configuration

# 4. 部署应用
./scripts/install.sh deployment

# 5. 启动服务
./scripts/install.sh service

# 6. 验证安装
./scripts/install.sh verification
```

## 🔧 系统要求

### 操作系统
- **Linux**: Ubuntu 20.04+, CentOS 8+, Debian 11+
- **macOS**: macOS 10.15+ (开发环境)
- **架构**: x86_64, ARM64

### 硬件要求
- **CPU**: 2核心以上
- **内存**: 4GB以上
- **存储**: 20GB以上可用空间
- **网络**: 支持IPv6的网络环境

### 软件依赖
- **Python**: 3.8+ (推荐3.9+)
- **PHP**: 8.1+ (推荐8.2+)
- **MySQL**: 8.0+ (推荐8.0.30+)
- **Redis**: 6.0+ (推荐7.0+)
- **Nginx**: 1.18+ (推荐1.20+)
- **Git**: 2.20+

## 📦 依赖安装

### Ubuntu/Debian系统
```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 安装基础依赖
sudo apt install -y \
    python3 python3-pip python3-venv \
    php8.1 php8.1-fpm php8.1-mysql php8.1-curl php8.1-json \
    mysql-server redis-server nginx \
    git curl wget unzip \
    build-essential libssl-dev libffi-dev

# 安装Python依赖
pip3 install --user -r backend/requirements.txt

# 安装PHP依赖（如果需要）
# composer install --no-dev --optimize-autoloader
```

### CentOS/RHEL系统
```bash
# 更新系统包
sudo yum update -y

# 安装EPEL仓库
sudo yum install -y epel-release

# 安装基础依赖
sudo yum install -y \
    python3 python3-pip \
    php php-fpm php-mysql php-curl php-json \
    mysql-server redis nginx \
    git curl wget unzip \
    gcc gcc-c++ make openssl-devel libffi-devel

# 启动服务
sudo systemctl start mysqld redis nginx
sudo systemctl enable mysqld redis nginx

# 安装Python依赖
pip3 install --user -r backend/requirements.txt
```

### macOS系统
```bash
# 安装Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装依赖
brew install python@3.9 php mysql redis nginx git

# 启动服务
brew services start mysql
brew services start redis
brew services start nginx

# 安装Python依赖
pip3 install -r backend/requirements.txt
```

## ⚙️ 系统配置

### 1. 数据库配置

#### MySQL配置
```bash
# 启动MySQL服务
sudo systemctl start mysql
sudo systemctl enable mysql

# 安全配置
sudo mysql_secure_installation

# 创建数据库和用户
sudo mysql -e "CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'your_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

#### 数据库优化配置
```bash
# 编辑MySQL配置文件
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

# 添加以下配置
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
max_connections = 200
query_cache_size = 64M
query_cache_type = 1

# 重启MySQL
sudo systemctl restart mysql
```

### 2. Redis配置

#### Redis配置
```bash
# 编辑Redis配置文件
sudo nano /etc/redis/redis.conf

# 修改以下配置
maxmemory 512mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000

# 重启Redis
sudo systemctl restart redis
```

### 3. Nginx配置

#### 创建Nginx配置
```bash
# 创建站点配置
sudo nano /etc/nginx/sites-available/ipv6-wireguard-manager

# 添加以下配置
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/ipv6-wireguard-manager/php-frontend;
    index index.php;

    # 前端文件
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP处理
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 静态文件
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# 启用站点
sudo ln -s /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. PHP配置

#### PHP-FPM配置
```bash
# 编辑PHP-FPM配置
sudo nano /etc/php/8.1/fpm/pool.d/www.conf

# 修改以下配置
user = www-data
group = www-data
listen = /var/run/php/php8.1-fpm.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

# 重启PHP-FPM
sudo systemctl restart php8.1-fpm
```

## 🚀 应用部署

### 1. 环境配置

#### 创建环境文件
```bash
# 复制环境模板
cp env.template .env

# 编辑环境配置
nano .env

# 配置内容
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=3.1.0
DEBUG=false
ENVIRONMENT=production

# 数据库配置
DATABASE_URL=mysql://ipv6wgm:your_password@localhost:3306/ipv6wgm

# 安全配置
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# 服务器配置
SERVER_HOST=127.0.0.1
SERVER_PORT=8000

# Redis配置
REDIS_URL=redis://localhost:6379/0
USE_REDIS=true
```

### 2. 数据库初始化

#### 运行数据库迁移
```bash
# 进入后端目录
cd backend

# 激活Python虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 运行数据库迁移
alembic upgrade head

# 或使用初始化脚本
python init_database.py
```

### 3. 应用启动

#### 后端服务启动
```bash
# 使用systemd服务（推荐）
sudo cp scripts/ipv6-wireguard-manager.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ipv6-wireguard-manager
sudo systemctl start ipv6-wireguard-manager

# 或手动启动
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

#### 创建systemd服务文件
```bash
# 创建服务文件
sudo nano /etc/systemd/system/ipv6-wireguard-manager.service

# 添加以下内容
[Unit]
Description=IPv6 WireGuard Manager API
After=network.target mysql.service redis.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/path/to/ipv6-wireguard-manager/backend
Environment=PATH=/path/to/ipv6-wireguard-manager/backend/venv/bin
ExecStart=/path/to/ipv6-wireguard-manager/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

## 🔧 服务管理

### 启动服务
```bash
# 启动所有服务
sudo systemctl start mysql redis nginx php8.1-fpm ipv6-wireguard-manager

# 启用开机自启
sudo systemctl enable mysql redis nginx php8.1-fpm ipv6-wireguard-manager
```

### 停止服务
```bash
# 停止所有服务
sudo systemctl stop ipv6-wireguard-manager nginx php8.1-fpm redis mysql
```

### 重启服务
```bash
# 重启所有服务
sudo systemctl restart mysql redis nginx php8.1-fpm ipv6-wireguard-manager
```

### 查看服务状态
```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
sudo systemctl status php8.1-fpm
sudo systemctl status redis
sudo systemctl status mysql
```

## 📊 监控和日志

### 查看应用日志
```bash
# 查看应用日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看Nginx日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# 查看PHP-FPM日志
sudo tail -f /var/log/php8.1-fpm.log
```

### 健康检查
```bash
# 检查API健康状态
curl http://localhost:8000/health

# 检查前端访问
curl http://localhost/

# 检查数据库连接
mysql -u ipv6wgm -p -e "SELECT 1;"
```

## 🔒 安全配置

### 防火墙配置
```bash
# 配置UFW防火墙
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 51820/udp  # WireGuard
sudo ufw enable
```

### SSL/TLS配置
```bash
# 使用Let's Encrypt获取SSL证书
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com

# 或使用自签名证书
sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/private/ipv6wgm.key -out /etc/ssl/certs/ipv6wgm.crt -days 365 -nodes
```

## 🧪 测试安装

### 运行测试套件
```bash
# 运行所有测试
python scripts/run_tests.py --all

# 运行特定测试
python scripts/run_tests.py --unit
python scripts/run_tests.py --integration
python scripts/run_tests.py --performance
```

### 功能验证
```bash
# 验证API端点
curl http://localhost:8000/api/v1/health

# 验证前端访问
curl http://localhost/

# 验证数据库连接
python backend/test_db_connection.py
```

## 🔧 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 检查端口占用
sudo netstat -tlnp | grep :8000
sudo netstat -tlnp | grep :80

# 检查配置文件
sudo nginx -t
sudo systemctl status ipv6-wireguard-manager
```

#### 2. 数据库连接失败
```bash
# 检查MySQL服务
sudo systemctl status mysql

# 检查数据库配置
mysql -u ipv6wgm -p -e "SHOW DATABASES;"

# 检查连接参数
python backend/test_db_connection.py
```

#### 3. 权限问题
```bash
# 设置正确的文件权限
sudo chown -R www-data:www-data /path/to/ipv6-wireguard-manager
sudo chmod -R 755 /path/to/ipv6-wireguard-manager
```

### 日志分析
```bash
# 查看详细错误日志
sudo journalctl -u ipv6-wireguard-manager --no-pager -l
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/mysql/error.log
```

## 📚 相关文档

- [部署指南](DEPLOYMENT_GUIDE.md) - 完整的部署说明
- [配置管理](CONFIGURATION_GUIDE.md) - 系统配置说明
- [故障排除](TROUBLESHOOTING_GUIDE.md) - 问题诊断解决
- [API参考](API_REFERENCE.md) - API接口文档

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
