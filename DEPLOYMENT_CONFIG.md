# IPv6 WireGuard Manager 部署配置指南

## 🌐 多主机部署支持

本项目已完全支持IPv6/IPv4双栈网络，可以在任何支持双栈的主机上部署。

## 📋 部署前准备

### 1. 系统要求
- **操作系统**: Linux (Ubuntu 20.04+, CentOS 8+, Debian 11+)
- **内存**: 最少 2GB RAM
- **存储**: 最少 10GB 可用空间
- **网络**: 支持IPv4和IPv6双栈

### 2. 网络要求
- **端口**: 80 (HTTP), 8000 (API), 5432 (PostgreSQL), 6379 (Redis)
- **防火墙**: 确保必要端口开放
- **IPv6**: 确保系统支持IPv6（可选但推荐）

## 🚀 部署方式

### 方式一：一键安装（推荐）

```bash
# 自动检测最佳安装方式
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 指定安装方式
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s native

# 自定义配置
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --dir /opt/my-app --port 8080
```

### 方式二：Docker部署

```bash
# 开发环境
docker-compose up -d

# 生产环境
docker-compose -f docker-compose.production.yml up -d
```

### 方式三：手动部署

```bash
# 1. 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 2. 安装依赖
sudo apt update
sudo apt install -y python3 python3-pip nodejs npm postgresql redis-server nginx

# 3. 配置数据库
sudo -u postgres createdb ipv6wgm
sudo -u postgres createuser ipv6wgm
sudo -u postgres psql -c "ALTER USER ipv6wgm PASSWORD 'password';"

# 4. 构建前端
cd frontend
npm install
npm run build

# 5. 配置后端
cd ../backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 6. 启动服务
sudo systemctl start postgresql redis-server
sudo systemctl enable postgresql redis-server
```

## ⚙️ 环境变量配置

### 前端环境变量

创建 `frontend/.env` 文件：

```bash
# API配置 - 自动检测，无需修改
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8000

# 应用配置
VITE_APP_NAME=IPv6 WireGuard Manager
VITE_APP_VERSION=3.0.0
VITE_DEBUG=false

# 功能开关
VITE_ENABLE_WEBSOCKET=true
VITE_ENABLE_MONITORING=true
VITE_ENABLE_BGP=true

# 主题配置
VITE_THEME=light
VITE_PRIMARY_COLOR=#3b82f6
```

### 后端环境变量

创建 `backend/.env` 文件：

```bash
# 数据库配置
DATABASE_URL=postgresql://ipv6wgm:password@localhost:5432/ipv6wgm
REDIS_URL=redis://localhost:6379/0

# 安全配置
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
DEBUG=false
LOG_LEVEL=INFO
```

## 🌍 网络配置

### IPv4配置

系统会自动检测IPv4地址，支持：
- 公网IPv4地址
- 内网IPv4地址 (192.168.x.x, 172.16-31.x.x, 10.x.x.x)
- 本地地址 (127.0.0.1, localhost)

### IPv6配置

系统会自动检测IPv6地址，支持：
- 公网IPv6地址
- 内网IPv6地址 (fd00::/8, fe80::/10)
- 本地地址 (::1)

### 双栈网络

系统同时支持IPv4和IPv6访问：
- 前端：自动检测并使用当前网络协议
- 后端：监听所有接口 (0.0.0.0)
- Nginx：同时监听IPv4和IPv6端口

## 🔧 配置验证

### 1. 检查网络配置

访问前端页面，查看网络配置信息：
- 打开浏览器开发者工具
- 查看控制台输出的配置信息
- 确认API和WebSocket地址正确

### 2. 测试API连接

```bash
# 测试健康检查
curl http://your-server-ip:8000/health

# 测试IPv6连接
curl http://[your-ipv6-address]:8000/health
```

### 3. 测试前端访问

```bash
# IPv4访问
curl http://your-server-ip/

# IPv6访问
curl http://[your-ipv6-address]/
```

## 🐳 Docker网络配置

### 开发环境

```yaml
networks:
  ipv6wgm-network:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: 172.18.0.0/16
        - subnet: 2001:db8::/64
```

### 生产环境

```yaml
networks:
  app-network:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
        - subnet: 2001:db8::/64
```

## 🔒 安全配置

### 1. 防火墙设置

```bash
# UFW配置
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw enable

# iptables配置
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
```

### 2. SSL/TLS配置

```bash
# 使用Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com

# 或使用自签名证书
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt
```

## 📊 监控和日志

### 1. 系统监控

```bash
# 检查服务状态
sudo systemctl status nginx
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status postgresql
sudo systemctl status redis-server

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 2. 性能监控

```bash
# 系统资源
htop
iotop
nethogs

# 网络连接
ss -tuln
netstat -tuln
```

## 🚨 故障排除

### 常见问题

1. **前端无法连接后端**
   - 检查防火墙设置
   - 确认后端服务运行正常
   - 验证API地址配置

2. **IPv6访问失败**
   - 确认系统支持IPv6
   - 检查IPv6网络配置
   - 验证DNS解析

3. **WebSocket连接失败**
   - 检查WebSocket URL配置
   - 确认代理设置正确
   - 验证防火墙规则

### 调试命令

```bash
# 检查端口监听
sudo ss -tuln | grep -E ':(80|8000|5432|6379) '

# 检查IPv6支持
ip -6 addr show
ping6 ::1

# 检查DNS解析
nslookup your-domain.com
dig AAAA your-domain.com
```

## 📝 最佳实践

1. **生产环境部署**
   - 使用HTTPS
   - 配置防火墙
   - 设置监控告警
   - 定期备份数据

2. **性能优化**
   - 启用Gzip压缩
   - 配置缓存策略
   - 优化数据库查询
   - 使用CDN加速

3. **安全加固**
   - 定期更新依赖
   - 使用强密码
   - 限制API访问
   - 启用访问日志

## 📞 技术支持

如果遇到问题，请：

1. 查看日志文件
2. 检查网络配置
3. 验证环境变量
4. 提交Issue到GitHub

---

**注意**: 本项目已完全支持IPv6/IPv4双栈网络，可以在任何支持双栈的主机上部署。系统会自动检测网络环境并适配相应的协议。
