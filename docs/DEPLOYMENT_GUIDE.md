# 部署指南

## 概述

本文档提供IPv6 WireGuard Manager的详细部署指南，包括开发环境、测试环境、生产环境等多种部署方式。

## 环境要求

### 系统要求

| 组件 | 最低要求 | 推荐配置 |
|------|----------|----------|
| **操作系统** | Linux/macOS/Windows | Ubuntu 20.04+ / CentOS 8+ |
| **CPU** | 2核心 | 4核心+ |
| **内存** | 2GB | 8GB+ |
| **存储** | 10GB | 50GB+ SSD |
| **网络** | 100Mbps | 1Gbps+ |

### 软件要求

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| **Python** | 3.8+ | 后端运行环境 |
| **Node.js** | 16+ | 前端构建环境 |
| **MySQL** | 8.0+ | 数据库 |
| **Nginx** | 1.18+ | Web服务器 |
| **Docker** | 20.10+ | 容器化部署 |
| **WireGuard** | 1.0+ | VPN协议支持 |

## 部署方式

### 1. 自动安装脚本部署

#### 1.1 快速安装

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

#### 1.2 自定义安装

```bash
# 使用自定义参数安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- \
  --install-dir /opt/ipv6-wireguard-manager \
  --frontend-dir /var/www/html \
  --config-dir /etc/wireguard \
  --log-dir /var/log/ipv6-wireguard-manager \
  --nginx-dir /etc/nginx/sites-available \
  --systemd-dir /etc/systemd/system \
  --api-port 8000 \
  --web-port 80
```

#### 1.3 安装脚本参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--install-dir` | `/opt/ipv6-wireguard-manager` | 安装目录 |
| `--frontend-dir` | `/var/www/html` | 前端Web目录 |
| `--config-dir` | `/etc/wireguard` | WireGuard配置目录 |
| `--log-dir` | `/var/log/ipv6-wireguard-manager` | 日志目录 |
| `--nginx-dir` | `/etc/nginx/sites-available` | Nginx配置目录 |
| `--systemd-dir` | `/etc/systemd/system` | Systemd服务目录 |
| `--api-port` | `8000` | API服务端口 |
| `--web-port` | `80` | Web服务端口 |

### 2. Docker部署

#### 2.1 开发环境

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

#### 2.2 生产环境

```bash
# 使用生产环境配置
docker-compose -f docker-compose.production.yml up -d
```

#### 2.3 微服务架构

```bash
# 使用微服务配置
docker-compose -f docker-compose.microservices.yml up -d
```

#### 2.4 Docker环境变量

```bash
# 数据库配置
MYSQL_ROOT_PASSWORD=your_secure_password
MYSQL_DATABASE=ipv6wgm
MYSQL_USER=ipv6wgm
MYSQL_PASSWORD=your_db_password

# API配置
API_V1_STR=/api/v1
SECRET_KEY=your_secret_key_here
ACCESS_TOKEN_EXPIRE_MINUTES=11520

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# 路径配置
INSTALL_DIR=/app
FRONTEND_DIR=/var/www/html
CONFIG_DIR=/app/config
LOG_DIR=/app/logs
```

### 3. 手动部署

#### 3.1 后端部署

```bash
# 1. 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 2. 创建虚拟环境
cd backend
python -m venv venv
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate  # Windows

# 3. 安装依赖
pip install -r requirements.txt

# 4. 配置环境变量
cp env.example .env
# 编辑 .env 文件

# 5. 初始化数据库
python init_database.py

# 6. 启动服务
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

#### 3.2 前端部署

```bash
# 1. 安装Node.js依赖
cd php-frontend
npm install

# 2. 配置API端点
cp config/api_config.php.example config/api_config.php
# 编辑配置文件

# 3. 部署到Web服务器
sudo cp -r * /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
```

#### 3.3 数据库配置

```bash
# 1. 安装MySQL
sudo apt update
sudo apt install mysql-server

# 2. 创建数据库和用户
mysql -u root -p
```

```sql
CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';
FLUSH PRIVILEGES;
```

```bash
# 3. 导入数据库结构
mysql -u ipv6wgm -p ipv6wgm < migrations/init.sql
```

#### 3.4 Nginx配置

```bash
# 1. 安装Nginx
sudo apt install nginx

# 2. 创建配置文件
sudo nano /etc/nginx/sites-available/ipv6-wireguard-manager
```

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com;
    root /var/www/html;
    index index.php index.html;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # PHP处理
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 日志配置
    access_log /var/log/nginx/ipv6-wireguard-manager_access.log;
    error_log /var/log/nginx/ipv6-wireguard-manager_error.log;
}
```

```bash
# 3. 启用站点
sudo ln -s /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

#### 3.5 Systemd服务配置

```bash
# 1. 创建服务文件
sudo nano /etc/systemd/system/ipv6-wireguard-manager.service
```

```ini
[Unit]
Description=IPv6 WireGuard Manager
After=network.target mysql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/ipv6-wireguard-manager/backend
Environment=PATH=/opt/ipv6-wireguard-manager/backend/venv/bin
Environment=INSTALL_DIR=/opt/ipv6-wireguard-manager
Environment=LOG_DIR=/var/log/ipv6-wireguard-manager
Environment=CONFIG_DIR=/etc/wireguard
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/uvicorn app.main:app --host :: --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# 2. 启用服务
sudo systemctl daemon-reload
sudo systemctl enable ipv6-wireguard-manager
sudo systemctl start ipv6-wireguard-manager
```

## 环境配置

### 1. 开发环境

#### 1.1 环境变量配置

```bash
# .env 文件
DEBUG=true
LOG_LEVEL=DEBUG
DATABASE_URL=mysql://ipv6wgm:password@localhost:3306/ipv6wgm
SECRET_KEY=dev_secret_key
API_V1_STR=/api/v1
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

#### 1.2 开发工具配置

```bash
# 安装开发工具
pip install -r requirements-dev.txt

# 运行测试
python -m pytest tests/

# 代码格式化
black app/
isort app/

# 类型检查
mypy app/
```

### 2. 测试环境

#### 2.1 环境变量配置

```bash
# .env.test 文件
DEBUG=false
LOG_LEVEL=INFO
DATABASE_URL=mysql://ipv6wgm:password@test-db:3306/ipv6wgm_test
SECRET_KEY=test_secret_key
API_V1_STR=/api/v1
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

#### 2.2 测试数据库配置

```bash
# 创建测试数据库
mysql -u root -p
```

```sql
CREATE DATABASE ipv6wgm_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON ipv6wgm_test.* TO 'ipv6wgm'@'%';
FLUSH PRIVILEGES;
```

### 3. 生产环境

#### 3.1 环境变量配置

```bash
# .env.production 文件
DEBUG=false
LOG_LEVEL=WARNING
DATABASE_URL=mysql://ipv6wgm:secure_password@prod-db:3306/ipv6wgm
SECRET_KEY=your_very_secure_secret_key_here
API_V1_STR=/api/v1
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# 安全配置
CORS_ORIGINS=["https://your-domain.com"]
TRUSTED_HOSTS=["your-domain.com"]
```

#### 3.2 SSL/TLS配置

```bash
# 1. 安装Certbot
sudo apt install certbot python3-certbot-nginx

# 2. 获取SSL证书
sudo certbot --nginx -d your-domain.com

# 3. 自动续期
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

#### 3.3 防火墙配置

```bash
# 1. 配置UFW防火墙
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 51820/udp  # WireGuard端口
```

#### 3.4 系统优化

```bash
# 1. 系统参数优化
sudo nano /etc/sysctl.conf
```

```bash
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr

# WireGuard优化
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

```bash
# 2. 应用配置
sudo sysctl -p
```

## 监控和日志

### 1. 系统监控

#### 1.1 Prometheus监控

```bash
# 1. 安装Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xzf prometheus-2.40.0.linux-amd64.tar.gz
sudo mv prometheus-2.40.0.linux-amd64 /opt/prometheus

# 2. 配置Prometheus
sudo nano /opt/prometheus/prometheus.yml
```

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ipv6-wireguard-manager'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: '/metrics'
    scrape_interval: 5s
```

#### 1.2 Grafana仪表板

```bash
# 1. 安装Grafana
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt update
sudo apt install grafana

# 2. 启动Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### 2. 日志管理

#### 2.1 日志轮转配置

```bash
# 1. 配置logrotate
sudo nano /etc/logrotate.d/ipv6-wireguard-manager
```

```
/var/log/ipv6-wireguard-manager/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload ipv6-wireguard-manager
    endscript
}
```

#### 2.2 ELK Stack集成

```bash
# 1. 安装Elasticsearch
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.5.0-linux-x86_64.tar.gz
tar xzf elasticsearch-8.5.0-linux-x86_64.tar.gz
sudo mv elasticsearch-8.5.0 /opt/elasticsearch

# 2. 安装Logstash
wget https://artifacts.elastic.co/downloads/logstash/logstash-8.5.0-linux-x86_64.tar.gz
tar xzf logstash-8.5.0-linux-x86_64.tar.gz
sudo mv logstash-8.5.0 /opt/logstash

# 3. 安装Kibana
wget https://artifacts.elastic.co/downloads/kibana/kibana-8.5.0-linux-x86_64.tar.gz
tar xzf kibana-8.5.0-linux-x86_64.tar.gz
sudo mv kibana-8.5.0 /opt/kibana
```

## 备份和恢复

### 1. 数据备份

#### 1.1 数据库备份

```bash
# 1. 创建备份脚本
sudo nano /opt/ipv6-wireguard-manager/scripts/backup.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/opt/ipv6-wireguard-manager/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="ipv6wgm"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 数据库备份
mysqldump -u ipv6wgm -p$DB_PASSWORD $DB_NAME > $BACKUP_DIR/database_$DATE.sql

# 配置文件备份
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /etc/wireguard /opt/ipv6-wireguard-manager/config

# 清理旧备份（保留30天）
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

```bash
# 2. 设置定时备份
sudo crontab -e
# 添加: 0 2 * * * /opt/ipv6-wireguard-manager/scripts/backup.sh
```

#### 1.2 配置文件备份

```bash
# 1. 备份WireGuard配置
sudo cp -r /etc/wireguard /opt/ipv6-wireguard-manager/backups/wireguard_$(date +%Y%m%d)

# 2. 备份应用配置
sudo cp -r /opt/ipv6-wireguard-manager/config /opt/ipv6-wireguard-manager/backups/config_$(date +%Y%m%d)
```

### 2. 数据恢复

#### 2.1 数据库恢复

```bash
# 1. 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 2. 恢复数据库
mysql -u ipv6wgm -p ipv6wgm < /opt/ipv6-wireguard-manager/backups/database_20240101_120000.sql

# 3. 启动服务
sudo systemctl start ipv6-wireguard-manager
```

## API路径构建器部署

### 1. 概述

API路径构建器是IPv6 WireGuard Manager v3.1.0引入的新功能，它提供了一个统一的方式来管理API路径，简化了前端与后端的集成，并提高了API的可维护性。

### 2. 部署要求

| 组件 | 要求 | 说明 |
|------|------|------|
| **PHP版本** | 7.4+ | 前端API路径构建器需要PHP 7.4或更高版本 |
| **JavaScript** | ES6+ | 前端JavaScript路径构建器需要现代浏览器支持 |
| **Python** | 3.8+ | 后端路径构建器需要Python 3.8或更高版本 |
| **权限** | 读写权限 | 需要对配置目录有读写权限 |

### 3. 部署步骤

#### 3.1 自动部署

使用安装脚本自动部署时，API路径构建器会自动安装和配置：

```bash
# 使用默认设置安装（包含API路径构建器）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 使用自定义参数安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- \
  --install-dir /opt/ipv6-wireguard-manager \
  --api-port 8000 \
  --enable-path-builder
```

#### 3.2 手动部署

##### 3.2.1 后端部署

```bash
# 1. 确保后端已部署并运行
cd /opt/ipv6-wireguard-manager/backend

# 2. 安装路径构建器依赖
pip install -r requirements_path_builder.txt

# 3. 初始化路径构建器
python -m app.core.path_builder --init

# 4. 验证安装
python -m app.core.path_builder --test
```

##### 3.2.2 前端部署

```bash
# 1. 确保前端已部署
cd /var/www/html

# 2. 复制路径构建器文件
sudo cp -r /opt/ipv6-wireguard-manager/php-frontend/api_path_builder /var/www/html/
sudo cp -r /opt/ipv6-wireguard-manager/php-frontend/js_path_builder /var/www/html/

# 3. 设置权限
sudo chown -R www-data:www-data /var/www/html/api_path_builder
sudo chown -R www-data:www-data /var/www/html/js_path_builder
sudo chmod -R 755 /var/www/html/api_path_builder
sudo chmod -R 755 /var/www/html/js_path_builder
```

##### 3.2.3 配置文件设置

```bash
# 1. 创建配置目录
sudo mkdir -p /etc/ipv6-wireguard-manager/path_builder

# 2. 复制配置文件
sudo cp /opt/ipv6-wireguard-manager/config/path_builder_config.json /etc/ipv6-wireguard-manager/path_builder/

# 3. 编辑配置文件
sudo nano /etc/ipv6-wireguard-manager/path_builder/path_builder_config.json
```

```json
{
  "api_version": "v1",
  "base_url": "http://localhost:8000",
  "endpoints": {
    "auth": {
      "login": "/auth/login",
      "logout": "/auth/logout",
      "refresh": "/auth/refresh"
    },
    "users": {
      "list": "/users/",
      "create": "/users/",
      "detail": "/users/{id}",
      "update": "/users/{id}",
      "delete": "/users/{id}"
    }
  },
  "cache_enabled": true,
  "cache_ttl": 3600
}
```

### 4. Docker部署

#### 4.1 Docker Compose配置

在`docker-compose.yml`中添加API路径构建器服务：

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - ENABLE_PATH_BUILDER=true
    volumes:
      - ./config/path_builder_config.json:/app/config/path_builder_config.json

  frontend:
    build: ./php-frontend
    ports:
      - "80:80"
    volumes:
      - ./php-frontend/api_path_builder:/var/www/html/api_path_builder
      - ./php-frontend/js_path_builder:/var/www/html/js_path_builder
```

#### 4.2 Docker环境变量

```bash
# 启用API路径构建器
ENABLE_PATH_BUILDER=true

# 路径构建器配置文件路径
PATH_BUILDER_CONFIG_PATH=/app/config/path_builder_config.json

# 缓存设置
PATH_BUILDER_CACHE_ENABLED=true
PATH_BUILDER_CACHE_TTL=3600
```

### 5. 验证部署

#### 5.1 后端验证

```bash
# 测试后端路径构建器
curl -X GET "http://localhost:8000/api/v1/path_builder/status" \
  -H "accept: application/json"

# 预期响应
{
  "status": "active",
  "version": "3.1.0",
  "endpoints_count": 25,
  "cache_status": "enabled"
}
```

#### 5.2 前端验证

```bash
# 测试PHP路径构建器
php -r "require_once '/var/www/html/api_path_builder/PathBuilder.php'; \$pb = new PathBuilder(); echo \$pb->getVersion();"

# 测试JavaScript路径构建器
node -e "const pb = require('/var/www/html/js_path_builder/PathBuilder.js'); console.log(pb.getVersion());"
```

#### 5.3 集成测试

```bash
# 运行集成测试
cd /opt/ipv6-wireguard-manager
python tests/test_path_builder_integration.py
```

### 6. 常见问题

#### 6.1 路径构建器未启用

**问题**: API路径构建器功能不可用

**解决方案**:
```bash
# 检查配置文件
cat /etc/ipv6-wireguard-manager/path_builder/path_builder_config.json

# 检查环境变量
echo $ENABLE_PATH_BUILDER

# 手动启用
export ENABLE_PATH_BUILDER=true
sudo systemctl restart ipv6-wireguard-manager
```

#### 6.2 路径构建器缓存问题

**问题**: API路径更新后缓存未刷新

**解决方案**:
```bash
# 清除缓存
rm -rf /tmp/ipv6-wireguard-manager/path_builder_cache/*

# 重启服务
sudo systemctl restart ipv6-wireguard-manager

# 禁用缓存（临时）
export PATH_BUILDER_CACHE_ENABLED=false
```

#### 6.3 权限问题

**问题**: 路径构建器无法访问配置文件

**解决方案**:
```bash
# 设置正确权限
sudo chown -R www-data:www-data /etc/ipv6-wireguard-manager/path_builder
sudo chmod 644 /etc/ipv6-wireguard-manager/path_builder/path_builder_config.json
```

### 7. 性能优化

#### 7.1 缓存优化

```json
{
  "cache_enabled": true,
  "cache_ttl": 3600,
  "cache_strategy": "lru",
  "cache_size": 1000
}
```

#### 7.2 并发优化

```bash
# 增加工作进程
sudo nano /etc/systemd/system/ipv6-wireguard-manager.service
```

```ini
[Service]
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/uvicorn app.main:app --host :: --port 8000 --workers 4
Environment=PATH_BUILDER_WORKERS=4
```

### 8. 监控与日志

#### 8.1 日志配置

```bash
# 配置路径构建器日志
sudo mkdir -p /var/log/ipv6-wireguard-manager/path_builder
sudo nano /etc/ipv6-wireguard-manager/path_builder/logging_config.json
```

```json
{
  "version": 1,
  "disable_existing_loggers": false,
  "formatters": {
    "standard": {
      "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
    }
  },
  "handlers": {
    "default": {
      "level": "INFO",
      "formatter": "standard",
      "class": "logging.StreamHandler"
    },
    "file": {
      "level": "INFO",
      "formatter": "standard",
      "class": "logging.FileHandler",
      "filename": "/var/log/ipv6-wireguard-manager/path_builder/path_builder.log",
      "mode": "a"
    }
  },
  "loggers": {
    "path_builder": {
      "handlers": ["default", "file"],
      "level": "INFO",
      "propagate": false
    }
  }
}
```

#### 8.2 监控指标

```bash
# 查看路径构建器状态
curl -X GET "http://localhost:8000/api/v1/path_builder/metrics" \
  -H "accept: application/json"
```

```json
{
  "requests_total": 1250,
  "cache_hits": 1180,
  "cache_misses": 70,
  "average_response_time": "2.5ms",
  "uptime": "2d 14h 32m"
}
```

## 高级部署

### 1. 微服务架构

#### 1.1 独立路径构建器服务

```yaml
# docker-compose.microservices.yml
version: '3.8'

services:
  path-builder:
    build: ./path_builder
    ports:
      - "8001:8000"
    environment:
      - SERVICE_NAME=path-builder
      - API_VERSION=v1
    volumes:
      - ./config/path_builder_config.json:/app/config/path_builder_config.json
    restart: unless-stopped
```

#### 1.2 API网关配置

```nginx
# /etc/nginx/sites-available/ipv6-wireguard-manager
server {
    listen 80;
    server_name your-domain.com;

    location /api/v1/paths/ {
        proxy_pass http://localhost:8001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/v1/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 2. 集群部署

#### 2.1 负载均衡配置

```nginx
upstream path_builder_backend {
    server 10.0.1.10:8000;
    server 10.0.1.11:8000;
    server 10.0.1.12:8000;
}

server {
    listen 80;
    server_name your-domain.com;

    location /api/v1/paths/ {
        proxy_pass http://path_builder_backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 2.2 共享缓存配置

```bash
# 使用Redis作为共享缓存
docker run -d --name path-builder-cache \
  -p 6379:6379 \
  redis:alpine
```

```json
{
  "cache_enabled": true,
  "cache_backend": "redis",
  "cache_redis_url": "redis://localhost:6379/0",
  "cache_ttl": 3600
}
```

### 3. 多环境部署

#### 3.1 开发环境

```bash
# 开发环境配置
export ENVIRONMENT=development
export PATH_BUILDER_DEBUG=true
export PATH_BUILDER_CACHE_ENABLED=false
export PATH_BUILDER_LOG_LEVEL=DEBUG
```

#### 3.2 测试环境

```bash
# 测试环境配置
export ENVIRONMENT=testing
export PATH_BUILDER_DEBUG=false
export PATH_BUILDER_CACHE_ENABLED=true
export PATH_BUILDER_CACHE_TTL=300
export PATH_BUILDER_LOG_LEVEL=INFO
```

#### 3.3 生产环境

```bash
# 生产环境配置
export ENVIRONMENT=production
export PATH_BUILDER_DEBUG=false
export PATH_BUILDER_CACHE_ENABLED=true
export PATH_BUILDER_CACHE_TTL=3600
export PATH_BUILDER_LOG_LEVEL=WARNING
export PATH_BUILDER_MONITORING_ENABLED=true
```

## 版本兼容性

### 1. 向后兼容性

API路径构建器设计为向后兼容，支持旧版本的API端点：

```json
{
  "compatibility_mode": true,
  "legacy_endpoints": {
    "v1": "/api/v1",
    "v2": "/api/v2"
  }
}
```

### 2. 版本升级

#### 2.1 从v3.0.x升级到v3.1.x

```bash
# 1. 备份配置
sudo cp /etc/ipv6-wireguard-manager/api_config.json /etc/ipv6-wireguard-manager/api_config.json.backup

# 2. 更新代码
cd /opt/ipv6-wireguard-manager
git pull origin main

# 3. 安装路径构建器
./install.sh --upgrade --enable-path-builder

# 4. 迁移配置
python scripts/migrate_to_path_builder.py

# 5. 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

#### 2.2 配置迁移

```python
# migrate_to_path_builder.py
import json
import os

def migrate_config():
    # 读取旧配置
    with open('/etc/ipv6-wireguard-manager/api_config.json', 'r') as f:
        old_config = json.load(f)
    
    # 创建新配置
    new_config = {
        "api_version": "v1",
        "base_url": old_config.get("api_base_url", "http://localhost:8000"),
        "endpoints": {
            "auth": {
                "login": "/auth/login",
                "logout": "/auth/logout",
                "refresh": "/auth/refresh"
            },
            "users": {
                "list": "/users/",
                "create": "/users/",
                "detail": "/users/{id}",
                "update": "/users/{id}",
                "delete": "/users/{id}"
            }
        },
        "cache_enabled": True,
        "cache_ttl": 3600
    }
    
    # 保存新配置
    os.makedirs('/etc/ipv6-wireguard-manager/path_builder', exist_ok=True)
    with open('/etc/ipv6-wireguard-manager/path_builder/path_builder_config.json', 'w') as f:
        json.dump(new_config, f, indent=2)
    
    print("配置迁移完成")

if __name__ == "__main__":
    migrate_config()
```

---

**注意**: API路径构建器是IPv6 WireGuard Manager v3.1.0的新功能，部署前请确保系统满足所有要求。如需更多帮助，请参考[API路径构建器使用指南](API_PATH_BUILDER_USAGE.md)。
#### 2.2 配置文件恢复

```bash
# 1. 恢复WireGuard配置
sudo cp -r /opt/ipv6-wireguard-manager/backups/wireguard_20240101 /etc/wireguard

# 2. 恢复应用配置
sudo cp -r /opt/ipv6-wireguard-manager/backups/config_20240101 /opt/ipv6-wireguard-manager/config

# 3. 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

## 故障排除

### 1. 常见问题

#### 1.1 服务启动失败

```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f

# 检查端口占用
sudo netstat -tlnp | grep 8000
```

#### 1.2 数据库连接失败

```bash
# 检查数据库状态
sudo systemctl status mysql

# 测试数据库连接
mysql -u ipv6wgm -p -h localhost ipv6wgm

# 检查数据库配置
cat /opt/ipv6-wireguard-manager/backend/.env
```

#### 1.3 WireGuard配置问题

```bash
# 检查WireGuard状态
sudo wg show

# 检查配置文件
sudo cat /etc/wireguard/wg0.conf

# 测试WireGuard连接
sudo wg-quick up wg0
```

### 2. 性能优化

#### 2.1 数据库优化

```sql
-- 检查慢查询
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';

-- 优化表
OPTIMIZE TABLE users, wireguard_servers, wireguard_clients;
```

#### 2.2 应用优化

```bash
# 1. 增加工作进程
sudo nano /etc/systemd/system/ipv6-wireguard-manager.service
```

```ini
[Service]
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/uvicorn app.main:app --host :: --port 8000 --workers 4
```

### 3. 安全加固

#### 3.1 系统安全

```bash
# 1. 更新系统
sudo apt update && sudo apt upgrade -y

# 2. 配置SSH安全
sudo nano /etc/ssh/sshd_config
```

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

#### 3.2 应用安全

```bash
# 1. 设置文件权限
sudo chown -R www-data:www-data /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager
sudo chmod 600 /opt/ipv6-wireguard-manager/config/*.key

# 2. 配置防火墙
sudo ufw enable
sudo ufw allow from 192.168.1.0/24 to any port 22
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## 升级指南

### 1. 版本升级

#### 1.1 备份数据

```bash
# 1. 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 2. 备份数据库
mysqldump -u ipv6wgm -p ipv6wgm > backup_before_upgrade.sql

# 3. 备份配置文件
sudo cp -r /opt/ipv6-wireguard-manager /opt/ipv6-wireguard-manager_backup
```

#### 1.2 升级应用

```bash
# 1. 拉取最新代码
cd /opt/ipv6-wireguard-manager
git pull origin main

# 2. 更新依赖
cd backend
pip install -r requirements.txt

# 3. 运行数据库迁移
python migrations/upgrade.py

# 4. 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

### 2. 回滚操作

```bash
# 1. 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 2. 恢复备份
sudo rm -rf /opt/ipv6-wireguard-manager
sudo mv /opt/ipv6-wireguard-manager_backup /opt/ipv6-wireguard-manager

# 3. 恢复数据库
mysql -u ipv6wgm -p ipv6wgm < backup_before_upgrade.sql

# 4. 重启服务
sudo systemctl start ipv6-wireguard-manager
```

## 最佳实践

### 1. 部署最佳实践

- **环境隔离**: 开发、测试、生产环境完全隔离
- **配置管理**: 使用环境变量管理配置
- **版本控制**: 所有配置文件和代码使用版本控制
- **监控告警**: 部署完整的监控和告警系统
- **备份策略**: 定期备份数据和配置文件

### 2. 安全最佳实践

- **最小权限**: 使用最小权限原则
- **网络安全**: 配置防火墙和网络隔离
- **证书管理**: 使用有效的SSL/TLS证书
- **密码策略**: 使用强密码和定期更换
- **审计日志**: 记录所有操作和访问日志

### 3. 运维最佳实践

- **自动化部署**: 使用CI/CD自动化部署
- **健康检查**: 定期检查系统健康状态
- **性能监控**: 监控系统性能和资源使用
- **故障处理**: 建立故障处理流程
- **文档维护**: 保持文档的及时更新

---

**注意**: 本文档基于当前版本，如有更新请查看最新版本文档。
