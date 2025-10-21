# IPv6 WireGuard Manager

## 📋 项目概述

IPv6 WireGuard Manager是一个功能完整、架构先进的企业级VPN管理系统，支持IPv6地址管理、WireGuard配置、BGP路由、用户管理等功能。

## 🚀 快速开始

### 环境要求
- Python 3.8+
- PHP 8.1+
- MySQL 8.0+
- Redis 6.0+
- Docker & Docker Compose

### 安装部署

#### 1. 克隆项目
```bash
git clone https://github.com/your-repo/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
```

#### 2. 快速部署（推荐）
```bash
# 使用Docker Compose一键部署
docker-compose up -d

# 或使用生产环境配置
docker-compose -f docker-compose.production.yml up -d
```

#### 3. 手动部署
```bash
# 运行模块化安装脚本
./scripts/install.sh

# 或分步安装
./scripts/install.sh environment dependencies configuration deployment
```

### 访问系统
- Web界面: http://localhost
- API接口: http://localhost/api/v1
- 监控面板: http://localhost:3000 (Grafana)
- 指标收集: http://localhost:9090 (Prometheus)

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
- **问题反馈**: [GitHub Issues](https://github.com/your-repo/ipv6-wireguard-manager/issues)
- **讨论**: [GitHub Discussions](https://github.com/your-repo/ipv6-wireguard-manager/discussions)

---

**版本**: 3.1.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队
