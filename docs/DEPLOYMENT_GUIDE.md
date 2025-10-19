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
curl -fsSL https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/install.sh | bash
```

#### 1.2 自定义安装

```bash
# 使用自定义参数安装
curl -fsSL https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/install.sh | bash -s -- \
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
git clone https://github.com/your-repo/ipv6-wireguard-manager.git
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
git clone https://github.com/your-repo/ipv6-wireguard-manager.git
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
