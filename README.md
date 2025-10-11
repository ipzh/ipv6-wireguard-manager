# IPv6 WireGuard Manager

现代化的 IPv6 WireGuard 管理平台，基于 FastAPI + React 构建。

## ✨ 特性

- 🚀 **现代化架构**: FastAPI + React + TypeScript
- 🔐 **安全认证**: JWT 认证 + RBAC 权限控制
- 🌐 **IPv6 支持**: 完整的 IPv6 网络管理
- 📊 **实时监控**: WebSocket 实时数据推送
- 🐳 **容器化部署**: Docker 一键部署
- ⚡ **高性能**: 原生安装，资源占用少

## 🚀 快速安装

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 手动安装

```bash
# 下载项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 选择安装方式
./install.sh
```

## 📦 安装方式

| 方式 | 特点 | 适用场景 |
|------|------|----------|
| **Docker** | 环境隔离，易于管理 | 测试环境、开发环境 |
| **原生** | 性能最优，资源占用少 | 生产环境、VPS部署 |

## 🛠️ 系统要求

### 最低要求
- **内存**: 1GB+
- **磁盘**: 2GB+
- **系统**: Linux (Ubuntu/Debian/CentOS/RHEL/Fedora/Alpine)

### 推荐配置
- **内存**: 2GB+
- **磁盘**: 5GB+
- **CPU**: 2核心+

## 🌐 访问地址

安装完成后，访问以下地址：

- **前端界面**: http://your-server-ip:3000
- **API文档**: http://your-server-ip:8000/docs
- **WebSocket**: ws://your-server-ip:8000/ws

## 🔧 管理命令

### Docker 安装
```bash
# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down
```

### 原生安装
```bash
# 查看后端日志
journalctl -u ipv6-wireguard-backend -f

# 查看前端日志
journalctl -u ipv6-wireguard-frontend -f

# 重启服务
systemctl restart ipv6-wireguard-backend ipv6-wireguard-frontend
```

## 📚 项目结构

```
ipv6-wireguard-manager/
├── backend/                 # FastAPI 后端
│   ├── app/
│   │   ├── api/            # API 路由
│   │   ├── core/           # 核心配置
│   │   ├── models/         # 数据模型
│   │   ├── schemas/        # Pydantic 模式
│   │   └── services/       # 业务逻辑
│   └── requirements.txt    # Python 依赖
├── frontend/               # React 前端
│   ├── src/
│   │   ├── components/     # React 组件
│   │   ├── pages/          # 页面组件
│   │   ├── store/          # Redux 状态管理
│   │   └── services/       # API 服务
│   └── package.json        # Node.js 依赖
├── docker-compose.yml      # Docker 配置
├── install.sh             # 智能安装器
├── install-robust.sh      # 健壮安装脚本
└── scripts/               # 工具脚本
```

## 🔧 开发

### 后端开发
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 前端开发
```bash
cd frontend
npm install
npm run dev
```

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 支持

- **GitHub Issues**: [问题反馈](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **文档**: [项目文档](https://github.com/ipzh/ipv6-wireguard-manager)