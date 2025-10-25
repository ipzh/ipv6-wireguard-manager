# IPv6 WireGuard Manager

## 📋 项目概述

IPv6 WireGuard Manager是一个功能完整、架构先进的企业级VPN管理系统，支持IPv6地址管理、WireGuard配置、BGP路由、用户管理等功能。

## 🚀 快速开始

### 环境要求

#### 基础要求
- **Python**: 3.9+ (推荐3.11)
- **PHP**: 8.1+ (带fpm扩展)
- **数据库**: MySQL 8.0+ 或 PostgreSQL 13+
- **缓存**: Redis 6.0+
- **Web服务器**: Nginx
- **容器**: Docker & Docker Compose

#### 系统要求
- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora 30+, Arch Linux, openSUSE 15+, macOS 10.15+
- **架构**: x86_64, ARM64, ARM32
- **CPU**: 1核心以上（推荐2核心以上）
- **内存**: 1GB以上（推荐4GB以上）
- **存储**: 5GB以上可用空间（推荐20GB以上）
- **网络**: 支持IPv6的网络环境（可选）

### 安装方式

#### 方式一：一键安装（推荐）
```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者下载后运行
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
./install.sh
```

#### 方式二：Docker部署
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 直接启动（自动生成模式）
docker-compose up -d

# 或使用生产环境配置
docker-compose -f docker-compose.production.yml up -d

# 查看自动生成的凭据
docker-compose logs backend | grep "自动生成的"
```

#### 方式三：原生安装
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 使用主安装脚本进行原生安装
./install.sh --type native

# 或使用智能模式
./install.sh --auto --type native
```

#### 方式四：手动配置
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 复制环境配置
cp env.template .env
# 编辑 .env 文件，设置您的密钥和密码

# 使用主安装脚本
./install.sh --type native

# 或分步安装（使用跳过选项）
./install.sh --type native --skip-deps --skip-db --skip-service --skip-frontend
```

### 安装选项

#### 安装类型选项
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

### 服务管理

#### 检查服务状态
```bash
# Docker环境
docker-compose ps

# 原生环境
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status redis
```

#### 查看日志
```bash
# Docker环境
docker-compose logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mysql

# 原生环境
sudo journalctl -u ipv6-wireguard-manager -f
sudo tail -f /var/log/nginx/error.log
```

#### 重启服务
```bash
# Docker环境
docker-compose restart

# 原生环境
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl restart nginx
```

### 访问系统

#### 主要访问地址
- **Web界面**: http://localhost
- **API接口**: http://localhost/api/v1
- **API文档**: http://localhost/docs
- **健康检查**: http://localhost/health

#### 监控面板
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **指标收集**: http://localhost/metrics

#### 默认凭据

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

### 故障排除

#### 常见问题

**1. 端口冲突**
```bash
# 检查端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :3306

# 修改端口配置
vim .env
# 修改 SERVER_PORT=8080
```

**2. 数据库连接失败**
```bash
# 检查数据库服务
docker-compose logs mysql
sudo systemctl status mysql

# 重置数据库
docker-compose down -v
docker-compose up -d
```

**3. 权限问题**
```bash
# 修复文件权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

**4. 网络问题**
```bash
# 检查防火墙
sudo ufw status
sudo firewall-cmd --list-all

# 检查IPv6支持
ip -6 addr show
```

#### 日志查看
```bash
# 应用日志
tail -f logs/app.log
tail -f logs/error.log

# 系统日志
journalctl -u ipv6-wireguard-manager -f
journalctl -u nginx -f

# Docker日志
docker-compose logs -f backend
docker-compose logs -f frontend
```

#### 性能优化
```bash
# 数据库优化
mysql -u root -p
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Threads_connected';

# 缓存优化
redis-cli info memory
redis-cli config get maxmemory

# 系统资源
htop
df -h
free -h
```

## 🏗️ 系统架构

### 技术栈
- **后端**: FastAPI + SQLAlchemy + Pydantic
- **前端**: PHP + Nginx + JavaScript
- **数据库**: MySQL 8.0 + Redis
- **监控**: Prometheus + Grafana
- **容器**: Docker + Docker Compose
- **负载均衡**: HAProxy
- **任务调度**: Celery + RabbitMQ

### 核心功能
- ✅ IPv6地址池管理
- ✅ WireGuard服务器管理
- ✅ 客户端配置管理
- ✅ BGP路由管理
- ✅ 用户权限管理
- ✅ 系统监控告警
- ✅ 数据备份恢复
- ✅ 安全审计日志

## 📚 文档中心

### 用户文档
- [用户手册](docs/USER_MANUAL.md) - 完整功能使用指南
- [快速开始](docs/QUICK_START_GUIDE.md) - 5分钟快速上手
- [常见问题](docs/FAQ.md) - 问题解答

### 开发者文档
- [开发者指南](docs/DEVELOPER_GUIDE.md) - 开发环境搭建
- [API参考](docs/API_REFERENCE.md) - 完整API文档
- [架构设计](docs/ARCHITECTURE_DESIGN.md) - 系统架构说明

### 管理员文档
- [部署指南](docs/DEPLOYMENT_GUIDE.md) - 生产环境部署
- [配置管理](docs/CONFIGURATION_GUIDE.md) - 系统配置说明
- [故障排除](docs/TROUBLESHOOTING_GUIDE.md) - 问题诊断解决

## 🔧 开发指南

### 环境搭建
```bash
# 后端开发环境
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或 venv\Scripts\activate  # Windows
pip install -r requirements.txt

# 前端开发环境
cd php-frontend
# 配置PHP环境，无需Node.js构建
```

### 运行测试
```bash
# 运行所有测试
python scripts/run_tests.py --all

# 运行特定测试
python scripts/run_tests.py --unit
python scripts/run_tests.py --integration
python scripts/run_tests.py --performance
```

### 代码检查
```bash
# 运行代码检查
python scripts/run_tests.py --lint

# 运行安全扫描
python scripts/security/security_scan.py

# 检查文档一致性
python scripts/docs/check_consistency.py
```

## 🚀 部署指南

### Docker部署
```bash
# 开发环境
docker-compose up -d

# 生产环境
docker-compose -f docker-compose.production.yml up -d

# 微服务架构
docker-compose -f docker-compose.microservices.yml up -d
```

### 系统服务部署
```bash
# 使用安装脚本
./scripts/install.sh

# 手动部署
sudo systemctl start ipv6-wireguard-manager
sudo systemctl enable ipv6-wireguard-manager
```

## 📊 监控运维

### 系统监控
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **健康检查**: http://localhost/health
- **指标端点**: http://localhost/metrics

### 日志管理
- **应用日志**: `logs/app.log`
- **错误日志**: `logs/error.log`
- **系统日志**: `journalctl -u ipv6-wireguard-manager`

### 备份恢复
```bash
# 创建备份
python scripts/backup/backup_manager.py --backup

# 恢复备份
python scripts/backup/backup_manager.py --restore backup_file.sql

# 灾难恢复
python scripts/disaster_recovery/disaster_recovery.py --recover full
```

## 🔒 安全特性

### 安全扫描
```bash
# 运行安全扫描
python scripts/security/security_scan.py

# 生成安全报告
python scripts/security/security_scan.py --output security_report.html --format html
```

### 安全配置
- JWT令牌认证
- 密码强度验证
- 账户锁定机制
- 速率限制
- 安全头配置
- 审计日志记录

## 🤝 贡献指南

### 参与开发
1. Fork项目
2. 创建功能分支
3. 提交代码
4. 创建Pull Request

### 代码规范
- 遵循PEP 8规范
- 使用类型注解
- 编写单元测试
- 更新文档

### 问题反馈
- 创建Issue报告问题
- 提供详细错误信息
- 包含复现步骤

## 📄 许可证

本项目采用MIT许可证，详见[LICENSE](LICENSE)文件。

## 📞 支持

- **文档**: [docs/](docs/)
- **问题反馈**: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **讨论**: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

---

**版本**: 3.1.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队