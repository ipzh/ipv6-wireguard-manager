# IPv6 WireGuard Manager 快速开始

## 🚀 一键安装

### 最简单的方式（推荐）

**Linux/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-curl.sh | bash
```

**Windows PowerShell:**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.ps1" -OutFile "install.ps1"
.\install.ps1
```

### 传统方式

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 启动服务
chmod +x scripts/*.sh
./scripts/start.sh
```

## 📋 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM
- 5GB+ 磁盘空间

## 🌐 访问系统

安装完成后访问：
- **前端界面**: http://localhost:3000
- **后端API**: http://localhost:8000
- **API文档**: http://localhost:8000/docs

**默认登录:**
- 用户名: `admin`
- 密码: `admin123`

## 🛠️ 常用命令

```bash
# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart
```

## 📚 更多信息

- 详细安装指南: [INSTALL.md](INSTALL.md)
- 项目文档: [README.md](README.md)
- API文档: http://localhost:8000/docs

---

**注意**: 请在生产环境中修改默认密码！
