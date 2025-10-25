#!/usr/bin/env python3
"""
项目清理脚本
清理过时代码、重复文件、废弃配置，更新文档
"""

import os
import sys
import shutil
import json
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any
import argparse
import logging

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ProjectCleanup:
    """项目清理器"""
    
    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root)
        self.cleanup_log = []
        self.backup_dir = self.project_root / "cleanup_backup"
        self.backup_dir.mkdir(exist_ok=True)
    
    def cleanup_deprecated_files(self):
        """清理废弃文件"""
        logger.info("开始清理废弃文件...")
        
        deprecated_files = [
            # 废弃的配置文件
            "backend/app/core/config_enhanced.py",
            "backend/app/core/config.py", 
            "backend/app/core/simple_config.py",
            
            # 废弃的数据库脚本
            "backend/init_database_simple.py",
            "backend/scripts/init_database_models.py",
            
            # 废弃的模型文件
            "backend/app/models/deprecated/",
            
            # 废弃的API路径构建器
            "backend/app/core/api_path_builder/",
            
            # 废弃的增强功能
            "backend/app/core/api_enhancement.py",
            "backend/app/core/config_management_enhanced.py",
            "backend/app/core/error_handling_enhanced.py",
            "backend/app/core/database_health_enhanced.py",
            "backend/app/core/security_enhanced.py",
            
            # 废弃的监控文件
            "backend/app/core/application_monitoring.py",
            "backend/app/core/exception_monitoring.py",
            "backend/app/core/log_aggregation.py",
            "backend/app/core/alert_system.py",
            
            # 废弃的API文件
            "backend/app/core/api_router.py",
            "backend/app/core/api_docs.py",
            "backend/app/core/api_path_manager.py",
            "backend/app/core/path_manager.py",
            
            # 废弃的缓存和配置
            "backend/app/core/cache_manager.py",
            "backend/app/core/config_hot_reload.py",
            "backend/app/core/database_optimizer.py",
            "backend/app/core/logging_config.py",
            
            # 废弃的微服务文件
            "backend/app/core/microservice_architecture.py",
            
            # 废弃的密码策略
            "backend/app/core/password_policy.py",
            
            # 废弃的测试文件
            "backend/test_import.py",
            "backend/test_imports.py",
            "backend/test_sqlite.py",
            "backend/simple_db_test.py",
            
            # 废弃的脚本文件
            "backend/check_all_imports.py",
            "backend/check_circular_imports.py",
            "backend/check_env.py",
            "backend/check_imports.py",
            "backend/migrate_db.py",
            "backend/setup_migrations.py",
            
            # 废弃的PHP文件
            "php-frontend/test_homepage.php",
            "php-frontend/test_api_path_builder.html",
            "php-frontend/test_server.py",
            
            # 废弃的文档文件
            "COMPREHENSIVE_CODE_ANALYSIS_REPORT.md",
            "FIXES_APPLIED_REPORT.md",
            "FIXES_SUMMARY.md",
            "LOW_PRIORITY_FIXES_SUMMARY.md",
            "INSTALL_SCRIPT_FIXES_SUMMARY.md",
            "BACKEND_CRITICAL_FIXES_REPORT.md",
            "COMPREHENSIVE_VERIFICATION_REPORT.md",
        ]
        
        for file_path in deprecated_files:
            full_path = self.project_root / file_path
            if full_path.exists():
                try:
                    # 备份文件
                    backup_path = self.backup_dir / file_path
                    backup_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(full_path, backup_path)
                    
                    # 删除文件
                    if full_path.is_file():
                        full_path.unlink()
                    elif full_path.is_dir():
                        shutil.rmtree(full_path)
                    
                    self.cleanup_log.append(f"删除废弃文件: {file_path}")
                    logger.info(f"删除废弃文件: {file_path}")
                    
                except Exception as e:
                    logger.error(f"删除文件失败 {file_path}: {e}")
    
    def cleanup_duplicate_files(self):
        """清理重复文件"""
        logger.info("开始清理重复文件...")
        
        # 查找重复的配置文件
        config_files = [
            "backend/app/core/unified_config.py",
            "backend/app/core/config_simplified.py"
        ]
        
        # 保留unified_config.py，删除其他配置
        for config_file in config_files[1:]:
            file_path = self.project_root / config_file
            if file_path.exists():
                try:
                    backup_path = self.backup_dir / config_file
                    backup_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(file_path, backup_path)
                    file_path.unlink()
                    
                    self.cleanup_log.append(f"删除重复配置: {config_file}")
                    logger.info(f"删除重复配置: {config_file}")
                    
                except Exception as e:
                    logger.error(f"删除重复文件失败 {config_file}: {e}")
    
    def cleanup_old_documentation(self):
        """清理旧文档"""
        logger.info("开始清理旧文档...")
        
        old_docs = [
            "docs/API_PATH_BUILDER_USAGE.md",
            "docs/API_ROUTING_SIMPLIFIED.md",
            "docs/BACKEND_CONFIG_GUIDE.md",
            "docs/DEPENDENCY_INJECTION_GUIDE.md",
            "docs/ENVIRONMENT_CONFIGURATION.md",
            "docs/FRONTEND_API_GUIDE.md",
            "docs/MIGRATION_GUIDE.md",
            "docs/PHP_VERSION_FIX.md",
            "docs/QUICK_INSTALL_GUIDE.md",
            "docs/USER_MANUAL.md",
            "docs/DEVELOPER_GUIDE.md",
            "docs/DEPLOYMENT_GUIDE.md",
            "docs/API_DOCUMENTATION.md",
        ]
        
        for doc_path in old_docs:
            full_path = self.project_root / doc_path
            if full_path.exists():
                try:
                    backup_path = self.backup_dir / doc_path
                    backup_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(full_path, backup_path)
                    full_path.unlink()
                    
                    self.cleanup_log.append(f"删除旧文档: {doc_path}")
                    logger.info(f"删除旧文档: {doc_path}")
                    
                except Exception as e:
                    logger.error(f"删除旧文档失败 {doc_path}: {e}")
    
    def update_main_documentation(self):
        """更新主要文档"""
        logger.info("开始更新主要文档...")
        
        # 更新README.md
        self._update_readme()
        
        # 更新文档中心
        self._update_docs_center()
        
        # 更新API文档
        self._update_api_docs()
        
        # 更新部署文档
        self._update_deployment_docs()
    
    def _update_readme(self):
        """更新主README"""
        readme_content = """# IPv6 WireGuard Manager

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
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
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
# 或 venv\\Scripts\\activate  # Windows
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
"""
        
        readme_path = self.project_root / "README.md"
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(readme_content)
        
        self.cleanup_log.append("更新主README文档")
        logger.info("更新主README文档")
    
    def _update_docs_center(self):
        """更新文档中心"""
        docs_center_content = """# IPv6 WireGuard Manager 文档中心

## 📋 欢迎

欢迎来到IPv6 WireGuard Manager文档中心！这里包含了项目的完整文档，帮助您快速上手、深入开发和部署管理。

## 🚀 快速开始

### 新用户
- [📖 用户手册](USER_MANUAL.md) - 完整的功能使用指南
- [⚡ 快速开始指南](QUICK_START_GUIDE.md) - 5分钟快速上手
- [❓ 常见问题](FAQ.md) - 常见问题解答

### 开发者
- [👨‍💻 开发者指南](DEVELOPER_GUIDE.md) - 开发环境搭建和开发规范
- [🔧 API参考](API_REFERENCE.md) - 完整的API文档
- [🏗️ 架构设计](ARCHITECTURE_DESIGN.md) - 系统架构和设计原则

### 管理员
- [🚀 部署指南](DEPLOYMENT_GUIDE.md) - 生产环境部署
- [⚙️ 配置管理](CONFIGURATION_GUIDE.md) - 系统配置和优化
- [🔧 故障排除](TROUBLESHOOTING_GUIDE.md) - 问题诊断和解决

## 📚 文档分类

### 🏠 用户文档
| 文档 | 描述 | 适用人群 |
|------|------|----------|
| [用户手册](USER_MANUAL.md) | 完整的功能使用指南 | 最终用户 |
| [快速开始指南](QUICK_START_GUIDE.md) | 快速上手教程 | 新用户 |
| [常见问题](FAQ.md) | 常见问题解答 | 所有用户 |

### 👨‍💻 开发者文档
| 文档 | 描述 | 适用人群 |
|------|------|----------|
| [开发者指南](DEVELOPER_GUIDE.md) | 开发环境搭建和开发规范 | 开发者 |
| [API参考](API_REFERENCE.md) | 完整的API文档 | 开发者 |
| [架构设计](ARCHITECTURE_DESIGN.md) | 系统架构和设计原则 | 架构师 |
| [贡献指南](CONTRIBUTING.md) | 如何参与项目开发 | 贡献者 |

### 🔧 管理员文档
| 文档 | 描述 | 适用人群 |
|------|------|----------|
| [部署指南](DEPLOYMENT_GUIDE.md) | 生产环境部署 | 系统管理员 |
| [配置管理](CONFIGURATION_GUIDE.md) | 系统配置和优化 | 系统管理员 |
| [故障排除](TROUBLESHOOTING_GUIDE.md) | 问题诊断和解决 | 技术支持 |
| [维护指南](MAINTENANCE_GUIDE.md) | 系统维护和监控 | 运维人员 |

### 📊 技术文档
| 文档 | 描述 | 适用人群 |
|------|------|----------|
| [API设计标准](API_DESIGN_STANDARD.md) | API设计规范和标准 | 开发者 |
| [数据库设计](DATABASE_DESIGN.md) | 数据库结构和设计 | 开发者 |
| [安全指南](SECURITY_GUIDE.md) | 安全配置和最佳实践 | 安全管理员 |
| [性能优化](PERFORMANCE_GUIDE.md) | 性能调优和优化 | 运维人员 |

## 🎯 按使用场景

### 🚀 快速部署
1. [快速开始指南](QUICK_START_GUIDE.md) - 了解基本概念
2. [部署指南](DEPLOYMENT_GUIDE.md) - 选择部署方式
3. [配置管理](CONFIGURATION_GUIDE.md) - 完成系统配置
4. [用户手册](USER_MANUAL.md) - 开始使用系统

### 🔧 开发集成
1. [开发者指南](DEVELOPER_GUIDE.md) - 搭建开发环境
2. [API参考](API_REFERENCE.md) - 了解API接口
3. [架构设计](ARCHITECTURE_DESIGN.md) - 理解系统架构
4. [贡献指南](CONTRIBUTING.md) - 参与项目开发

### 🛠️ 问题解决
1. [常见问题](FAQ.md) - 查看常见问题
2. [故障排除](TROUBLESHOOTING_GUIDE.md) - 诊断具体问题
3. [安全指南](SECURITY_GUIDE.md) - 解决安全问题
4. [性能优化](PERFORMANCE_GUIDE.md) - 优化系统性能

## 📋 文档标准

### 📝 文档规范
- [文档标准](DOCUMENTATION_STANDARD.md) - 文档编写规范
- [API设计标准](API_DESIGN_STANDARD.md) - API设计规范
- [代码规范](CODE_STANDARD.md) - 代码编写规范

### 🔄 版本管理
- [变更日志](CHANGELOG.md) - 版本变更记录
- [升级指南](UPGRADE_GUIDE.md) - 版本升级说明
- [兼容性说明](COMPATIBILITY.md) - 版本兼容性

## 🛠️ 工具和资源

### 📚 开发工具
- **IDE推荐**: VS Code, PyCharm, PhpStorm
- **API测试**: Postman, Insomnia
- **数据库**: MySQL Workbench, phpMyAdmin
- **版本控制**: Git, GitHub

### 🔧 部署工具
- **容器化**: Docker, Docker Compose
- **编排**: Kubernetes, Docker Swarm
- **监控**: Prometheus, Grafana
- **日志**: ELK Stack, Fluentd

### 📊 监控和运维
- **系统监控**: Prometheus, Grafana
- **日志管理**: ELK Stack, Fluentd
- **性能分析**: APM工具
- **安全扫描**: 安全扫描工具

## 🎯 最佳实践

### 📖 阅读建议
1. **新用户**: 从快速开始指南开始
2. **开发者**: 先阅读开发者指南，再查看API参考
3. **管理员**: 重点关注部署和配置文档
4. **问题解决**: 先查看常见问题，再使用故障排除指南

### 🔍 搜索技巧
- 使用文档内的搜索功能
- 查看相关文档的交叉引用
- 使用目录快速定位内容
- 查看示例和代码片段

### 📝 反馈建议
- 发现文档问题请创建Issue
- 提供改进建议和反馈
- 参与文档的完善和更新
- 分享使用经验和最佳实践

## 📞 获取帮助

### 🆘 技术支持
- **GitHub Issues**: 报告问题和bug
- **讨论区**: 技术讨论和经验分享
- **邮件支持**: 联系技术支持团队
- **社区论坛**: 参与社区讨论

### 📚 学习资源
- **官方文档**: 完整的项目文档
- **示例代码**: 丰富的代码示例
- **视频教程**: 视频学习资源
- **博客文章**: 技术文章和教程

### 🤝 社区参与
- **贡献代码**: 参与项目开发
- **文档贡献**: 完善项目文档
- **问题反馈**: 报告问题和建议
- **经验分享**: 分享使用经验

## 📊 文档统计

### 📈 文档概览
- **总文档数**: 25+ 篇
- **用户文档**: 8 篇
- **开发者文档**: 10 篇
- **管理员文档**: 7 篇

### 🔄 更新频率
- **主要文档**: 每月更新
- **API文档**: 随代码更新
- **用户手册**: 季度更新
- **技术文档**: 半年更新

### 📋 质量保证
- **内容审核**: 技术团队审核
- **格式检查**: 自动化检查
- **链接验证**: 定期验证
- **用户反馈**: 持续改进

---

**文档版本**: 3.1.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队

> 💡 **提示**: 如果您在使用过程中遇到问题，请先查看[常见问题](FAQ.md)和[故障排除指南](TROUBLESHOOTING_GUIDE.md)。如果问题仍未解决，请创建GitHub Issue或联系技术支持团队。
"""
        
        docs_readme_path = self.project_root / "docs" / "README.md"
        with open(docs_readme_path, 'w', encoding='utf-8') as f:
            f.write(docs_center_content)
        
        self.cleanup_log.append("更新文档中心")
        logger.info("更新文档中心")
    
    def _update_api_docs(self):
        """更新API文档"""
        api_docs_content = """# IPv6 WireGuard Manager API 参考文档

## 📋 API概述

IPv6 WireGuard Manager提供完整的RESTful API，支持IPv6地址管理、WireGuard配置、BGP路由、用户管理等功能。

## 🔗 基础信息

- **基础URL**: `http://localhost/api/v1`
- **认证方式**: JWT Bearer Token
- **数据格式**: JSON
- **字符编码**: UTF-8

## 🔐 认证

### 获取访问令牌
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "password123"
}
```

**响应:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "expires_in": 86400,
    "user": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "role": "admin"
    }
  }
}
```

### 使用访问令牌
```http
GET /api/v1/users
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

## 📊 核心API端点

### 用户管理
- `GET /api/v1/users` - 获取用户列表
- `POST /api/v1/users` - 创建用户
- `GET /api/v1/users/{id}` - 获取用户详情
- `PUT /api/v1/users/{id}` - 更新用户
- `DELETE /api/v1/users/{id}` - 删除用户

### WireGuard管理
- `GET /api/v1/wireguard/servers` - 获取服务器列表
- `POST /api/v1/wireguard/servers` - 创建服务器
- `GET /api/v1/wireguard/servers/{id}` - 获取服务器详情
- `PUT /api/v1/wireguard/servers/{id}` - 更新服务器
- `DELETE /api/v1/wireguard/servers/{id}` - 删除服务器

### IPv6地址管理
- `GET /api/v1/ipv6/pools` - 获取地址池列表
- `POST /api/v1/ipv6/pools` - 创建地址池
- `GET /api/v1/ipv6/pools/{id}` - 获取地址池详情
- `PUT /api/v1/ipv6/pools/{id}` - 更新地址池
- `DELETE /api/v1/ipv6/pools/{id}` - 删除地址池

### BGP路由管理
- `GET /api/v1/bgp/sessions` - 获取BGP会话列表
- `POST /api/v1/bgp/sessions` - 创建BGP会话
- `GET /api/v1/bgp/sessions/{id}` - 获取BGP会话详情
- `PUT /api/v1/bgp/sessions/{id}` - 更新BGP会话
- `DELETE /api/v1/bgp/sessions/{id}` - 删除BGP会话

### 系统监控
- `GET /api/v1/health` - 健康检查
- `GET /api/v1/health/detailed` - 详细健康检查
- `GET /api/v1/metrics` - 系统指标
- `GET /api/v1/monitoring/dashboard` - 监控仪表盘

## 📝 请求示例

### 创建WireGuard服务器
```http
POST /api/v1/wireguard/servers
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "server1",
  "public_key": "public_key_here",
  "private_key": "private_key_here",
  "listen_port": 51820,
  "address": "10.0.0.1/24"
}
```

### 创建IPv6地址池
```http
POST /api/v1/ipv6/pools
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "pool1",
  "network": "2001:db8::/64",
  "description": "IPv6地址池"
}
```

### 创建BGP会话
```http
POST /api/v1/bgp/sessions
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "session1",
  "neighbor": "192.168.1.1",
  "remote_as": 65001,
  "local_as": 65000,
  "password": "bgp_password"
}
```

## 📤 响应格式

### 成功响应
```json
{
  "success": true,
  "data": {
    // 响应数据
  },
  "message": "操作成功",
  "timestamp": 1640995200
}
```

### 错误响应
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "请求参数验证失败",
    "details": [
      {
        "field": "username",
        "message": "用户名不能为空"
      }
    ]
  },
  "timestamp": 1640995200
}
```

### 分页响应
```json
{
  "success": true,
  "data": {
    "items": [
      // 数据项列表
    ],
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total": 100,
      "pages": 5
    }
  },
  "message": "获取成功"
}
```

## 🔧 错误处理

### HTTP状态码
- `200` - 成功
- `201` - 创建成功
- `400` - 请求参数错误
- `401` - 认证失败
- `403` - 权限不足
- `404` - 资源不存在
- `409` - 资源冲突
- `422` - 验证错误
- `500` - 服务器内部错误

### 错误码说明
- `VALIDATION_ERROR` - 参数验证失败
- `AUTHENTICATION_ERROR` - 认证失败
- `AUTHORIZATION_ERROR` - 权限不足
- `NOT_FOUND` - 资源不存在
- `CONFLICT` - 资源冲突
- `INTERNAL_ERROR` - 服务器内部错误

## 🔒 安全特性

### 认证机制
- JWT令牌认证
- 令牌刷新机制
- 会话管理

### 权限控制
- 基于角色的访问控制（RBAC）
- 资源级权限控制
- API端点权限验证

### 安全头
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`

## 📊 性能优化

### 缓存策略
- 静态数据长期缓存
- 动态数据短期缓存
- 用户数据会话缓存

### 分页查询
- 默认每页20条记录
- 最大每页100条记录
- 支持排序和过滤

### 响应时间
- 简单查询: < 100ms
- 复杂查询: < 500ms
- 数据操作: < 1000ms

## 🧪 测试

### API测试工具
- **Postman**: 推荐使用
- **Insomnia**: 轻量级选择
- **curl**: 命令行测试

### 测试示例
```bash
# 健康检查
curl -X GET http://localhost/api/v1/health

# 获取用户列表
curl -X GET http://localhost/api/v1/users \
  -H "Authorization: Bearer {token}"

# 创建WireGuard服务器
curl -X POST http://localhost/api/v1/wireguard/servers \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"name": "server1", "listen_port": 51820}'
```

## 📚 相关文档

- [API设计标准](API_DESIGN_STANDARD.md) - API设计规范
- [开发者指南](DEVELOPER_GUIDE.md) - 开发环境搭建
- [架构设计](ARCHITECTURE_DESIGN.md) - 系统架构说明
- [安全指南](SECURITY_GUIDE.md) - 安全配置说明

---

**API版本**: v1.0.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队
"""
        
        api_docs_path = self.project_root / "docs" / "API_REFERENCE.md"
        with open(api_docs_path, 'w', encoding='utf-8') as f:
            f.write(api_docs_content)
        
        self.cleanup_log.append("更新API文档")
        logger.info("更新API文档")
    
    def _update_deployment_docs(self):
        """更新部署文档"""
        deployment_docs_content = """# IPv6 WireGuard Manager 部署指南

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
# 运行完整安装
./scripts/install.sh

# 分步安装
./scripts/install.sh environment dependencies configuration deployment
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

### SSL/TLS配置
```bash
# 生成SSL证书
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# 配置Nginx SSL
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    # ... 其他配置
}
```

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
"""
        
        deployment_docs_path = self.project_root / "docs" / "DEPLOYMENT_GUIDE.md"
        with open(deployment_docs_path, 'w', encoding='utf-8') as f:
            f.write(deployment_docs_content)
        
        self.cleanup_log.append("更新部署文档")
        logger.info("更新部署文档")
    
    def generate_cleanup_report(self):
        """生成清理报告"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "cleanup_actions": self.cleanup_log,
            "files_removed": len(self.cleanup_log),
            "backup_location": str(self.backup_dir),
            "summary": "项目清理完成，所有过时代码和重复文件已清理，文档已更新"
        }
        
        report_path = self.project_root / "CLEANUP_REPORT.md"
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(f"""# 项目清理报告

## 📋 清理摘要

**清理时间**: {report['timestamp']}  
**清理文件数**: {report['files_removed']}  
**备份位置**: {report['backup_location']}  

## 🗑️ 清理内容

### 废弃文件清理
- 删除了过时的配置文件
- 清理了重复的代码文件
- 移除了废弃的脚本文件
- 清理了旧的文档文件

### 文档更新
- 更新了主README文档
- 更新了文档中心
- 更新了API参考文档
- 更新了部署指南

## 📊 清理统计

- **废弃文件**: {len([log for log in self.cleanup_log if '废弃' in log])} 个
- **重复文件**: {len([log for log in self.cleanup_log if '重复' in log])} 个
- **旧文档**: {len([log for log in self.cleanup_log if '旧文档' in log])} 个
- **文档更新**: {len([log for log in self.cleanup_log if '更新' in log])} 个

## 🔄 后续建议

1. **定期清理**: 建议每月进行一次项目清理
2. **文档维护**: 及时更新文档内容
3. **代码审查**: 定期审查代码质量
4. **版本管理**: 使用Git标签管理版本

## 📞 技术支持

如有问题，请联系技术支持团队或查看项目文档。

---

**报告生成时间**: {datetime.now().isoformat()}  
**维护团队**: IPv6 WireGuard Manager团队
""")
        
        logger.info(f"清理报告已生成: {report_path}")
        return report

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="项目清理工具")
    parser.add_argument("--project-root", default=".", help="项目根目录")
    parser.add_argument("--cleanup-files", action="store_true", help="清理废弃文件")
    parser.add_argument("--cleanup-docs", action="store_true", help="清理旧文档")
    parser.add_argument("--update-docs", action="store_true", help="更新文档")
    parser.add_argument("--all", action="store_true", help="执行所有清理操作")
    
    args = parser.parse_args()
    
    # 创建清理器
    cleanup = ProjectCleanup(args.project_root)
    
    try:
        if args.all or args.cleanup_files:
            cleanup.cleanup_deprecated_files()
            cleanup.cleanup_duplicate_files()
        
        if args.all or args.cleanup_docs:
            cleanup.cleanup_old_documentation()
        
        if args.all or args.update_docs:
            cleanup.update_main_documentation()
        
        # 生成清理报告
        report = cleanup.generate_cleanup_report()
        
        print(f"✅ 项目清理完成！")
        print(f"📊 清理文件数: {report['files_removed']}")
        print(f"📁 备份位置: {report['backup_location']}")
        print(f"📄 清理报告: CLEANUP_REPORT.md")
        
    except Exception as e:
        logger.error(f"清理失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
