# IPv6 WireGuard Manager - 自动生成模式安装指南

## 🚀 一键安装（推荐）

### 快速安装
```bash
# 方式一：直接运行（推荐）
curl -fsSL https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/install.sh | bash

# 方式二：下载后运行
wget https://raw.githubusercontent.com/your-repo/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
./install.sh
```

### 安装选项
```bash
# 智能安装（自动选择最佳配置）
./install.sh

# Docker 安装（推荐）
./install.sh --type docker

# 原生安装
./install.sh --type native

# 最小化安装
./install.sh --type minimal

# 静默安装（无交互）
./install.sh --silent

# 生产环境安装
./install.sh --production
```

## 🔧 手动安装

### 1. 克隆项目
```bash
git clone https://github.com/your-repo/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
```

### 2. 自动生成模式启动
```bash
# 直接启动（系统自动生成强密码和长密钥）
docker-compose up -d

# 查看自动生成的凭据
docker-compose logs backend | grep "自动生成的"
```

### 3. 手动配置模式
```bash
# 复制环境模板
cp env.template .env

# 编辑配置文件（可选）
nano .env

# 启动服务
docker-compose up -d
```

## 🔑 自动生成特性

### 自动生成的凭据
- **SECRET_KEY**: 64字符强密钥（包含字母、数字、特殊字符）
- **FIRST_SUPERUSER_PASSWORD**: 16字符强密码
- **MYSQL_ROOT_PASSWORD**: 20字符数据库密码

### 获取凭据的方法
```bash
# 方法一：查看安装日志
docker-compose logs backend | grep "自动生成的"

# 方法二：查看完整后端日志
docker-compose logs backend

# 方法三：实时监控日志
docker-compose logs -f backend
```

## 📋 安装后配置

### 1. 访问系统
- **前端界面**: http://localhost
- **后端 API**: http://localhost:8000
- **API 文档**: http://localhost:8000/docs

### 2. 登录系统
- **用户名**: `admin`
- **密码**: 查看自动生成的密码

### 3. 首次配置
1. 登录后立即修改管理员密码
2. 配置 WireGuard 服务器
3. 设置网络参数
4. 创建客户端配置

## 🛠️ 服务管理

### Docker 服务管理
```bash
# 查看服务状态
docker-compose ps

# 启动服务
docker-compose start

# 停止服务
docker-compose stop

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f

# 更新服务
docker-compose pull
docker-compose up -d --build
```

### 数据库管理
```bash
# 连接数据库
docker-compose exec mysql mysql -u root -p

# 备份数据
docker-compose exec mysql mysqldump -u root -p ipv6wgm > backup.sql

# 恢复数据
docker-compose exec -T mysql mysql -u root -p ipv6wgm < backup.sql
```

## 🔒 安全配置

### 1. 修改默认凭据
```bash
# 编辑环境文件
nano .env

# 设置自定义密钥和密码
SECRET_KEY=your_custom_secret_key
FIRST_SUPERUSER_PASSWORD=your_custom_password

# 重启服务
docker-compose restart
```

### 2. SSL 证书配置
```bash
# 生成自签名证书（开发环境）
openssl req -x509 -newkey rsa:4096 -keyout nginx/ssl/key.pem -out nginx/ssl/cert.pem -days 365 -nodes

# 生产环境请使用有效的 SSL 证书
```

### 3. 防火墙配置
```bash
# 开放必要端口
ufw allow 80
ufw allow 443
ufw allow 51820/udp  # WireGuard 端口
```

## 🔧 故障排除

### 1. 服务启动失败
```bash
# 查看详细错误
docker-compose logs [service_name]

# 检查端口占用
netstat -tlnp | grep :80
netstat -tlnp | grep :8000

# 重启服务
docker-compose restart
```

### 2. 数据库连接问题
```bash
# 检查数据库状态
docker-compose exec mysql mysqladmin ping -h localhost -u root -p

# 重置数据库
docker-compose down -v
docker-compose up -d
```

### 3. 前端无法访问
```bash
# 检查前端容器
docker-compose logs frontend

# 检查 Nginx 配置
docker-compose exec frontend nginx -t
```

## 📊 监控和维护

### 1. 系统监控
```bash
# 查看资源使用
docker stats

# 查看磁盘使用
df -h

# 查看内存使用
free -h
```

### 2. 日志管理
```bash
# 查看应用日志
docker-compose logs -f backend

# 查看访问日志
docker-compose logs -f frontend

# 清理旧日志
docker system prune -f
```

### 3. 备份策略
```bash
# 创建备份脚本
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec mysql mysqldump -u root -p ipv6wgm > backup_${DATE}.sql
tar -czf config_backup_${DATE}.tar.gz .env docker-compose.yml
EOF

chmod +x backup.sh
```

## 🎯 高级配置

### 1. 性能优化
```bash
# 调整 Docker 资源限制
# 编辑 docker-compose.yml 中的 deploy.resources 部分
```

### 2. 集群部署
```bash
# 使用 Docker Swarm
docker swarm init
docker stack deploy -c docker-compose.yml ipv6wgm
```

### 3. 监控集成
```bash
# 集成 Prometheus 监控
# 配置 Grafana 仪表板
# 设置告警规则
```

## 📞 技术支持

### 常见问题
1. **端口冲突**: 修改 `.env` 文件中的端口配置
2. **内存不足**: 增加系统内存或调整 Docker 资源限制
3. **网络问题**: 检查防火墙和网络配置
4. **权限问题**: 确保 Docker 用户有足够权限

### 获取帮助
- 查看项目文档
- 提交 Issue
- 加入社区讨论
- 联系技术支持

## 🎉 完成安装

安装完成后，您将拥有：
- ✅ 完整的 IPv6 WireGuard 管理系统
- ✅ 自动生成的安全凭据
- ✅ 现代化的 Web 界面
- ✅ RESTful API 接口
- ✅ 实时监控和日志
- ✅ 高可用性架构

开始使用您的 IPv6 WireGuard Manager 吧！
