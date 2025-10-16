# IPv6 WireGuard Manager - 详细部署指南

## 📋 目录

- [概述](#概述)
- [系统要求](#系统要求)
- [安装方式](#安装方式)
- [配置说明](#配置说明)
- [服务管理](#服务管理)
- [监控配置](#监控配置)
- [备份配置](#备份配置)
- [集群部署](#集群部署)
- [故障排除](#故障排除)
- [性能优化](#性能优化)
- [安全加固](#安全加固)

## 概述

IPv6 WireGuard Manager 是一个企业级的VPN管理解决方案，支持IPv4/IPv6双栈网络、BGP路由管理、集群部署等高级功能。

### 主要特性

- ✅ **IPv4/IPv6双栈支持**: 完整的双栈网络管理
- ✅ **WireGuard VPN管理**: 服务器和客户端管理
- ✅ **BGP路由管理**: 动态路由宣告和管理
- ✅ **集群部署**: 高可用性和负载均衡
- ✅ **监控告警**: 实时监控和告警系统
- ✅ **备份恢复**: 自动化备份和恢复
- ✅ **Web管理界面**: 现代化的Web管理界面

## 系统要求

### 最低要求

| 组件 | 最低要求 | 推荐要求 |
|------|----------|----------|
| **CPU** | 2核心 | 4核心+ |
| **内存** | 2GB | 8GB+ |
| **存储** | 20GB | 100GB+ |
| **网络** | 100Mbps | 1Gbps+ |

### 操作系统支持

| 发行版 | 版本 | 支持状态 |
|--------|------|----------|
| **Ubuntu** | 20.04 LTS+ | ✅ 完全支持 |
| **Debian** | 11+ | ✅ 完全支持 |
| **CentOS** | 8+ | ✅ 完全支持 |
| **RHEL** | 8+ | ✅ 完全支持 |
| **Rocky Linux** | 8+ | ✅ 完全支持 |
| **AlmaLinux** | 8+ | ✅ 完全支持 |

### 软件依赖

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| **Python** | 3.8+ | 推荐3.11+ |
| **MySQL** | 8.0+ | 数据库 |
| **Redis** | 6.0+ | 缓存（可选） |
| **Nginx** | 1.18+ | Web服务器 |
| **WireGuard** | 1.0+ | VPN服务 |
| **ExaBGP** | 4.0+ | BGP服务（可选） |

## 安装方式

### 方式一：一键安装（推荐）

```bash
# 下载并执行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者指定安装参数
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --dir /opt/ipv6-wireguard --port 8080
```

### 方式二：Docker安装

```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 启动服务
docker-compose up -d

# 查看服务状态
docker-compose ps
```

### 方式三：手动安装

```bash
# 1. 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 2. 安装系统依赖
sudo apt update
sudo apt install -y python3 python3-pip python3-venv mysql-server redis-server nginx

# 3. 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 4. 安装Python依赖
pip install -r requirements.txt

# 5. 配置数据库
sudo mysql -e "CREATE DATABASE ipv6wgm;"
sudo mysql -e "CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'your_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"

# 6. 初始化数据库
python backend/scripts/init_database.py

# 7. 启动服务
python backend/scripts/start_server.py
```

## 配置说明

### 环境变量配置

创建 `.env` 文件：

```bash
# 应用配置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.0.0"
APP_DEBUG=false
APP_ENV=production

# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=ipv6wgm
DB_USER=ipv6wgm
DB_PASS=your_secure_password

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
REDIS_DB=0

# API配置
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4

# 安全配置
SECRET_KEY=your_secret_key_here
JWT_SECRET_KEY=your_jwt_secret_key
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=480

# 监控配置
MONITORING_ENABLED=true
MONITORING_INTERVAL=30
ALERT_EMAIL=admin@example.com

# 备份配置
BACKUP_ENABLED=true
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION_DAYS=30
BACKUP_PATH=/backups

# 集群配置
CLUSTER_ENABLED=false
CLUSTER_NODE_ID=node1
CLUSTER_DISCOVERY_URL=http://localhost:8000/api/v1/cluster
```

### 数据库配置

#### MySQL配置优化

编辑 `/etc/mysql/mysql.conf.d/mysqld.cnf`：

```ini
[mysqld]
# 基础配置
port = 3306
bind-address = 0.0.0.0
max_connections = 200
max_connect_errors = 1000

# 字符集配置
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 存储引擎配置
default-storage-engine = InnoDB
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2

# 查询缓存
query_cache_type = 1
query_cache_size = 64M
query_cache_limit = 2M

# 慢查询日志
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 二进制日志
log-bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
```

#### 数据库初始化

```bash
# 创建数据库和用户
sudo mysql -e "CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'your_secure_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# 初始化数据库表
python backend/scripts/init_database.py
```

### Nginx配置

#### 主配置文件

创建 `/etc/nginx/sites-available/ipv6-wireguard-manager`：

```nginx
# IPv4和IPv6双栈监听
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com;

    # 重定向到HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.com;

    # SSL配置
    ssl_certificate /etc/ssl/certs/your-domain.crt;
    ssl_certificate_key /etc/ssl/private/your-domain.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 客户端最大上传大小
    client_max_body_size 10M;

    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/php-frontend;
        index index.php index.html;
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP处理
    location ~ \.php$ {
        root /opt/ipv6-wireguard-manager/php-frontend;
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
        proxy_pass http://127.0.0.1:8000/api/v1/status/health;
        access_log off;
    }

    # 静态资源缓存
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        root /opt/ipv6-wireguard-manager/php-frontend;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

#### 启用站点

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重载配置
sudo systemctl reload nginx
```

### 系统服务配置

#### 后端服务

创建 `/etc/systemd/system/ipv6-wireguard-manager.service`：

```ini
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service redis.service
Wants=mysql.service redis.service

[Service]
Type=exec
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=/opt/ipv6-wireguard-manager
Environment=PATH=/opt/ipv6-wireguard-manager/venv/bin
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/python backend/scripts/start_server.py
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

# 安全配置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/ipv6-wireguard-manager
ReadWritePaths=/var/log/ipv6-wireguard-manager
ReadWritePaths=/tmp

[Install]
WantedBy=multi-user.target
```

#### 启动服务

```bash
# 重载systemd配置
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable ipv6-wireguard-manager

# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 查看状态
sudo systemctl status ipv6-wireguard-manager
```

## 服务管理

### 服务控制命令

```bash
# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 重启服务
sudo systemctl restart ipv6-wireguard-manager

# 重载配置
sudo systemctl reload ipv6-wireguard-manager

# 查看状态
sudo systemctl status ipv6-wireguard-manager

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f
```

### 日志管理

#### 日志配置

编辑 `backend/app/core/logging_config.py`：

```python
LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "default": {
            "format": "[%(asctime)s] %(levelname)s in %(module)s: %(message)s",
        },
        "detailed": {
            "format": "[%(asctime)s] %(levelname)s in %(module)s: %(message)s [%(pathname)s:%(lineno)d]",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": "INFO",
            "formatter": "default",
            "stream": "ext://sys.stdout",
        },
        "file": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "DEBUG",
            "formatter": "detailed",
            "filename": "/var/log/ipv6-wireguard-manager/app.log",
            "maxBytes": 10485760,  # 10MB
            "backupCount": 5,
        },
        "error_file": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "ERROR",
            "formatter": "detailed",
            "filename": "/var/log/ipv6-wireguard-manager/error.log",
            "maxBytes": 10485760,  # 10MB
            "backupCount": 5,
        },
    },
    "loggers": {
        "": {
            "level": "DEBUG",
            "handlers": ["console", "file", "error_file"],
        },
    },
}
```

#### 日志轮转

创建 `/etc/logrotate.d/ipv6-wireguard-manager`：

```
/var/log/ipv6-wireguard-manager/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 ipv6wgm ipv6wgm
    postrotate
        systemctl reload ipv6-wireguard-manager
    endscript
}
```

## 监控配置

### 系统监控

#### 监控指标配置

编辑 `backend/app/core/monitoring_config.py`：

```python
MONITORING_CONFIG = {
    "enabled": True,
    "interval": 30,  # 秒
    "metrics": {
        "system": {
            "cpu": True,
            "memory": True,
            "disk": True,
            "network": True,
            "load": True,
        },
        "application": {
            "database": True,
            "cache": True,
            "api": True,
            "wireguard": True,
            "bgp": True,
        },
    },
    "alerts": {
        "cpu_usage": {
            "threshold": 80.0,
            "level": "warning",
            "enabled": True,
        },
        "memory_usage": {
            "threshold": 85.0,
            "level": "warning",
            "enabled": True,
        },
        "disk_usage": {
            "threshold": 90.0,
            "level": "error",
            "enabled": True,
        },
    },
    "notifications": {
        "email": {
            "enabled": True,
            "smtp_host": "smtp.example.com",
            "smtp_port": 587,
            "smtp_user": "alerts@example.com",
            "smtp_password": "your_password",
            "recipients": ["admin@example.com"],
        },
        "webhook": {
            "enabled": False,
            "url": "https://hooks.slack.com/services/...",
        },
    },
}
```

### 告警配置

#### 告警规则示例

```python
ALERT_RULES = [
    {
        "id": "cpu_high",
        "name": "CPU使用率过高",
        "metric": "system.cpu.usage",
        "condition": ">",
        "threshold": 80.0,
        "level": "warning",
        "cooldown": 300,  # 5分钟
        "enabled": True,
    },
    {
        "id": "memory_high",
        "name": "内存使用率过高",
        "metric": "system.memory.usage",
        "condition": ">",
        "threshold": 85.0,
        "level": "error",
        "cooldown": 300,
        "enabled": True,
    },
    {
        "id": "disk_high",
        "name": "磁盘使用率过高",
        "metric": "system.disk.usage",
        "condition": ">",
        "threshold": 90.0,
        "level": "critical",
        "cooldown": 600,  # 10分钟
        "enabled": True,
    },
]
```

## 备份配置

### 备份策略

#### 备份配置

编辑 `backend/app/core/backup_config.py`：

```python
BACKUP_CONFIG = {
    "enabled": True,
    "schedules": [
        {
            "name": "daily_full",
            "type": "full",
            "schedule": "0 2 * * *",  # 每天凌晨2点
            "retention_days": 7,
            "enabled": True,
        },
        {
            "name": "weekly_full",
            "type": "full",
            "schedule": "0 3 * * 0",  # 每周日凌晨3点
            "retention_days": 30,
            "enabled": True,
        },
        {
            "name": "monthly_full",
            "type": "full",
            "schedule": "0 4 1 * *",  # 每月1日凌晨4点
            "retention_days": 365,
            "enabled": True,
        },
    ],
    "backup_path": "/backups",
    "compression": True,
    "encryption": False,
    "verification": True,
}
```

#### 备份脚本

创建 `scripts/backup.sh`：

```bash
#!/bin/bash

# 备份脚本
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${DATE}"

# 创建备份目录
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

# 数据库备份
mysqldump -u ipv6wgm -p ipv6wgm > "${BACKUP_DIR}/${BACKUP_NAME}/database.sql"

# 配置文件备份
cp -r /opt/ipv6-wireguard-manager/config "${BACKUP_DIR}/${BACKUP_NAME}/"

# 日志文件备份
cp -r /var/log/ipv6-wireguard-manager "${BACKUP_DIR}/${BACKUP_NAME}/"

# 压缩备份
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "${BACKUP_DIR}" "${BACKUP_NAME}"

# 删除临时目录
rm -rf "${BACKUP_DIR}/${BACKUP_NAME}"

# 清理旧备份
find "${BACKUP_DIR}" -name "backup_*.tar.gz" -mtime +30 -delete

echo "备份完成: ${BACKUP_NAME}.tar.gz"
```

## 集群部署

### 集群配置

#### 集群节点配置

编辑 `backend/app/core/cluster_config.py`：

```python
CLUSTER_CONFIG = {
    "enabled": True,
    "node_id": "node1",
    "discovery_url": "http://localhost:8000/api/v1/cluster",
    "heartbeat_interval": 30,
    "load_balancer": {
        "strategy": "round_robin",
        "node_weights": {},
    },
    "services": {
        "ipv6-wireguard-manager": {
            "nodes": ["node1", "node2", "node3"],
            "metadata": {},
        },
    },
}
```

#### 负载均衡配置

使用Nginx作为负载均衡器：

```nginx
upstream ipv6_wireguard_manager {
    least_conn;
    server 192.168.1.10:8000 weight=1 max_fails=3 fail_timeout=30s;
    server 192.168.1.11:8000 weight=1 max_fails=3 fail_timeout=30s;
    server 192.168.1.12:8000 weight=1 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com;

    location /api/ {
        proxy_pass http://ipv6_wireguard_manager;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 故障排除

### 常见问题

#### 1. 服务启动失败

**问题**: 服务无法启动

**排查步骤**:

```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看详细日志
sudo journalctl -u ipv6-wireguard-manager -f

# 检查配置文件
sudo nginx -t

# 检查端口占用
sudo netstat -tlnp | grep :8000
```

**解决方案**:

1. 检查配置文件语法
2. 检查端口是否被占用
3. 检查数据库连接
4. 检查权限设置

#### 2. 数据库连接失败

**问题**: 无法连接到数据库

**排查步骤**:

```bash
# 测试数据库连接
mysql -u ipv6wgm -p -h localhost ipv6wgm

# 检查MySQL服务状态
sudo systemctl status mysql

# 查看MySQL日志
sudo tail -f /var/log/mysql/error.log
```

**解决方案**:

1. 检查MySQL服务状态
2. 验证用户权限
3. 检查防火墙设置
4. 验证连接参数

#### 3. 前端页面无法访问

**问题**: 前端页面显示空白或错误

**排查步骤**:

```bash
# 检查Nginx状态
sudo systemctl status nginx

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/error.log

# 检查PHP-FPM状态
sudo systemctl status php8.1-fpm

# 测试PHP配置
php -m
```

**解决方案**:

1. 检查Nginx配置
2. 验证PHP-FPM状态
3. 检查文件权限
4. 验证PHP扩展

### 日志分析

#### 日志文件位置

```bash
# 应用日志
/var/log/ipv6-wireguard-manager/app.log

# 错误日志
/var/log/ipv6-wireguard-manager/error.log

# Nginx日志
/var/log/nginx/access.log
/var/log/nginx/error.log

# MySQL日志
/var/log/mysql/error.log
/var/log/mysql/slow.log

# 系统日志
/var/log/syslog
```

#### 日志分析命令

```bash
# 查看最近的错误
sudo tail -f /var/log/ipv6-wireguard-manager/error.log

# 搜索特定错误
sudo grep -i "error" /var/log/ipv6-wireguard-manager/app.log

# 统计错误数量
sudo grep -c "ERROR" /var/log/ipv6-wireguard-manager/app.log

# 查看访问统计
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
```

## 性能优化

### 系统优化

#### 内核参数优化

编辑 `/etc/sysctl.conf`：

```bash
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
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
```

#### 应用优化

```python
# 数据库连接池优化
DATABASE_CONFIG = {
    "pool_size": 20,
    "max_overflow": 30,
    "pool_timeout": 30,
    "pool_recycle": 3600,
    "pool_pre_ping": True,
}

# 缓存优化
CACHE_CONFIG = {
    "redis": {
        "max_connections": 20,
        "socket_timeout": 5,
        "socket_connect_timeout": 5,
        "retry_on_timeout": True,
    },
    "local": {
        "max_size": 1000,
        "ttl": 300,
    },
}
```

### 数据库优化

#### MySQL优化

```ini
[mysqld]
# 连接优化
max_connections = 500
max_connect_errors = 1000
connect_timeout = 10
wait_timeout = 28800
interactive_timeout = 28800

# 缓存优化
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
innodb_log_buffer_size = 64M
innodb_flush_log_at_trx_commit = 2

# 查询优化
query_cache_type = 1
query_cache_size = 128M
query_cache_limit = 4M
tmp_table_size = 64M
max_heap_table_size = 64M

# 索引优化
key_buffer_size = 256M
sort_buffer_size = 2M
read_buffer_size = 2M
read_rnd_buffer_size = 8M
```

## 安全加固

### 系统安全

#### 防火墙配置

```bash
# 安装UFW
sudo apt install ufw

# 默认策略
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 允许SSH
sudo ufw allow ssh

# 允许HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许WireGuard
sudo ufw allow 51820/udp

# 启用防火墙
sudo ufw enable
```

#### SSL证书配置

```bash
# 使用Let's Encrypt
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 应用安全

#### 安全配置

```python
SECURITY_CONFIG = {
    "password_policy": {
        "min_length": 12,
        "require_uppercase": True,
        "require_lowercase": True,
        "require_digits": True,
        "require_special": True,
        "max_age_days": 90,
    },
    "rate_limiting": {
        "enabled": True,
        "requests_per_minute": 100,
        "burst_limit": 200,
    },
    "session_security": {
        "timeout_minutes": 30,
        "secure_cookies": True,
        "httponly_cookies": True,
        "samesite": "strict",
    },
    "api_security": {
        "cors_origins": ["https://your-domain.com"],
        "trusted_hosts": ["your-domain.com"],
        "csrf_protection": True,
    },
}
```

#### 输入验证

```python
# 严格的输入验证
VALIDATION_RULES = {
    "username": {
        "type": "string",
        "min_length": 3,
        "max_length": 50,
        "pattern": r"^[a-zA-Z0-9_-]+$",
    },
    "email": {
        "type": "email",
        "max_length": 255,
    },
    "password": {
        "type": "string",
        "min_length": 12,
        "pattern": r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$",
    },
}
```

---

**IPv6 WireGuard Manager** - 企业级部署指南 🚀

通过本指南，您可以成功部署和管理IPv6 WireGuard Manager，享受完整的VPN管理解决方案！
