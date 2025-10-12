# IPv6 WireGuard Manager

现代化的企业级IPv6 WireGuard VPN管理系统，支持BGP路由、IPv6前缀池管理和实时监控。

## 🚀 一键安装

### 快速开始

```bash
# 一键安装（自动选择最佳安装方式）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 安装选项

- **Docker安装**（推荐新手）：环境隔离，易于管理
- **原生安装**（推荐VPS）：性能最优，资源占用少
- **低内存安装**（1GB内存）：专为小内存服务器优化

### 系统要求

- **操作系统**：Ubuntu 18.04+, Debian 10+, CentOS 7+
- **内存**：最低1GB，推荐2GB+
- **存储**：最低2GB可用空间
- **网络**：支持IPv4和IPv6

## ✨ 主要功能

### 🔐 用户认证系统
- JWT令牌认证
- 用户角色管理
- 会话管理
- 密码安全策略

### 🌐 WireGuard管理
- 服务器配置管理
- 客户端管理
- 密钥生成和管理
- 配置文件导出

### 🛣️ BGP路由管理
- BGP会话管理
- 路由宣告控制
- 前缀过滤
- 路由策略配置

### 📊 IPv6前缀池管理
- 前缀分配和回收
- 客户端关联
- 自动宣告配置
- 使用统计

### 📈 系统监控
- 实时性能监控
- 网络流量统计
- 服务状态监控
- 告警管理

### 📝 日志管理
- 操作日志记录
- 系统日志查看
- 日志导出
- 审计跟踪

## 🛠️ 技术栈

### 后端
- **FastAPI** - 现代Python Web框架
- **SQLAlchemy** - ORM数据库操作
- **PostgreSQL** - 主数据库
- **Redis** - 缓存和会话存储
- **Pydantic** - 数据验证

### 前端
- **React** - 用户界面框架
- **TypeScript** - 类型安全
- **Ant Design** - UI组件库
- **Vite** - 构建工具

### 基础设施
- **Docker** - 容器化部署
- **Nginx** - 反向代理
- **systemd** - 服务管理
- **UFW** - 防火墙管理

## 📖 使用指南

### 默认登录信息
- **用户名**：admin
- **密码**：admin123

### 访问地址
- **Web界面**：http://your-server-ip
- **API文档**：http://your-server-ip/docs
- **健康检查**：http://your-server-ip/health

### 基本操作

1. **登录系统**
   - 使用默认账号登录
   - 修改默认密码

2. **配置WireGuard服务器**
   - 创建服务器配置
   - 设置网络参数
   - 生成密钥对

3. **管理客户端**
   - 添加客户端
   - 分配IP地址
   - 导出配置文件

4. **配置BGP路由**
   - 设置BGP会话
   - 配置路由宣告
   - 管理前缀池

## 🔧 开发指南

### 本地开发

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 后端开发
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# 前端开发
cd frontend
npm install
npm run dev
```

### 环境变量

```bash
# 数据库配置
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
REDIS_URL=redis://localhost:6379/0

# 安全配置
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 调试模式
DEBUG=True
```

## 🐛 故障排除

### 常见问题

1. **安装失败**
   ```bash
   # 检查系统要求
   free -m  # 检查内存
   df -h    # 检查磁盘空间
   ```

2. **服务无法启动**
   ```bash
   # 查看服务状态
   systemctl status ipv6-wireguard-manager
   
   # 查看日志
   journalctl -u ipv6-wireguard-manager -f
   ```

3. **API无响应**
   ```bash
   # 检查端口监听
   netstat -tlnp | grep :8000
   
   # 测试API
   curl http://localhost:8000/health
   ```

### 修复脚本

如果遇到问题，可以使用修复脚本：

```bash
# 修复所有API端点问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-all-endpoints.sh | bash

# 诊断后端问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/diagnose-backend-issue.sh | bash
```

## 📋 更新日志

### v3.0.0 (最新)
- ✅ 修复所有FastAPI依赖注入问题
- ✅ 优化Pydantic 2.x兼容性
- ✅ 改进一键安装脚本
- ✅ 增强错误处理和日志记录
- ✅ 完善API端点功能

### v2.x.x
- 基础功能实现
- 用户认证系统
- WireGuard管理
- BGP路由管理

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢所有贡献者和开源社区的支持！

## 📞 支持

如果您遇到问题或有建议，请：

1. 查看 [故障排除](#故障排除) 部分
2. 搜索 [Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
3. 创建新的 Issue
4. 联系维护者

---

**注意**：请在生产环境中修改默认密码和密钥！