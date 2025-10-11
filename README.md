# IPv6 WireGuard Manager

一个现代化的企业级IPv6 WireGuard VPN管理平台，基于Python FastAPI后端和React前端构建。

## ✨ 特性

- 🚀 **现代化架构**: FastAPI + React + TypeScript
- 🔐 **企业级安全**: JWT认证 + RBAC权限控制
- 📊 **实时监控**: WebSocket实时数据推送
- 🌐 **IPv6支持**: 完整的IPv6网络管理
- 🐳 **容器化部署**: Docker一键部署
- 📱 **响应式设计**: 适配各种设备
- 🔧 **自动化管理**: 完整的脚本工具

## 🚀 一键安装

### 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM
- 5GB+ 磁盘空间

### 快速开始

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 一键启动（Linux/macOS）
chmod +x scripts/*.sh
./scripts/start.sh

# 一键启动（Windows）
scripts\start.bat
```

### 访问系统

- **前端界面**: http://localhost:3000
- **后端API**: http://localhost:8000
- **API文档**: http://localhost:8000/docs

**默认登录信息:**
- 用户名: `admin`
- 密码: `admin123`

## 📋 功能模块

### 🔧 WireGuard管理
- 服务器配置和管理
- 客户端配置生成
- QR码生成
- 实时状态监控
- 流量统计

### 🌐 网络管理
- 网络接口管理
- 防火墙规则配置
- 路由表管理
- 流量监控

### 📊 监控系统
- 系统性能监控
- 服务状态检查
- 告警通知
- 实时数据推送

### 📝 日志管理
- 审计日志
- 操作日志
- 日志搜索
- 日志导出

### 👥 用户管理
- 用户认证
- 角色权限
- 操作审计

## 🛠️ 管理命令

```bash
# 启动服务
./scripts/start.sh          # Linux/macOS
scripts\start.bat           # Windows

# 停止服务
./scripts/stop.sh           # Linux/macOS
scripts\stop.bat            # Windows

# 查看状态
./scripts/status.sh         # Linux/macOS
scripts\status.bat          # Windows

# 查看日志
./scripts/logs.sh           # Linux/macOS
scripts\logs.bat            # Windows

# 备份数据
./scripts/backup.sh         # Linux/macOS
scripts\backup.bat          # Windows

# 恢复数据
./scripts/restore.sh backup_name    # Linux/macOS
scripts\restore.bat backup_name     # Windows

# 清理数据
./scripts/clean.sh          # Linux/macOS
scripts\clean.bat           # Windows
```

## 🏗️ 技术架构

### 后端技术栈
- **框架**: FastAPI 0.104.1
- **数据库**: PostgreSQL + SQLAlchemy 2.0
- **缓存**: Redis
- **认证**: JWT + Passlib
- **异步**: asyncio + asyncpg
- **监控**: psutil + prometheus-client
- **WebSocket**: websockets

### 前端技术栈
- **框架**: React 18 + TypeScript
- **构建工具**: Vite
- **UI库**: Ant Design 5.x
- **状态管理**: Redux Toolkit + RTK Query
- **路由**: React Router v6
- **图表**: Recharts

### 基础设施
- **容器化**: Docker + Docker Compose
- **数据库**: PostgreSQL 15
- **缓存**: Redis 7
- **反向代理**: Nginx

## 📁 项目结构

```
ipv6-wireguard-manager/
├── backend/                 # FastAPI后端
│   ├── app/
│   │   ├── api/            # API路由
│   │   ├── core/           # 核心配置
│   │   ├── models/         # 数据库模型
│   │   ├── schemas/        # Pydantic模式
│   │   ├── services/       # 业务逻辑
│   │   └── utils/          # 工具函数
│   ├── migrations/         # 数据库迁移
│   ├── tests/             # 测试文件
│   └── requirements.txt   # Python依赖
├── frontend/               # React前端
│   ├── src/
│   │   ├── components/    # React组件
│   │   ├── pages/         # 页面组件
│   │   ├── hooks/         # 自定义Hook
│   │   ├── services/      # API服务
│   │   ├── store/         # Redux状态管理
│   │   ├── types/         # TypeScript类型
│   │   └── utils/         # 工具函数
│   └── package.json       # Node.js依赖
├── docker/                # Docker配置
├── docs/                  # 项目文档
├── scripts/               # 管理脚本
└── docker-compose.yml     # 服务编排
```

## 🔧 开发环境

```bash
# 启动开发环境
./scripts/dev.sh           # Linux/macOS
scripts\dev.bat            # Windows

# 运行测试
./scripts/test.sh          # Linux/macOS
scripts\test.bat           # Windows

# 构建镜像
./scripts/build.sh         # Linux/macOS
scripts\build.bat          # Windows
```

## 📚 API文档

启动服务后，访问 http://localhost:8000/docs 查看完整的API文档。

### 主要API端点

- `POST /api/v1/auth/login` - 用户登录
- `GET /api/v1/wireguard/servers` - 获取服务器列表
- `POST /api/v1/wireguard/servers` - 创建服务器
- `GET /api/v1/monitoring/system/stats` - 获取系统统计
- `WS /api/v1/ws/{user_id}` - WebSocket连接

## 🔒 安全特性

- JWT令牌认证
- 基于角色的访问控制 (RBAC)
- 密码哈希存储
- API请求验证
- 操作审计日志
- 防火墙规则管理

## 📈 性能特性

- 异步数据库操作
- Redis缓存支持
- WebSocket实时通信
- 分页查询优化
- 数据库连接池
- 静态资源优化

## 🐛 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tulpn | grep :3000
   netstat -tulpn | grep :8000
   ```

2. **Docker问题**
   ```bash
   # 检查Docker状态
   docker --version
   docker-compose --version
   ```

3. **权限问题**
   ```bash
   # Linux/macOS
   chmod +x scripts/*.sh
   ```

4. **内存不足**
   ```bash
   # 检查系统资源
   free -h
   df -h
   ```

### 获取帮助

- 查看日志: `./scripts/logs.sh`
- 检查状态: `./scripts/status.sh`
- 查看文档: `docs/` 目录
- 提交Issue: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)

## 📄 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📞 联系方式

- 项目地址: [https://github.com/ipzh/ipv6-wireguard-manager](https://github.com/ipzh/ipv6-wireguard-manager)
- 问题反馈: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者！

---

**注意**: 请在生产环境中修改默认密码并配置适当的安全设置。