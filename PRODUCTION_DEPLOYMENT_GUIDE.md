# IPv6 WireGuard Manager - 生产环境部署指南

## 📋 概述

本文档提供IPv6 WireGuard Manager在生产环境中的完整部署指南，包括系统要求、部署步骤、配置说明、监控配置和安全加固等内容。

## 🎯 部署架构

### 生产环境架构图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   负载均衡器    │    │   Web服务器    │    │   数据库集群    │
│   (Nginx)      │◄──►│   (FastAPI)    │◄──►│   (MySQL)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端应用      │    │   缓存服务      │    │   监控系统      │
│   (PHP+Nginx)   │    │   (Redis)       │    │   (Prometheus)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 快速部署

### 一键部署脚本

```bash
# 下载部署脚本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/deploy-production.sh

# 执行部署
chmod +x deploy-production.sh
./deploy-production.sh
```

### Docker Compose部署

```bash
# 克隆仓库
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 生产环境部署
docker-compose -f docker-compose.production.yml up -d
```

## 📋 系统要求

### 硬件要求

| 组件 | 最低配置 | 推荐配置 | 企业级配置 |
|------|----------|----------|------------|
| **CPU** | 2核心 | 4核心 | 8核心+ |
| **内存** | 4GB | 8GB | 16GB+ |
| **存储** | 50GB | 100GB | 500GB+ |
| **网络** | 100Mbps | 1Gbps | 10Gbps+ |

### 软件要求

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| **操作系统** | Ubuntu 20.04+ / CentOS 8+ | 推荐Ubuntu 22.04 LTS |
| **Docker** | 20.10+ | 容器运行时 |
| **Docker Compose** | 2.0+ | 容器编排 |
| **MySQL** | 8.0+ | 数据库 |
| **Redis** | 6.0+ | 缓存服务 |
| **Nginx** | 1.18+ | Web服务器 |

## 🔧 部署步骤

### 步骤1：环境准备

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Docker
curl -fsSL https://get.docker.com | sh

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 创建部署目录
sudo mkdir -p /opt/ipv6-wireguard
cd /opt/ipv6-wireguard
```

### 步骤2：配置文件准备

创建 `.env.production` 文件：

```bash
# 应用配置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.0.0"
APP_ENV=production
APP_DEBUG=false

# 数据库配置
DB_HOST=mysql
DB_PORT=3306
DB_NAME=ipv6wgm
DB_USER=ipv6wgm
DB_PASS=your_secure_password_here

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password_here
REDIS_DB=0

# API配置
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
API_V1_STR=/api/v1

# 安全配置
SECRET_KEY=your_secret_key_here
JWT_SECRET_KEY=your_jwt_secret_key_here
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=480

# 监控配置
MONITORING_ENABLED=true
MONITORING_INTERVAL=30
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000

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

### 步骤3：启动服务

```bash
# 拉取最新代码
git clone https://github.com/ipzh/ipv6-wireguard-manager.git .

# 启动生产环境服务
docker-compose -f docker-compose.production.yml up -d

# 查看服务状态
docker-compose -f docker-compose.production.yml ps
```

### 步骤4：初始化系统

```bash
# 等待服务启动
sleep 30

# 初始化数据库
docker-compose -f docker-compose.production.yml exec backend python -c "
from app.core.database import init_db
import asyncio
print('开始数据库初始化...')
result = asyncio.run(init_db())
print(f'数据库初始化完成: {result}')
"

# 创建管理员用户
docker-compose -f docker-compose.production.yml exec backend python -c "
from app.core.database import get_async_db
from app.models.user import User
import asyncio

async def create_admin():
    async for db in get_async_db():
        admin = User(
            username='admin',
            email='admin@example.com',
            is_superuser=True,
            is_active=True
        )
        admin.set_password('admin123')
        db.add(admin)
        await db.commit()
        print('管理员用户创建成功')

asyncio.run(create_admin())
"
```

## 🔒 安全配置

### SSL/TLS配置

```nginx
# Nginx SSL配置
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/ssl/certs/your-domain.com.crt;
    ssl_certificate_key /etc/ssl/private/your-domain.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        proxy_pass http://frontend:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /api/ {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 防火墙配置

```bash
# 配置UFW防火墙
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw status
```

## 📊 监控配置

### Prometheus配置

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'ipv6-wireguard'
    static_configs:
      - targets: ['backend:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Grafana仪表板

导入预配置的仪表板：

1. 访问 `http://your-server:3000`
2. 使用默认凭据登录 (admin/admin)
3. 导入仪表板ID: `1860` (系统监控)
4. 配置数据源指向Prometheus

## 🔄 备份策略

### 自动备份脚本

```bash
#!/bin/bash
# /opt/ipv6-wireguard/scripts/backup.sh

BACKUP_DIR="/backups/ipv6-wireguard"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 数据库备份
docker-compose -f docker-compose.production.yml exec mysql mysqldump -u ipv6wgm -p$DB_PASS ipv6wgm > $BACKUP_DIR/db_$DATE.sql

# 配置文件备份
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /opt/ipv6-wireguard/config/

# 清理旧备份（保留30天）
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "备份完成: $BACKUP_DIR"
```

### 定时备份配置

```bash
# 添加到crontab
crontab -e

# 每天凌晨2点执行备份
0 2 * * * /opt/ipv6-wireguard/scripts/backup.sh
```

## 🚨 故障排除

### 常见问题解决

#### 问题1：服务无法启动
```bash
# 检查服务状态
docker-compose -f docker-compose.production.yml ps

# 查看日志
docker-compose -f docker-compose.production.yml logs backend
docker-compose -f docker-compose.production.yml logs frontend
```

#### 问题2：数据库连接失败
```bash
# 检查数据库连接
docker-compose -f docker-compose.production.yml exec mysql mysql -u ipv6wgm -p

# 检查数据库状态
docker-compose -f docker-compose.production.yml exec mysql mysqladmin -u root -p status
```

#### 问题3：SSL证书问题
```bash
# 检查证书有效期
openssl x509 -in /etc/ssl/certs/your-domain.com.crt -noout -dates

# 重新生成证书（如果使用Let's Encrypt）
certbot renew --dry-run
```

## 📈 性能优化

### 数据库优化

```ini
# MySQL配置优化
[mysqld]
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
query_cache_size = 128M
max_connections = 200
```

### 应用优化

```python
# FastAPI配置优化
# backend/app/core/config.py
class Settings:
    # 连接池配置
    DATABASE_POOL_SIZE = 20
    DATABASE_MAX_OVERFLOW = 30
    
    # 缓存配置
    REDIS_POOL_SIZE = 10
    REDIS_MAX_CONNECTIONS = 50
    
    # 性能配置
    API_WORKERS = 4
    MAX_REQUEST_SIZE = 10 * 1024 * 1024  # 10MB
```

## 🔄 更新流程

### 版本更新

```bash
# 1. 备份当前版本
./scripts/backup.sh

# 2. 拉取最新代码
git pull origin main

# 3. 更新Docker镜像
docker-compose -f docker-compose.production.yml pull

# 4. 重启服务
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml up -d

# 5. 检查服务状态
docker-compose -f docker-compose.production.yml ps
```

### 数据库迁移

```bash
# 运行数据库迁移
docker-compose -f docker-compose.production.yml exec backend alembic upgrade head
```

## 📞 技术支持

### 获取帮助

- **文档**: [项目文档](https://github.com/ipzh/ipv6-wireguard-manager/docs)
- **问题**: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **讨论**: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

### 紧急联系方式

- **紧急支持**: support@ipv6-wireguard.com
- **安全漏洞**: security@ipv6-wireguard.com

---

## 📄 许可证

本项目采用 MIT 许可证。详细信息请查看 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎贡献代码！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

---

**IPv6 WireGuard Manager** - 企业级VPN管理解决方案 🚀

*最后更新: 2024年12月*