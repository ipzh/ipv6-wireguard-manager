# IPv6 WireGuard Manager 部署指南

## 📋 部署概述

本指南介绍IPv6 WireGuard Manager的多种部署方式，包括Docker部署、系统服务部署、微服务架构部署等。

## 🚀 快速部署

### Docker Compose部署（推荐）

#### 1. 基础部署
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 启动服务
docker-compose up -d

# 查看服务状态
docker-compose ps
```

#### 2. 生产环境部署
```bash
# 使用生产环境配置
docker-compose -f docker-compose.production.yml up -d

# 查看日志
docker-compose -f docker-compose.production.yml logs -f
```

#### 3. 微服务架构部署
```bash
# 使用微服务配置
docker-compose -f docker-compose.microservices.yml up -d

# 查看服务状态
docker-compose -f docker-compose.microservices.yml ps
```

### 系统服务部署

#### 1. 使用安装脚本
```bash
# 运行完整安装（原生部署）
./install.sh --type native

# 按需跳过步骤示例
./install.sh --type native --skip-db --skip-service --skip-frontend
```

#### 2. 手动部署
```bash
# 安装依赖
sudo apt-get update
sudo apt-get install python3-pip python3-venv mysql-server redis-server nginx

# 配置数据库
sudo mysql -e "CREATE DATABASE ipv6wgm;"
sudo mysql -e "CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"

# 启动服务
sudo systemctl start mysql redis nginx
sudo systemctl enable mysql redis nginx
```

## 🏗️ 架构部署

### 单机部署
适用于开发环境和小规模部署。

**特点:**
- 所有服务运行在同一台服务器
- 配置简单，维护方便
- 适合开发和测试环境

**部署步骤:**
1. 安装基础环境
2. 配置数据库
3. 部署应用服务
4. 配置反向代理

### 集群部署
适用于生产环境和大规模部署。

**特点:**
- 多台服务器组成集群
- 支持负载均衡和高可用
- 适合生产环境

**部署步骤:**
1. 配置负载均衡器
2. 部署多个应用实例
3. 配置数据库主从复制
4. 配置监控和日志

### 微服务部署
适用于大型企业和云环境。

**特点:**
- 服务拆分，独立部署
- 支持水平扩展
- 适合云原生环境

**部署步骤:**
1. 部署API网关
2. 部署各个微服务
3. 配置服务发现
4. 配置监控和治理

## 🔧 配置管理

### 环境变量配置
```bash
# 应用配置
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=3.1.0
DEBUG=false
ENVIRONMENT=production

# 数据库配置
DATABASE_URL=mysql://ipv6wgm:password@mysql:3306/ipv6wgm

# 安全配置
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

### 配置文件管理
```bash
# 主配置文件
backend/app/core/unified_config.py

# 环境配置文件
.env

# Docker配置文件
docker-compose.yml
docker-compose.production.yml
docker-compose.microservices.yml
```

## 📊 监控部署

### Prometheus监控
```bash
# 启动Prometheus
docker-compose up -d prometheus

# 访问监控界面
http://localhost:9090
```

### Grafana仪表板
```bash
# 启动Grafana
docker-compose up -d grafana

# 访问仪表板
http://localhost:3000
# 用户名: admin
# 密码: admin
```

### 日志收集
```bash
# 启动ELK Stack
docker-compose up -d elasticsearch kibana

# 访问日志分析
http://localhost:5601
```

## 🔒 安全配置

### HttpOnly Cookie配置

系统默认使用HttpOnly Cookie存储JWT令牌，提供更高的安全性。

#### 开发环境配置
- Cookie的`secure`标志自动适配：HTTP环境下为`false`，HTTPS环境下为`true`
- 前端需要配置`withCredentials: true`（axios）或`credentials: 'include'`（fetch）

#### 生产环境配置
**必须使用HTTPS** - Cookie的`Secure`标志需要HTTPS

```bash
# 1. 配置HTTPS（必须）
# 使用Let's Encrypt或商业证书

# 2. 更新环境变量
export APP_ENV=production
export DEBUG=false

# 3. Cookie将自动使用Secure标志
```

#### Cookie安全属性
- ✅ `HttpOnly=True` - 防止JavaScript访问（XSS防护）
- ✅ `Secure=True` - 仅HTTPS传输（生产环境）
- ✅ `SameSite=Lax` - CSRF保护
- ✅ 自动环境适配

### SSL/TLS配置
```bash
# 生成SSL证书
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# 配置Nginx SSL
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # 安全头配置
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # ... 其他配置
}
```

### 令牌黑名单配置

#### 内存存储（默认，开发环境）
```bash
# 无需配置，默认使用内存存储
# 适合单实例部署
```

#### 数据库存储（生产环境推荐）
```bash
# 设置环境变量
export USE_DATABASE_BLACKLIST=true

# 系统将自动使用数据库存储令牌黑名单
# 支持分布式部署和多实例
```

#### Redis存储（生产环境最佳）
```bash
# 设置Redis URL
export REDIS_URL=redis://localhost:6379/0
export USE_REDIS=true

# 令牌黑名单将存储在Redis中
# 支持分布式和高并发场景
```

### 防暴力破解配置

系统已内置防暴力破解机制：
- **登录尝试限制**: 5分钟内最多5次尝试
- **锁定时间**: 5分钟
- **基于**: 用户名 + IP地址

**当前使用内存存储**（开发环境）：
```python
# backend/app/api/api_v1/endpoints/auth.py
_MAX_LOGIN_ATTEMPTS = 5
_LOGIN_WINDOW_SECONDS = 300  # 5分钟
```

**生产环境建议使用Redis**：
- 支持分布式部署
- 支持多实例共享状态

### 防火墙配置
```bash
# 开放必要端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 51820/udp

# 启用防火墙
sudo ufw enable
```

### 安全扫描
```bash
# 运行安全扫描
python scripts/security/security_scan.py

# 生成安全报告
python scripts/security/security_scan.py --output security_report.html --format html
```

### 密码哈希配置

系统使用**bcrypt**进行密码哈希（推荐方案）：
- ✅ 自适应成本因子
- ✅ 自动加盐
- ✅ 抗暴力破解

**配置**:
- bcrypt不可用时自动回退到pbkdf2_sha256
- 密码长度限制：72字节（bcrypt限制）

### 令牌配置

**访问令牌**:
```bash
# 默认过期时间：8天
ACCESS_TOKEN_EXPIRE_MINUTES=11520  # 可配置，范围：1分钟-1年
```

**刷新令牌**:
```bash
# 默认过期时间：30天
REFRESH_TOKEN_EXPIRE_DAYS=30  # 可配置，范围：1天-1年
```

**环境变量配置**:
```bash
# .env 文件
ACCESS_TOKEN_EXPIRE_MINUTES=11520
REFRESH_TOKEN_EXPIRE_DAYS=30
```

## 📈 性能优化

### 数据库优化
```bash
# 配置MySQL
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2

# 创建索引
python scripts/optimize_database.py
```

### 缓存优化
```bash
# 配置Redis
maxmemory 512mb
maxmemory-policy allkeys-lru

# 启用缓存
USE_REDIS=true
REDIS_URL=redis://localhost:6379/0
```

### 负载均衡
```bash
# 配置HAProxy
backend backend_servers
    balance roundrobin
    server backend1 backend-1:8000 check
    server backend2 backend-2:8000 check
```

## 🔄 备份恢复

### 数据备份
```bash
# 创建备份
python scripts/backup/backup_manager.py --backup

# 定时备份
crontab -e
# 每天凌晨2点备份
0 2 * * * /path/to/backup_manager.py --backup
```

### 灾难恢复
```bash
# 评估系统状态
python scripts/disaster_recovery/disaster_recovery.py --assess

# 执行灾难恢复
python scripts/disaster_recovery/disaster_recovery.py --recover full
```

## 🧪 测试部署

### 功能测试
```bash
# 运行单元测试
python scripts/run_tests.py --unit

# 运行集成测试
python scripts/run_tests.py --integration

# 运行性能测试
python scripts/run_tests.py --performance
```

### 负载测试
```bash
# 使用Apache Bench测试
ab -n 1000 -c 10 http://localhost/api/v1/health

# 使用wrk测试
wrk -t12 -c400 -d30s http://localhost/api/v1/health
```

## 📚 故障排除

### 常见问题
1. **服务启动失败**
   - 检查端口占用
   - 检查配置文件
   - 查看错误日志

2. **数据库连接失败**
   - 检查数据库服务
   - 验证连接参数
   - 检查网络连通性

3. **API访问失败**
   - 检查防火墙设置
   - 验证API端点
   - 查看错误日志

### 日志查看
```bash
# 查看应用日志
tail -f logs/app.log

# 查看系统日志
journalctl -u ipv6-wireguard-manager -f

# 查看Docker日志
docker-compose logs -f backend
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

**部署指南版本**: 3.1.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队
