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
# 指定安装类型
./install.sh --type docker          # Docker安装
./install.sh --type native           # 原生安装
./install.sh --type minimal          # 最小化安装

# 智能安装模式
./install.sh --auto                  # 自动选择参数并退出
./install.sh --silent                # 静默安装（非交互）

# 跳过特定步骤
./install.sh --skip-deps             # 跳过依赖安装
./install.sh --skip-db               # 跳过数据库配置
./install.sh --skip-service          # 跳过服务创建
./install.sh --skip-frontend         # 跳过前端部署

# 生产环境配置
./install.sh --production            # 生产环境安装
./install.sh --performance           # 性能优化安装
./install.sh --debug                 # 调试模式

# 自定义配置
./install.sh --dir /opt/custom       # 自定义安装目录
./install.sh --port 8080             # 自定义Web端口
./install.sh --api-port 9000         # 自定义API端口
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

- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora 30+, Arch Linux, openSUSE 15+
- **架构**: x86_64, ARM64, ARM32
- **CPU**: 1核心以上（推荐2核心以上）
- **内存**: 1GB以上（推荐4GB以上）
- **存储**: 5GB以上可用空间（推荐20GB以上）
- **网络**: 支持IPv6的网络环境（可选）

### 快速原生安装
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 使用主安装脚本进行原生安装
./install.sh --type native

# 或使用智能模式
./install.sh --auto --type native
```

### 分步安装（使用跳过选项）
```bash
# 1. 仅安装依赖
./install.sh --type native --skip-db --skip-service --skip-frontend

# 2. 仅配置数据库
./install.sh --type native --skip-deps --skip-service --skip-frontend

# 3. 仅部署前端
./install.sh --type native --skip-deps --skip-db --skip-service

# 4. 仅创建服务
./install.sh --type native --skip-deps --skip-db --skip-frontend

# 5. 完整安装
./install.sh --type native
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
FIRST_SUPERUSER_PASSWORD="<REPLACE_WITH_STRONG_PASSWORD>"
```

> 提示：使用安装脚本时会自动生成 `.env` 文件以及 `setup_credentials.txt`，文件中包含超级用户和数据库密码，请妥善保管并在首次登录后立即修改。

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

## 🔒 安全配置（重要）

### 安装后必须配置

#### 1. 环境变量配置
```bash
# 编辑环境变量文件
vim /opt/ipv6-wireguard-manager/.env

# 生产环境必须设置
DEBUG=false
APP_ENV=production
```

#### 2. HTTPS配置（生产环境必须）
- 生产环境必须使用HTTPS
- HttpOnly Cookie的`Secure`标志需要HTTPS
- 参考 [部署指南](DEPLOYMENT_GUIDE.md#httponly-cookie配置) 配置SSL证书

#### 3. 令牌黑名单配置（生产环境推荐）
```bash
# 使用数据库存储（推荐）
export USE_DATABASE_BLACKLIST=true

# 或使用Redis存储（最佳）
export REDIS_URL=redis://localhost:6379/0
export USE_REDIS=true
```

**详细安全配置请参考**:
- [部署指南 - 安全配置](DEPLOYMENT_GUIDE.md#-安全配置)
- [安全特性文档](SECURITY_FEATURES.md)

## 🌐 访问系统

### 主要访问地址
- **Web界面**: http://localhost
- **API接口**: http://localhost/api/v1
- **API文档**: http://localhost/docs
- **健康检查**: http://localhost/health 或 http://localhost/api/v1/health

### 监控面板
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **指标收集**: http://localhost/metrics

### 默认凭据

**自动生成模式（推荐）：**
- **用户名**: admin
- **密码**: 查看启动日志获取
  ```bash
  # Docker环境
  docker-compose logs backend | grep "自动生成的超级用户密码"
  
  # 原生环境
  sudo journalctl -u ipv6-wireguard-manager | grep "自动生成的超级用户密码"
  ```

**手动配置模式：**
- **用户名**: admin
- **密码**: .env 文件中设置的 FIRST_SUPERUSER_PASSWORD

**注意**: 脚本会自动生成强密码，不会使用默认的弱密码。请查看安装日志获取实际密码。

## 🔧 故障排除

### 常见问题

#### 1. 端口冲突
**问题**: 端口被其他服务占用

**解决方案**:
```bash
# 检查端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :3306
netstat -tulpn | grep :8000

# 修改端口配置
vim .env
# 修改 SERVER_PORT=8080, API_PORT=9000
```

#### 2. 数据库连接失败
**问题**: 无法连接到数据库

**解决方案**:
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
**问题**: 文件权限不正确

**解决方案**:
```bash
# 修复文件权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 修复WireGuard权限
sudo chown -R root:root /etc/wireguard
sudo chmod 600 /etc/wireguard/*.key
```

#### 4. 网络问题
**问题**: 网络连接或IPv6支持问题

**解决方案**:
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
**问题**: 服务无法正常启动

**解决方案**:
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

#### 6. 安装脚本问题
**问题**: 安装脚本执行失败

**解决方案**:
```bash
# 查看安装日志
tail -f /tmp/install_errors.log

# 检查脚本权限
chmod +x install.sh

# 重新运行安装
./install.sh --type native --skip-deps

# 检查系统兼容性
./install.sh --help
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
