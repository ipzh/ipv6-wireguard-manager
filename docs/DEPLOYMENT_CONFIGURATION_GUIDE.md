# IPv6 WireGuard Manager - 部署配置指南

## 📋 目录

- [概述](#概述)
- [系统要求](#系统要求)
- [安装方式](#安装方式)
- [配置管理](#配置管理)
- [环境变量](#环境变量)
- [数据库配置](#数据库配置)
- [网络配置](#网络配置)
- [安全配置](#安全配置)
- [监控配置](#监控配置)
- [备份配置](#备份配置)
- [集群配置](#集群配置)
- [性能优化](#性能优化)
- [故障排除](#故障排除)

## 概述

IPv6 WireGuard Manager 支持多种部署方式，包括单机部署、Docker部署、集群部署等。本指南详细介绍了各种部署方式的配置方法。

### 部署架构

```
┌─────────────────────────────────────────────────────────────┐
│                    IPv6 WireGuard Manager                   │
├─────────────────────────────────────────────────────────────┤
│  Frontend (PHP)  │  Backend (Python)  │  Database (MySQL)   │
│  - Nginx         │  - FastAPI         │  - 主从复制         │
│  - PHP-FPM       │  - Uvicorn         │  - 备份策略         │
│  - PWA支持       │  - 异步处理        │  - 监控告警         │
├─────────────────────────────────────────────────────────────┤
│  Cache (Redis)   │  Message Queue     │  File Storage       │
│  - 会话存储      │  - Celery          │  - 配置文件         │
│  - 数据缓存      │  - 任务队列        │  - 日志文件         │
│  - 速率限制      │  - 定时任务        │  - 备份文件         │
└─────────────────────────────────────────────────────────────┘
```

## 系统要求

### 最低要求

| 组件 | 最低配置 | 推荐配置 |
|------|----------|----------|
| **CPU** | 2核心 | 4核心+ |
| **内存** | 2GB | 8GB+ |
| **存储** | 20GB SSD | 100GB+ SSD |
| **网络** | 100Mbps | 1Gbps+ |
| **操作系统** | Ubuntu 20.04+ | Ubuntu 22.04 LTS |

### 软件依赖

#### 系统软件

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    mysql-server \
    redis-server \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-curl \
    php8.1-json \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-zip \
    git \
    curl \
    wget \
    unzip \
    supervisor \
    systemd \
    ufw \
    fail2ban

# CentOS/RHEL
sudo yum update
sudo yum install -y \
    python3.11 \
    python3.11-devel \
    mysql-server \
    redis \
    nginx \
    php-fpm \
    php-mysql \
    php-curl \
    php-json \
    php-mbstring \
    php-xml \
    php-zip \
    git \
    curl \
    wget \
    unzip \
    supervisor \
    systemd \
    firewalld \
    fail2ban
```

#### Python依赖

```bash
# 核心依赖
pip install -r requirements.txt

# 开发依赖
pip install -r requirements-dev.txt

# 最小化部署
pip install -r requirements-minimal.txt
```

## 安装方式

### 1. 一键安装（推荐）

```bash
# 基础安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 指定安装目录
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --dir /opt/ipv6-wireguard

# 指定端口
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --port 8080

# 静默安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent

# 生产环境安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --production

# 高性能安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --performance

# 最小化安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --minimal
```

### 2. Docker安装

```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 配置环境变量
cp .env.example .env
nano .env

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps
docker-compose logs -f
```

### 3. 手动安装

```bash
# 1. 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 2. 创建虚拟环境
python3.11 -m venv venv
source venv/bin/activate

# 3. 安装依赖
pip install -r requirements.txt

# 4. 配置环境变量
cp .env.example .env
nano .env

# 5. 初始化数据库
python backend/scripts/init_database.py

# 6. 启动服务
python backend/scripts/start_server.py
```

## 配置管理

### 配置文件结构

```
ipv6-wireguard-manager/
├── .env                          # 环境变量配置
├── docker-compose.yml            # Docker配置
├── docker-compose.production.yml # 生产环境Docker配置
├── nginx.conf                    # Nginx配置
├── php-fpm.conf                  # PHP-FPM配置
├── supervisor.conf               # Supervisor配置
├── backend/
│   ├── app/
│   │   ├── core/
│   │   │   ├── config.py         # 应用配置
│   │   │   ├── database.py       # 数据库配置
│   │   │   └── security.py       # 安全配置
│   │   └── main.py               # 主应用
│   └── requirements.txt          # Python依赖
├── php-frontend/
│   ├── config/
│   │   ├── config.php            # PHP配置
│   │   └── database.php          # 数据库配置
│   └── .htaccess                 # Apache配置
└── scripts/
    ├── install.sh                # 安装脚本
    ├── start.sh                  # 启动脚本
    └── backup.sh                 # 备份脚本
```

### 环境变量配置

#### 基础配置

```bash
# .env
# 应用配置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.0.0"
APP_DEBUG=false
APP_ENV=production
APP_URL=https://your-domain.com

# 安全配置
SECRET_KEY=your-secret-key-here
JWT_SECRET_KEY=your-jwt-secret-key-here
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=60
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# 数据库配置
DATABASE_URL=mysql+pymysql://username:password@localhost:3306/ipv6wgm
DB_HOST=localhost
DB_PORT=3306
DB_NAME=ipv6wgm
DB_USER=ipv6wgm
DB_PASS=your-mysql-password
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
DB_POOL_TIMEOUT=30
DB_POOL_RECYCLE=3600

# Redis配置
REDIS_URL=redis://localhost:6379/0
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=
REDIS_POOL_SIZE=10

# 邮件配置
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_TLS=true
SMTP_SSL=false

# 监控配置
ENABLE_MONITORING=true
MONITORING_INTERVAL=60
METRICS_RETENTION_DAYS=30
ALERT_EMAIL=admin@your-domain.com

# 备份配置
BACKUP_ENABLED=true
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION_DAYS=30
BACKUP_STORAGE_PATH=/backups
BACKUP_ENCRYPTION=true
BACKUP_ENCRYPTION_KEY=your-backup-encryption-key

# 集群配置
CLUSTER_ENABLED=false
CLUSTER_NODE_ID=node1
CLUSTER_NODES=node1:8000,node2:8000,node3:8000
CLUSTER_LEADER_ELECTION=true
CLUSTER_HEARTBEAT_INTERVAL=30
```

#### 高级配置

```bash
# 性能配置
WORKER_PROCESSES=4
WORKER_CONNECTIONS=1000
KEEPALIVE_TIMEOUT=65
CLIENT_MAX_BODY_SIZE=10M

# 缓存配置
CACHE_ENABLED=true
CACHE_DEFAULT_TIMEOUT=300
CACHE_KEY_PREFIX=ipv6wgm:
CACHE_BACKEND=redis

# 日志配置
LOG_LEVEL=INFO
LOG_FORMAT=json
LOG_FILE_PATH=/var/log/ipv6-wireguard-manager
LOG_MAX_SIZE=100MB
LOG_BACKUP_COUNT=10
LOG_ROTATION=daily

# 安全配置
ENABLE_RATE_LIMITING=true
RATE_LIMIT_PER_MINUTE=1000
RATE_LIMIT_BURST=2000
ENABLE_IP_WHITELIST=false
IP_WHITELIST=192.168.1.0/24,10.0.0.0/8
ENABLE_AUDIT_LOGGING=true
AUDIT_LOG_RETENTION_DAYS=365

# 双因子认证配置
ENABLE_2FA=true
TOTP_ISSUER=IPv6 WireGuard Manager
SMS_PROVIDER=twilio
SMS_API_KEY=your-sms-api-key
SMS_API_SECRET=your-sms-api-secret

# API配置
API_RATE_LIMIT_PER_MINUTE=1000
API_RATE_LIMIT_BURST=2000
API_KEY_EXPIRY_DAYS=365
API_KEY_MAX_PER_USER=10

# WebSocket配置
WEBSOCKET_ENABLED=true
WEBSOCKET_HEARTBEAT_INTERVAL=30
WEBSOCKET_MAX_CONNECTIONS=1000
```

## 数据库配置

### MySQL配置

#### 基础配置

```ini
# /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
# 基础设置
port = 3306
bind-address = 127.0.0.1
socket = /var/run/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid
datadir = /var/lib/mysql
tmpdir = /tmp

# 字符集设置
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'

# 连接设置
max_connections = 200
max_connect_errors = 1000
connect_timeout = 10
wait_timeout = 28800
interactive_timeout = 28800

# 缓存设置
key_buffer_size = 32M
max_allowed_packet = 16M
table_open_cache = 4000
sort_buffer_size = 2M
read_buffer_size = 2M
read_rnd_buffer_size = 8M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
query_cache_size = 32M
query_cache_limit = 2M

# InnoDB设置
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50
innodb_file_per_table = 1

# 日志设置
log-error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 安全设置
local-infile = 0
symbolic-links = 0
```

#### 高可用配置

```ini
# 主从复制配置
[mysqld]
# 主服务器配置
server-id = 1
log-bin = mysql-bin
binlog-format = ROW
expire_logs_days = 7
max_binlog_size = 100M

# 从服务器配置
server-id = 2
relay-log = mysql-relay-bin
read_only = 1
log_slave_updates = 1

# 集群配置
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_name = "ipv6wgm_cluster"
wsrep_cluster_address = "gcomm://192.168.1.10,192.168.1.11,192.168.1.12"
wsrep_node_name = "node1"
wsrep_node_address = "192.168.1.10"
wsrep_sst_method = rsync
```

### 数据库初始化

```sql
-- 创建数据库
CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建用户
CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'your-secure-password';
CREATE USER 'ipv6wgm'@'%' IDENTIFIED BY 'your-secure-password';

-- 授权
GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';
GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'%';

-- 刷新权限
FLUSH PRIVILEGES;

-- 创建表结构
USE ipv6wgm;
SOURCE backend/database/schema.sql;

-- 插入初始数据
SOURCE backend/database/initial_data.sql;
```

## 网络配置

### Nginx配置

#### 基础配置

```nginx
# /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # 基础设置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # MIME类型
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # 包含站点配置
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

#### 站点配置

```nginx
# /etc/nginx/sites-available/ipv6-wireguard-manager
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com www.your-domain.com;
    
    # 重定向到HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # SSL配置
    ssl_certificate /etc/ssl/certs/your-domain.com.crt;
    ssl_certificate_key /etc/ssl/private/your-domain.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # 根目录
    root /var/www/ipv6-wireguard-manager/php-frontend;
    index index.php index.html;
    
    # 客户端最大上传大小
    client_max_body_size 10M;
    
    # 静态文件缓存
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # PHP处理
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket代理
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
    
    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # 禁止访问敏感文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /(config|logs|backups)/ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

### 防火墙配置

#### UFW配置

```bash
# 启用UFW
sudo ufw enable

# 允许SSH
sudo ufw allow 22/tcp

# 允许HTTP和HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许WireGuard端口
sudo ufw allow 51820/udp
sudo ufw allow 51821/udp

# 允许BGP端口
sudo ufw allow 179/tcp

# 允许管理端口（仅内网）
sudo ufw allow from 192.168.1.0/24 to any port 8000

# 查看状态
sudo ufw status verbose
```

#### iptables配置

```bash
# 清除现有规则
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# 设置默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许回环接口
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许HTTP和HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 允许WireGuard
iptables -A INPUT -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -p udp --dport 51821 -j ACCEPT

# 允许BGP
iptables -A INPUT -p tcp --dport 179 -j ACCEPT

# 允许内网访问管理端口
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 8000 -j ACCEPT

# 保存规则
iptables-save > /etc/iptables/rules.v4
```

## 安全配置

### SSL/TLS配置

#### 使用Let's Encrypt

```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 自动续期
sudo crontab -e
# 添加以下行
0 12 * * * /usr/bin/certbot renew --quiet
```

#### 自签名证书

```bash
# 创建私钥
openssl genrsa -out your-domain.com.key 2048

# 创建证书签名请求
openssl req -new -key your-domain.com.key -out your-domain.com.csr

# 创建自签名证书
openssl x509 -req -days 365 -in your-domain.com.csr -signkey your-domain.com.key -out your-domain.com.crt

# 移动证书文件
sudo mv your-domain.com.crt /etc/ssl/certs/
sudo mv your-domain.com.key /etc/ssl/private/
sudo chmod 600 /etc/ssl/private/your-domain.com.key
```

### 安全加固

#### Fail2ban配置

```ini
# /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
```

#### 系统安全配置

```bash
# 禁用root登录
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 更改SSH端口
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# 禁用密码认证
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# 重启SSH服务
sudo systemctl restart sshd

# 设置文件权限
sudo chmod 600 /etc/ssl/private/*
sudo chmod 644 /etc/ssl/certs/*
sudo chown -R www-data:www-data /var/www/ipv6-wireguard-manager
```

## 监控配置

### 系统监控

#### Prometheus配置

```yaml
# /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "ipv6wgm_rules.yml"

scrape_configs:
  - job_name: 'ipv6wgm'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['localhost:9104']

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['localhost:9121']
```

#### Grafana配置

```json
{
  "dashboard": {
    "title": "IPv6 WireGuard Manager",
    "panels": [
      {
        "title": "系统CPU使用率",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU使用率"
          }
        ]
      },
      {
        "title": "内存使用率",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "内存使用率"
          }
        ]
      },
      {
        "title": "WireGuard连接数",
        "type": "stat",
        "targets": [
          {
            "expr": "ipv6wgm_wireguard_clients_total",
            "legendFormat": "客户端数量"
          }
        ]
      }
    ]
  }
}
```

### 应用监控

#### 健康检查配置

```python
# backend/app/core/health_check.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
import redis.asyncio as redis
import psutil
import time

router = APIRouter()

@router.get("/health")
async def health_check():
    """健康检查端点"""
    health_status = {
        "status": "healthy",
        "timestamp": time.time(),
        "version": "3.0.0",
        "checks": {}
    }
    
    # 数据库检查
    try:
        # 数据库连接检查
        health_status["checks"]["database"] = "healthy"
    except Exception as e:
        health_status["checks"]["database"] = f"unhealthy: {str(e)}"
        health_status["status"] = "unhealthy"
    
    # Redis检查
    try:
        # Redis连接检查
        health_status["checks"]["redis"] = "healthy"
    except Exception as e:
        health_status["checks"]["redis"] = f"unhealthy: {str(e)}"
        health_status["status"] = "unhealthy"
    
    # 系统资源检查
    cpu_percent = psutil.cpu_percent(interval=1)
    memory_percent = psutil.virtual_memory().percent
    disk_percent = psutil.disk_usage('/').percent
    
    health_status["checks"]["system"] = {
        "cpu_percent": cpu_percent,
        "memory_percent": memory_percent,
        "disk_percent": disk_percent
    }
    
    if cpu_percent > 90 or memory_percent > 90 or disk_percent > 90:
        health_status["status"] = "degraded"
    
    return health_status
```

## 备份配置

### 自动备份脚本

```bash
#!/bin/bash
# /opt/ipv6-wireguard-manager/scripts/backup.sh

# 配置
BACKUP_DIR="/backups"
APP_DIR="/opt/ipv6-wireguard-manager"
DB_NAME="ipv6wgm"
DB_USER="ipv6wgm"
DB_PASS="your-mysql-password"
RETENTION_DAYS=30
ENCRYPTION_KEY="your-encryption-key"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 生成备份文件名
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME.tar.gz"

# 创建临时目录
TEMP_DIR="/tmp/backup_$BACKUP_NAME"
mkdir -p $TEMP_DIR

# 备份数据库
echo "备份数据库..."
mysqldump -u$DB_USER -p$DB_PASS $DB_NAME > $TEMP_DIR/database.sql

# 备份应用文件
echo "备份应用文件..."
cp -r $APP_DIR/php-frontend $TEMP_DIR/
cp -r $APP_DIR/backend $TEMP_DIR/
cp $APP_DIR/.env $TEMP_DIR/
cp $APP_DIR/docker-compose.yml $TEMP_DIR/

# 备份配置文件
echo "备份配置文件..."
cp /etc/nginx/sites-available/ipv6-wireguard-manager $TEMP_DIR/nginx.conf
cp /etc/php/8.1/fpm/pool.d/www.conf $TEMP_DIR/php-fpm.conf

# 创建压缩包
echo "创建压缩包..."
tar -czf $BACKUP_FILE -C /tmp $BACKUP_NAME

# 加密备份文件
echo "加密备份文件..."
gpg --symmetric --cipher-algo AES256 --passphrase $ENCRYPTION_KEY $BACKUP_FILE
rm $BACKUP_FILE
mv $BACKUP_FILE.gpg $BACKUP_FILE

# 清理临时目录
rm -rf $TEMP_DIR

# 清理旧备份
echo "清理旧备份..."
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "备份完成: $BACKUP_FILE"
```

### 备份恢复脚本

```bash
#!/bin/bash
# /opt/ipv6-wireguard-manager/scripts/restore.sh

# 配置
BACKUP_FILE=$1
APP_DIR="/opt/ipv6-wireguard-manager"
DB_NAME="ipv6wgm"
DB_USER="ipv6wgm"
DB_PASS="your-mysql-password"
ENCRYPTION_KEY="your-encryption-key"

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <备份文件>"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

# 创建临时目录
TEMP_DIR="/tmp/restore_$(date +%Y%m%d_%H%M%S)"
mkdir -p $TEMP_DIR

# 解密备份文件
echo "解密备份文件..."
gpg --decrypt --passphrase $ENCRYPTION_KEY $BACKUP_FILE | tar -xzf - -C $TEMP_DIR

# 停止服务
echo "停止服务..."
systemctl stop nginx
systemctl stop php8.1-fpm
systemctl stop ipv6-wireguard-manager

# 恢复数据库
echo "恢复数据库..."
mysql -u$DB_USER -p$DB_PASS $DB_NAME < $TEMP_DIR/*/database.sql

# 恢复应用文件
echo "恢复应用文件..."
cp -r $TEMP_DIR/*/php-frontend/* $APP_DIR/php-frontend/
cp -r $TEMP_DIR/*/backend/* $APP_DIR/backend/
cp $TEMP_DIR/*/.env $APP_DIR/
cp $TEMP_DIR/*/docker-compose.yml $APP_DIR/

# 恢复配置文件
echo "恢复配置文件..."
cp $TEMP_DIR/*/nginx.conf /etc/nginx/sites-available/ipv6-wireguard-manager
cp $TEMP_DIR/*/php-fpm.conf /etc/php/8.1/fpm/pool.d/www.conf

# 重启服务
echo "重启服务..."
systemctl start php8.1-fpm
systemctl start nginx
systemctl start ipv6-wireguard-manager

# 清理临时目录
rm -rf $TEMP_DIR

echo "恢复完成"
```

## 集群配置

### 集群架构

```
┌─────────────────────────────────────────────────────────────┐
│                    IPv6 WireGuard Manager 集群              │
├─────────────────────────────────────────────────────────────┤
│  Load Balancer (Nginx)                                      │
│  - 负载均衡                                                  │
│  - SSL终止                                                  │
│  - 健康检查                                                  │
├─────────────────────────────────────────────────────────────┤
│  Node 1          │  Node 2          │  Node 3              │
│  - Frontend      │  - Frontend      │  - Frontend          │
│  - Backend       │  - Backend       │  - Backend           │
│  - Cache         │  - Cache         │  - Cache             │
├─────────────────────────────────────────────────────────────┤
│  Database Cluster (MySQL)                                   │
│  - 主从复制                                                  │
│  - 自动故障转移                                              │
│  - 数据同步                                                  │
├─────────────────────────────────────────────────────────────┤
│  Shared Storage (NFS/GlusterFS)                             │
│  - 配置文件                                                  │
│  - 日志文件                                                  │
│  - 备份文件                                                  │
└─────────────────────────────────────────────────────────────┘
```

### 负载均衡配置

```nginx
# /etc/nginx/nginx.conf
upstream ipv6wgm_backend {
    least_conn;
    server 192.168.1.10:8000 max_fails=3 fail_timeout=30s;
    server 192.168.1.11:8000 max_fails=3 fail_timeout=30s;
    server 192.168.1.12:8000 max_fails=3 fail_timeout=30s;
}

upstream ipv6wgm_frontend {
    least_conn;
    server 192.168.1.10:80 max_fails=3 fail_timeout=30s;
    server 192.168.1.11:80 max_fails=3 fail_timeout=30s;
    server 192.168.1.12:80 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com;
    
    location /api/ {
        proxy_pass http://ipv6wgm_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location / {
        proxy_pass http://ipv6wgm_frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 集群管理脚本

```bash
#!/bin/bash
# /opt/ipv6-wireguard-manager/scripts/cluster_manager.sh

# 配置
NODES=("192.168.1.10" "192.168.1.11" "192.168.1.12")
APP_DIR="/opt/ipv6-wireguard-manager"
SERVICE_NAME="ipv6-wireguard-manager"

case $1 in
    "start")
        echo "启动集群..."
        for node in "${NODES[@]}"; do
            echo "启动节点: $node"
            ssh $node "systemctl start $SERVICE_NAME"
        done
        ;;
    "stop")
        echo "停止集群..."
        for node in "${NODES[@]}"; do
            echo "停止节点: $node"
            ssh $node "systemctl stop $SERVICE_NAME"
        done
        ;;
    "restart")
        echo "重启集群..."
        for node in "${NODES[@]}"; do
            echo "重启节点: $node"
            ssh $node "systemctl restart $SERVICE_NAME"
        done
        ;;
    "status")
        echo "集群状态:"
        for node in "${NODES[@]}"; do
            echo "节点: $node"
            ssh $node "systemctl status $SERVICE_NAME --no-pager"
        done
        ;;
    "deploy")
        echo "部署到集群..."
        for node in "${NODES[@]}"; do
            echo "部署到节点: $node"
            rsync -avz --delete $APP_DIR/ $node:$APP_DIR/
            ssh $node "systemctl restart $SERVICE_NAME"
        done
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|deploy}"
        exit 1
        ;;
esac
```

## 性能优化

### 系统优化

#### 内核参数优化

```bash
# /etc/sysctl.conf
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr

# 文件描述符限制
fs.file-max = 2097152
fs.nr_open = 2097152

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# 应用优化
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 10
```

#### 系统限制优化

```bash
# /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
www-data soft nofile 65536
www-data hard nofile 65536
```

### 应用优化

#### Python优化

```python
# backend/app/core/performance.py
import asyncio
import uvloop
from concurrent.futures import ThreadPoolExecutor

# 使用uvloop提升性能
asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

# 线程池配置
THREAD_POOL = ThreadPoolExecutor(max_workers=4)

# 连接池配置
DATABASE_POOL_SIZE = 20
DATABASE_MAX_OVERFLOW = 30
DATABASE_POOL_TIMEOUT = 30
DATABASE_POOL_RECYCLE = 3600

# 缓存配置
CACHE_TTL = 300
CACHE_MAX_SIZE = 1000
```

#### PHP优化

```ini
# /etc/php/8.1/fpm/pool.d/www.conf
[www]
user = www-data
group = www-data
listen = /var/run/php/php8.1-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 1000

; 性能优化
pm.process_idle_timeout = 10s
request_terminate_timeout = 30s
request_slowlog_timeout = 5s
slowlog = /var/log/php8.1-fpm-slow.log

; 内存优化
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 30
php_admin_value[upload_max_filesize] = 10M
php_admin_value[post_max_size] = 10M
```

## 故障排除

### 常见问题

#### 1. 服务启动失败

```bash
# 检查服务状态
systemctl status ipv6-wireguard-manager

# 查看日志
journalctl -u ipv6-wireguard-manager -f

# 检查端口占用
netstat -tlnp | grep :8000
lsof -i :8000

# 检查配置文件
python -m py_compile backend/app/main.py
```

#### 2. 数据库连接失败

```bash
# 检查MySQL服务
systemctl status mysql

# 测试数据库连接
mysql -u ipv6wgm -p -h localhost ipv6wgm

# 检查数据库配置
cat .env | grep DATABASE

# 查看数据库日志
tail -f /var/log/mysql/error.log
```

#### 3. 前端页面无法访问

```bash
# 检查Nginx状态
systemctl status nginx

# 测试Nginx配置
nginx -t

# 检查PHP-FPM状态
systemctl status php8.1-fpm

# 查看Nginx日志
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

#### 4. WireGuard连接问题

```bash
# 检查WireGuard状态
wg show

# 检查防火墙
ufw status
iptables -L

# 检查端口监听
netstat -ulnp | grep 51820

# 查看WireGuard日志
journalctl -u wg-quick@wg0 -f
```

### 日志分析

#### 日志文件位置

```bash
# 应用日志
/var/log/ipv6-wireguard-manager/
├── app.log
├── error.log
├── access.log
└── audit.log

# 系统日志
/var/log/
├── nginx/
│   ├── access.log
│   └── error.log
├── mysql/
│   └── error.log
├── php8.1-fpm.log
└── syslog
```

#### 日志分析脚本

```bash
#!/bin/bash
# /opt/ipv6-wireguard-manager/scripts/log_analyzer.sh

LOG_DIR="/var/log/ipv6-wireguard-manager"
DATE=$(date +%Y-%m-%d)

echo "=== 日志分析报告 - $DATE ==="

# 错误统计
echo "错误统计:"
grep -c "ERROR" $LOG_DIR/app.log

# 访问统计
echo "访问统计:"
awk '{print $1}' $LOG_DIR/access.log | sort | uniq -c | sort -nr | head -10

# 响应时间统计
echo "响应时间统计:"
awk '{print $NF}' $LOG_DIR/access.log | sort -n | tail -10

# 数据库查询统计
echo "数据库查询统计:"
grep "database" $LOG_DIR/app.log | wc -l
```

### 性能监控

#### 性能监控脚本

```bash
#!/bin/bash
# /opt/ipv6-wireguard-manager/scripts/performance_monitor.sh

# 系统资源监控
echo "=== 系统资源监控 ==="
echo "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)"
echo "内存使用率: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "磁盘使用率: $(df -h / | awk 'NR==2{print $5}')"

# 网络连接监控
echo "=== 网络连接监控 ==="
echo "TCP连接数: $(netstat -an | grep tcp | wc -l)"
echo "ESTABLISHED连接数: $(netstat -an | grep ESTABLISHED | wc -l)"

# 应用监控
echo "=== 应用监控 ==="
echo "Python进程数: $(ps aux | grep python | wc -l)"
echo "PHP-FPM进程数: $(ps aux | grep php-fpm | wc -l)"
echo "Nginx进程数: $(ps aux | grep nginx | wc -l)"

# 数据库监控
echo "=== 数据库监控 ==="
echo "MySQL连接数: $(mysql -u ipv6wgm -p'password' -e "SHOW STATUS LIKE 'Threads_connected';" | awk 'NR==2{print $2}')"
echo "MySQL查询数: $(mysql -u ipv6wgm -p'password' -e "SHOW STATUS LIKE 'Queries';" | awk 'NR==2{print $2}')"
```

---

**IPv6 WireGuard Manager 部署配置指南** - 完整的企业级部署解决方案 🚀

通过本指南，您可以成功部署和配置IPv6 WireGuard Manager，构建稳定、安全、高性能的网络管理平台！
