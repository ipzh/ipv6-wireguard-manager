# IPv6 WireGuard Manager 安装指南

## 🚀 一键安装方法

### 方法一：curl 一键安装（推荐）

**Linux/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-curl.sh | bash
```

**Windows (PowerShell):**
```powershell
# 下载并执行PowerShell安装脚本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.ps1" -OutFile "install.ps1"
.\install.ps1
```

### 方法二：Git 克隆安装

```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 一键启动
chmod +x scripts/*.sh
./scripts/start.sh
```

**Windows:**
```cmd
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
scripts\start.bat
```

### 方法三：Docker 直接安装

```bash
# 创建项目目录
mkdir ipv6-wireguard-manager
cd ipv6-wireguard-manager

# 下载docker-compose.yml
curl -O https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/docker-compose.yml

# 启动服务
docker-compose up -d
```

## 📋 系统要求

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **内存**: 2GB+ RAM
- **磁盘**: 5GB+ 可用空间
- **网络**: 互联网连接（用于下载镜像）

## 🔧 安装前准备

### 安装 Docker

**Ubuntu/Debian:**
```bash
# 更新包索引
sudo apt-get update

# 安装Docker
sudo apt-get install docker.io docker-compose

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到docker组
sudo usermod -aG docker $USER
```

**CentOS/RHEL:**
```bash
# 安装Docker
sudo yum install docker docker-compose

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到docker组
sudo usermod -aG docker $USER
```

**macOS:**
```bash
# 使用Homebrew安装
brew install docker docker-compose

# 或下载Docker Desktop
# https://docs.docker.com/desktop/mac/install/
```

**Windows:**
- 下载并安装 [Docker Desktop](https://docs.docker.com/desktop/windows/install/)

### 安装 Git

**Ubuntu/Debian:**
```bash
sudo apt-get install git
```

**CentOS/RHEL:**
```bash
sudo yum install git
```

**macOS:**
```bash
brew install git
```

**Windows:**
- 下载并安装 [Git for Windows](https://git-scm.com/download/win)

## 🌐 访问系统

安装完成后，您可以通过以下地址访问：

- **前端界面**: http://localhost:3000
- **后端API**: http://localhost:8000
- **API文档**: http://localhost:8000/docs

### 默认登录信息
- **用户名**: `admin`
- **密码**: `admin123`

## 🛠️ 管理命令

### 查看服务状态
```bash
docker-compose ps
```

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend
```

### 停止服务
```bash
docker-compose down
```

### 重启服务
```bash
docker-compose restart
```

### 更新服务
```bash
# 拉取最新镜像
docker-compose pull

# 重新构建并启动
docker-compose up -d --build
```

## 🔍 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tulpn | grep :3000
   netstat -tulpn | grep :8000
   
   # 修改端口（编辑docker-compose.yml）
   ports:
     - "3001:3000"  # 将前端端口改为3001
     - "8001:8000"  # 将后端端口改为8001
   ```

2. **Docker权限问题**
   ```bash
   # 添加用户到docker组
   sudo usermod -aG docker $USER
   
   # 重新登录或执行
   newgrp docker
   ```

3. **内存不足**
   ```bash
   # 检查系统资源
   free -h
   df -h
   
   # 清理Docker资源
   docker system prune -a
   ```

4. **网络问题**
   ```bash
   # 检查Docker网络
   docker network ls
   
   # 重启Docker服务
   sudo systemctl restart docker
   ```

### 获取帮助

- 查看项目文档: [README.md](README.md)
- 查看API文档: http://localhost:8000/docs
- 提交Issue: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)

## 🔒 安全配置

### 修改默认密码

1. 编辑配置文件:
   ```bash
   nano backend/.env
   ```

2. 修改以下配置:
   ```env
   # 生成新的JWT密钥
   SECRET_KEY=your-new-secret-key
   
   # 修改数据库密码
   DATABASE_URL=postgresql://ipv6wgm:your-new-password@localhost:5432/ipv6wgm
   ASYNC_DATABASE_URL=postgresql+asyncpg://ipv6wgm:your-new-password@localhost:5432/ipv6wgm
   ```

3. 重启服务:
   ```bash
   docker-compose restart
   ```

### 配置防火墙

```bash
# 只允许特定IP访问管理界面
sudo ufw allow from 192.168.1.0/24 to any port 3000
sudo ufw allow from 192.168.1.0/24 to any port 8000

# 或使用iptables
sudo iptables -A INPUT -p tcp --dport 3000 -s 192.168.1.0/24 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8000 -s 192.168.1.0/24 -j ACCEPT
```

## 📊 性能优化

### 系统资源优化

```bash
# 增加Docker内存限制
# 编辑docker-compose.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### 数据库优化

```bash
# 编辑PostgreSQL配置
# 在docker-compose.yml中添加环境变量
services:
  db:
    environment:
      POSTGRES_SHARED_BUFFERS: 256MB
      POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB
```

## 🔄 备份和恢复

### 备份数据

```bash
# 备份数据库
docker-compose exec db pg_dump -U ipv6wgm ipv6wgm > backup.sql

# 备份配置文件
tar -czf config-backup.tar.gz backend/.env docker-compose.yml
```

### 恢复数据

```bash
# 恢复数据库
docker-compose exec -T db psql -U ipv6wgm ipv6wgm < backup.sql

# 恢复配置文件
tar -xzf config-backup.tar.gz
```

## 📈 监控和维护

### 系统监控

```bash
# 查看容器资源使用
docker stats

# 查看系统资源
htop
df -h
free -h
```

### 日志管理

```bash
# 清理旧日志
docker-compose logs --tail=1000 > recent-logs.txt
docker-compose down
docker system prune -f
```

---

**注意**: 请在生产环境中修改默认密码并配置适当的安全设置。
