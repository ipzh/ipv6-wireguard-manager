# 部署模式矩阵表

## 概述

本文档描述了IPv6 WireGuard Manager项目支持的不同部署模式及其要求。

## 部署模式对比

| 模式 | 环境要求 | 可用脚本 | 支持功能 | 推荐场景 |
|------|----------|----------|----------|----------|
| **Docker Compose** | Docker, Docker Compose | `docker-compose up` | 完整功能 | 生产环境、开发环境 |
| **Docker Compose (低内存)** | Docker, Docker Compose | `docker-compose -f docker-compose.low-memory.yml up` | 基础功能 | 资源受限环境 |
| **原生安装** | Linux, systemd, MySQL | `./install.sh` | 完整功能 | 传统服务器 |
| **容器化部署** | Docker, Kubernetes | 自定义部署 | 完整功能 | 云原生环境 |

## 详细说明

### 1. Docker Compose 模式

**环境要求:**
- Docker 20.10+
- Docker Compose 2.0+
- 内存: 2GB+
- 磁盘: 10GB+

**可用脚本:**
- `docker-compose.yml` - 主配置文件
- `docker-compose up -d` - 启动服务
- `docker-compose down` - 停止服务

**支持功能:**
- ✅ 完整API服务
- ✅ PHP前端
- ✅ MySQL数据库
- ✅ Redis缓存
- ✅ Nginx反向代理
- ✅ 健康检查
- ✅ 日志管理

**配置文件:**
- `nginx/nginx.conf` - Nginx配置
- `redis/redis.conf` - Redis配置
- `env.template` - 环境变量模板

### 2. Docker Compose (低内存) 模式

**环境要求:**
- Docker 20.10+
- Docker Compose 2.0+
- 内存: 512MB+
- 磁盘: 5GB+

**可用脚本:**
- `docker-compose.low-memory.yml` - 低内存配置
- `docker-compose -f docker-compose.low-memory.yml up -d`

**支持功能:**
- ✅ 基础API服务
- ✅ PHP前端
- ✅ MySQL数据库
- ⚠️ 有限缓存功能
- ❌ 无Nginx反向代理
- ✅ 基础健康检查

### 3. 原生安装模式

**环境要求:**
- Linux (Ubuntu 20.04+, CentOS 8+, Debian 11+)
- systemd
- MySQL 8.0+
- Python 3.8+
- PHP 8.1+
- Nginx

**可用脚本:**
- `./install.sh` - 主安装脚本
- `./install.sh --help` - 查看选项
- `./install.sh --type=minimal` - 最小化安装

**支持功能:**
- ✅ 完整API服务
- ✅ PHP前端
- ✅ MySQL数据库
- ✅ Redis缓存
- ✅ Nginx配置
- ✅ systemd服务
- ✅ 健康检查
- ✅ 日志管理

**注意事项:**
- 需要root权限
- 依赖系统包管理器
- 需要手动配置防火墙

### 4. 容器化部署模式

**环境要求:**
- Kubernetes 1.20+
- 或 Docker Swarm
- 或云平台 (AWS ECS, Azure Container Instances)

**可用脚本:**
- 自定义Kubernetes manifests
- Helm charts (计划中)
- Terraform配置 (计划中)

**支持功能:**
- ✅ 完整API服务
- ✅ 水平扩展
- ✅ 自动恢复
- ✅ 负载均衡
- ✅ 服务发现

## 功能支持矩阵

| 功能 | Docker Compose | 低内存模式 | 原生安装 | 容器化部署 |
|------|----------------|------------|----------|------------|
| API服务 | ✅ | ✅ | ✅ | ✅ |
| 前端界面 | ✅ | ✅ | ✅ | ✅ |
| 数据库 | ✅ | ✅ | ✅ | ✅ |
| 缓存 | ✅ | ⚠️ | ✅ | ✅ |
| 反向代理 | ✅ | ❌ | ✅ | ✅ |
| 健康检查 | ✅ | ✅ | ✅ | ✅ |
| 日志管理 | ✅ | ✅ | ✅ | ✅ |
| 监控 | ✅ | ⚠️ | ✅ | ✅ |
| 备份 | ✅ | ⚠️ | ✅ | ✅ |
| 更新 | ✅ | ✅ | ✅ | ✅ |

## 选择建议

### 开发环境
- **推荐**: Docker Compose
- **原因**: 快速启动，完整功能，易于调试

### 测试环境
- **推荐**: Docker Compose (低内存)
- **原因**: 资源节约，基础功能验证

### 生产环境
- **推荐**: 原生安装 或 容器化部署
- **原因**: 性能最优，功能完整，易于维护

### 资源受限环境
- **推荐**: Docker Compose (低内存)
- **原因**: 最小资源消耗，基础功能可用

## 迁移指南

### 从Docker到原生
1. 导出Docker中的数据
2. 运行原生安装脚本
3. 导入数据
4. 配置服务

### 从原生到Docker
1. 备份原生数据
2. 配置Docker环境
3. 导入数据
4. 启动Docker服务

## 故障排除

### 常见问题
1. **端口冲突**: 检查端口占用情况
2. **权限问题**: 确保有足够权限
3. **依赖缺失**: 安装必要的依赖包
4. **配置错误**: 检查配置文件语法

### 获取帮助
- 查看日志: `docker-compose logs` 或 `journalctl -u service-name`
- 检查健康状态: 访问 `/api/v1/health`
- 查看文档: `docs/` 目录下的相关文档
