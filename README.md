# IPv6 WireGuard Manager

一个现代化的IPv6 WireGuard VPN管理系统，提供Web界面管理WireGuard服务器和客户端。

## ✨ 特性

- 🌐 **IPv6支持**：完整的IPv6网络管理
- 🔐 **安全认证**：JWT认证和RBAC权限控制
- 📊 **实时监控**：系统状态和连接监控
- 🎨 **现代界面**：React + TypeScript前端
- ⚡ **高性能**：FastAPI后端，支持高并发
- 🐳 **容器化**：Docker支持，一键部署
- 📱 **响应式设计**：支持移动端访问

## 🚀 快速开始

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-simple.sh | bash
```

### 其他安装方式

#### 🛡️ 健壮安装（解决目录问题）
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-robust.sh | bash
```

#### ⚡ VPS快速安装（原生安装）
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-vps-quick.sh | bash
```

#### 🐳 Docker安装
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-curl.sh | bash
```

#### 🔍 调试安装
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-debug.sh | bash
```

## 📋 系统要求

### 最低要求
- **内存**: 1GB RAM
- **存储**: 2GB 可用空间
- **网络**: IPv4/IPv6 网络连接

### 推荐配置
- **内存**: 2GB+ RAM
- **存储**: 5GB+ 可用空间
- **CPU**: 2核心+

### 支持的操作系统
- Ubuntu 18.04+
- Debian 10+
- CentOS 7+
- RHEL 7+
- Fedora 30+
- Alpine Linux 3.10+

## 🎯 安装方式对比

| 安装方式 | 适用场景 | 资源占用 | 性能 | 易用性 |
|----------|----------|----------|------|--------|
| **一键安装** | 通用 | 中等 | 良好 | ⭐⭐⭐⭐⭐ |
| **健壮安装** | 问题排查 | 中等 | 良好 | ⭐⭐⭐⭐ |
| **VPS快速** | VPS部署 | 最小 | 最优 | ⭐⭐⭐⭐ |
| **Docker** | 容器环境 | 较高 | 良好 | ⭐⭐⭐⭐⭐ |

## 🔧 安装后配置

### 默认访问信息
- **前端界面**: `http://your-server-ip`
- **后端API**: `http://your-server-ip/api`
- **API文档**: `http://your-server-ip/api/docs`

### 默认登录信息
- **用户名**: `admin`
- **密码**: `admin123`

⚠️ **安全提醒**: 请在生产环境中修改默认密码！

## 🛠️ 管理命令

### Docker安装
```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down
```

### 原生安装
```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f

# 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

## 📁 项目结构

```
ipv6-wireguard-manager/
├── backend/                 # FastAPI后端
│   ├── app/                # 应用代码
│   ├── requirements.txt    # Python依赖
│   └── Dockerfile         # 后端容器
├── frontend/               # React前端
│   ├── src/               # 源代码
│   ├── package.json       # Node.js依赖
│   └── Dockerfile         # 前端容器
├── docker-compose.yml     # Docker编排
├── install-*.sh          # 安装脚本
└── README.md             # 项目文档
```

## 🔧 开发环境

### 后端开发
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 前端开发
```bash
cd frontend
npm install
npm run dev
```

## 📚 技术栈

### 后端
- **FastAPI**: 现代Python Web框架
- **PostgreSQL**: 关系型数据库
- **Redis**: 缓存和会话存储
- **SQLAlchemy**: ORM框架
- **Pydantic**: 数据验证
- **JWT**: 身份认证

### 前端
- **React 18**: 用户界面库
- **TypeScript**: 类型安全
- **Vite**: 构建工具
- **Ant Design**: UI组件库
- **React Router**: 路由管理

### 部署
- **Docker**: 容器化部署
- **Nginx**: 反向代理
- **Systemd**: 服务管理

## 🤝 贡献

欢迎提交Issue和Pull Request！

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 支持

如果您遇到问题，请：

1. 查看 [常见问题](#常见问题)
2. 运行调试安装脚本
3. 提交Issue

### 常见问题

**Q: 安装失败怎么办？**
A: 运行调试安装脚本查看详细错误信息：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-debug.sh | bash
```

**Q: 如何修改默认密码？**
A: 登录后进入用户设置页面修改密码，或直接修改数据库中的用户密码。

**Q: 支持哪些操作系统？**
A: 支持主流Linux发行版，详见[系统要求](#系统要求)。

**Q: 如何备份数据？**
A: 备份PostgreSQL数据库和配置文件即可。

---

⭐ 如果这个项目对您有帮助，请给个Star！