# IPv6 WireGuard Manager - 生产部署指南

## 📋 目录

- [概述](#概述)
- [系统要求](#系统要求)
- [快速部署](#快速部署)
- [详细部署步骤](#详细部署步骤)
- [配置说明](#配置说明)
- [服务管理](#服务管理)
- [监控和维护](#监控和维护)
- [故障排除](#故障排除)
- [安全加固](#安全加固)

## 概述

IPv6 WireGuard Manager 是一个企业级的VPN管理平台，支持IPv4/IPv6双栈网络、WireGuard VPN管理、BGP路由管理等功能。本指南提供完整的生产环境部署方案。

### 架构特点

- **前后端分离**: PHP前端 + Python后端
- **数据库**: MySQL 8.0+
- **缓存**: Redis (可选)
- **Web服务器**: Nginx
- **容器化**: 支持Docker部署
- **高可用**: 支持集群部署

## 系统要求

### 最低配置

| 组件 | 最低要求 | 推荐配置 |
|------|----------|----------|
| **CPU** | 2核心 | 4核心+ |
| **内存** | 2GB | 8GB+ |
| **存储** | 20GB SSD | 100GB+ SSD |
| **网络** | 100Mbps | 1Gbps+ |
| **操作系统** | Ubuntu 20.04+ | Ubuntu 22.04 LTS |

### 软件依赖

```bash
# 必需软件
- Python 3.11+
- MySQL 8.0+
- Nginx 1.18+
- PHP 8.1+
- PHP-FPM
- Redis (可选)
- WireGuard
```

## 快速部署

### 一键安装

```bash
# 基础安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 生产环境安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --production

# 指定安装目录
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --dir /opt/ipv6-wireguard

# 静默安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent
```

### Docker部署

```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 配置环境变量
cp backend/env.example .env
nano .env

# 启动服务
docker-compose -f docker-compose.production.yml up -d

# 查看状态
docker-compose ps
docker-compose logs -f
```

## 详细部署步骤

### 1. 系统准备

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础软件
sudo apt install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    mysql-server \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-curl \
    php8.1-json \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-zip \
    redis-server \
    git \
    curl \
    wget \
    unzip \
    supervisor \
    ufw \
    fail2ban
```

### 2. 数据库配置

```bash
# 启动MySQL服务
sudo systemctl start mysql
sudo systemctl enable mysql

# 安全配置
sudo mysql_secure_installation

# 创建数据库和用户
sudo mysql -u root -p
```

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
EXIT;
```

### 3. 应用部署

```bash
# 克隆代码
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 创建虚拟环境
python3.11 -m venv venv
source venv/bin/activate

# 安装Python依赖
pip install -r backend/requirements.txt

# 配置环境变量
cp backend/env.example .env
nano .env
```

### 4. 前端部署

```bash
# 复制PHP前端文件
sudo cp -r php-frontend/* /var/www/html/

# 设置权限
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# 配置PHP-FPM
sudo systemctl start php8.1-fpm
sudo systemctl enable php8.1-fpm
```

### 5. Nginx配置

```bash
# 创建Nginx配置
sudo cp php-frontend/nginx.conf /etc/nginx/sites-available/ipv6-wireguard-manager
sudo ln -s /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 禁用默认站点
sudo rm -f /etc/nginx/sites-enabled/default

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### 6. 后端服务配置

```bash
# 初始化数据库
python backend/scripts/init_database.py

# 创建systemd服务
sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null <<EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/opt/ipv6-wireguard-manager
Environment=PATH=/opt/ipv6-wireguard-manager/venv/bin
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/uvicorn backend.app.main:app --host :: --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl daemon-reload
sudo systemctl start ipv6-wireguard-manager
sudo systemctl enable ipv6-wireguard-manager
```

## 配置说明

### 环境变量配置

```bash
# .env 文件配置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.0.0"
DEBUG=false
APP_ENV=production

# 数据库配置
DATABASE_URL="mysql+pymysql://ipv6wgm:password@localhost:3306/ipv6wgm"
DB_HOST="localhost"
DB_PORT=3306
DB_NAME="ipv6wgm"
DB_USER="ipv6wgm"
DB_PASS="your-secure-password"

# Redis配置
REDIS_URL="redis://localhost:6379/0"

# 安全配置
SECRET_KEY="your-secret-key-here"
JWT_SECRET_KEY="your-jwt-secret-key-here"

# 邮件配置
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USERNAME="your-email@gmail.com"
SMTP_PASSWORD="your-app-password"
```

### PHP前端配置

```php
// php-frontend/config/config.php
define('APP_NAME', getenv('APP_NAME') ?: 'IPv6 WireGuard Manager');
define('APP_VERSION', getenv('APP_VERSION') ?: '3.0.0');
define('APP_DEBUG', filter_var(getenv('APP_DEBUG') ?: false, FILTER_VALIDATE_BOOLEAN));
define('API_BASE_URL', getenv('API_BASE_URL') ?: 'http://localhost:8000/api/v1');
```

### 数据库配置

```php
// php-frontend/config/database.php
define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_PORT', getenv('DB_PORT') ?: 3306);
define('DB_NAME', getenv('DB_NAME') ?: 'ipv6wgm');
define('DB_USER', getenv('DB_USER') ?: 'ipv6wgm');
define('DB_PASS', getenv('DB_PASS') ?: 'your-secure-password');
```

## 服务管理

### 服务状态检查

```bash
# 检查所有服务状态
sudo systemctl status nginx
sudo systemctl status php8.1-fpm
sudo systemctl status mysql
sudo systemctl status redis-server
sudo systemctl status ipv6-wireguard-manager

# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f
sudo journalctl -u nginx -f
sudo journalctl -u php8.1-fpm -f
```

### 服务重启

```bash
# 重启所有服务
sudo systemctl restart nginx
sudo systemctl restart php8.1-fpm
sudo systemctl restart mysql
sudo systemctl restart ipv6-wireguard-manager

# 重启特定服务
sudo systemctl restart ipv6-wireguard-manager
```

### 服务停止/启动

```bash
# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 禁用服务
sudo systemctl disable ipv6-wireguard-manager

# 启用服务
sudo systemctl enable ipv6-wireguard-manager
```

## 监控和维护

### 健康检查

```bash
# 检查应用健康状态
curl -f http://localhost:8000/api/v1/health

# 检查前端访问
curl -f http://localhost/

# 检查数据库连接
mysql -u ipv6wgm -p -e "SELECT 1"

# 检查Redis连接
redis-cli ping
```

### 日志监控

```bash
# 应用日志
tail -f /var/log/ipv6-wireguard-manager/app.log

# Nginx日志
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# 系统日志
journalctl -u ipv6-wireguard-manager -f
```

### 性能监控

```bash
# 系统资源监控
htop
iotop
nethogs

# 数据库性能
mysql -u root -p -e "SHOW PROCESSLIST;"
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"

# 网络连接
netstat -tulpn | grep :8000
netstat -tulpn | grep :80
```

## 故障排除

### 常见问题

#### 1. PHP-FPM服务启动失败

```bash
# 检查PHP-FPM配置
sudo php-fpm8.1 -t

# 检查服务状态
sudo systemctl status php8.1-fpm

# 重启服务
sudo systemctl restart php8.1-fpm

# 查看错误日志
sudo journalctl -u php8.1-fpm -f
```

#### 2. 数据库连接失败

```bash
# 检查MySQL服务
sudo systemctl status mysql

# 测试数据库连接
mysql -u ipv6wgm -p -h localhost ipv6wgm

# 检查数据库配置
cat .env | grep DATABASE

# 查看MySQL日志
sudo tail -f /var/log/mysql/error.log
```

#### 3. 前端页面无法访问

```bash
# 检查Nginx状态
sudo systemctl status nginx

# 测试Nginx配置
sudo nginx -t

# 检查PHP-FPM状态
sudo systemctl status php8.1-fpm

# 查看Nginx日志
sudo tail -f /var/log/nginx/error.log
```

#### 4. 后端API无法访问

```bash
# 检查后端服务状态
sudo systemctl status ipv6-wireguard-manager

# 检查端口监听
netstat -tlnp | grep :8000

# 查看后端日志
sudo journalctl -u ipv6-wireguard-manager -f

# 测试API连接
curl -f http://localhost:8000/api/v1/health
```

### 日志分析

```bash
# 错误日志分析
grep -i error /var/log/ipv6-wireguard-manager/app.log | tail -20

# 访问日志分析
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10

# 性能分析
grep "slow" /var/log/mysql/slow.log | tail -10
```

## 安全加固

### 防火墙配置

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

# 允许管理端口（仅内网）
sudo ufw allow from 192.168.1.0/24 to any port 8000

# 查看状态
sudo ufw status verbose
```

### SSL/TLS配置

```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加以下行
0 12 * * * /usr/bin/certbot renew --quiet
```

### 系统安全

```bash
# 禁用root登录
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 更改SSH端口
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# 重启SSH服务
sudo systemctl restart sshd

# 设置文件权限
sudo chmod 600 /etc/ssl/private/*
sudo chmod 644 /etc/ssl/certs/*
sudo chown -R www-data:www-data /var/www/html/
```

### 应用安全

```bash
# 设置强密码
# 修改 .env 文件中的密码
SECRET_KEY="$(openssl rand -hex 32)"
JWT_SECRET_KEY="$(openssl rand -hex 32)"
DB_PASS="$(openssl rand -base64 32)"

# 启用审计日志
ENABLE_AUDIT_LOGGING=true

# 启用速率限制
ENABLE_RATE_LIMITING=true
RATE_LIMIT_PER_MINUTE=1000

# 启用双因子认证
ENABLE_2FA=true
```

## 备份和恢复

### 自动备份

```bash
# 创建备份脚本
sudo tee /opt/ipv6-wireguard-manager/scripts/backup.sh > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/backups"
APP_DIR="/opt/ipv6-wireguard-manager"
DB_NAME="ipv6wgm"
DB_USER="ipv6wgm"
DB_PASS="your-password"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
mysqldump -u$DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/database_$DATE.sql

# 备份应用文件
tar -czf $BACKUP_DIR/app_$DATE.tar.gz -C $APP_DIR .

# 清理旧备份（保留30天）
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "备份完成: $DATE"
EOF

# 设置执行权限
sudo chmod +x /opt/ipv6-wireguard-manager/scripts/backup.sh

# 设置定时任务
sudo crontab -e
# 添加以下行（每天凌晨2点备份）
0 2 * * * /opt/ipv6-wireguard-manager/scripts/backup.sh
```

### 手动备份

```bash
# 数据库备份
mysqldump -u ipv6wgm -p ipv6wgm > backup_$(date +%Y%m%d).sql

# 应用文件备份
tar -czf app_backup_$(date +%Y%m%d).tar.gz /opt/ipv6-wireguard-manager/

# 配置文件备份
tar -czf config_backup_$(date +%Y%m%d).tar.gz /etc/nginx/ /etc/php/ /etc/mysql/
```

### 恢复操作

```bash
# 恢复数据库
mysql -u ipv6wgm -p ipv6wgm < backup_20240101.sql

# 恢复应用文件
tar -xzf app_backup_20240101.tar.gz -C /

# 恢复配置文件
tar -xzf config_backup_20240101.tar.gz -C /
```

## 性能优化

### 系统优化

```bash
# 内核参数优化
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# 文件描述符限制
fs.file-max = 2097152

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

# 应用配置
sudo sysctl -p
```

### 应用优化

```bash
# MySQL优化
sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf > /dev/null <<EOF
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
query_cache_size = 32M
max_connections = 200
EOF

# PHP-FPM优化
sudo tee -a /etc/php/8.1/fpm/pool.d/www.conf > /dev/null <<EOF
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 1000
EOF

# 重启服务
sudo systemctl restart mysql
sudo systemctl restart php8.1-fpm
```

## 集群部署

### 负载均衡配置

```nginx
# /etc/nginx/nginx.conf
upstream ipv6wgm_backend {
    least_conn;
    server 192.168.1.10:8000 max_fails=3 fail_timeout=30s;
    server 192.168.1.11:8000 max_fails=3 fail_timeout=30s;
    server 192.168.1.12:8000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name your-domain.com;
    
    location /api/ {
        proxy_pass http://ipv6wgm_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 数据库集群

```bash
# 主从复制配置
# 主服务器
sudo mysql -u root -p
```

```sql
-- 主服务器配置
CHANGE MASTER TO
    MASTER_HOST='192.168.1.11',
    MASTER_USER='replication',
    MASTER_PASSWORD='replication_password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=154;

START SLAVE;
SHOW SLAVE STATUS\G;
```

---

**IPv6 WireGuard Manager 生产部署指南** - 完整的企业级部署解决方案 🚀

通过本指南，您可以成功部署IPv6 WireGuard Manager到生产环境，构建稳定、安全、高性能的VPN管理平台！