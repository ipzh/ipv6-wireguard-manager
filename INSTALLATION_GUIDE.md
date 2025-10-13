# IPv6 WireGuard Manager 安装指南

## 🚀 一键安装（推荐）

### 快速安装

```bash
# 一键安装，自动选择最佳安装方式
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者使用wget
wget -qO- https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 安装选项

```bash
# 指定安装目录
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --dir /opt/ipv6-wireguard

# 指定端口
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --port 8080

# 静默安装（无交互）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent
```

### 性能优化安装

```bash
# 高性能安装（启用所有优化）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --performance

# 生产环境安装（包含监控和健康检查）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --production
```

### 指定安装方式

```bash
# Docker安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s docker

# 原生安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s native

# 低内存安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s low-memory
```

### 组合选项示例

```bash
# 生产环境 + 性能优化 + 自定义目录和端口
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --production --performance --dir /opt/my-app --port 8080

# 静默安装 + Docker + 性能优化
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s docker --silent --performance

# 低内存 + 自定义配置
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s low-memory --dir /opt/ipv6-wg --port 3000
```

## 📋 安装选项说明

### 安装类型

| 类型 | 说明 | 适用场景 | 内存要求 |
|------|------|----------|----------|
| `docker` | Docker容器化安装 | 新手用户、测试环境 | 2GB+ |
| `native` | 原生系统安装 | VPS、生产环境 | 1GB+ |
| `low-memory` | 低内存优化安装 | 小内存服务器 | 512MB+ |

### 命令行选项

| 选项 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `--dir DIR` | 安装目录 | `/opt/ipv6-wireguard-manager` | `--dir /opt/my-app` |
| `--port PORT` | Web服务端口 | `80` | `--port 8080` |
| `--silent` | 静默安装（无交互） | `false` | `--silent` |
| `--performance` | 启用性能优化 | `false` | `--performance` |
| `--production` | 生产环境配置 | `false` | `--production` |
| `--help` | 显示帮助信息 | - | `--help` |

### 性能优化选项

当使用 `--performance` 选项时，安装脚本会自动配置：

- **内核参数优化**：TCP缓冲区、拥塞控制算法
- **Nginx优化**：工作进程、连接数、Gzip压缩
- **系统调优**：网络栈优化

### 生产环境选项

当使用 `--production` 选项时，安装脚本会自动配置：

- **监控工具**：htop、iotop、nethogs
- **日志轮转**：自动清理和压缩日志文件
- **自动备份**：数据库和配置文件每日备份
- **安全加固**：防火墙规则、服务配置

## 🔧 系统要求

### 最低要求

- **操作系统**：Ubuntu 18.04+, Debian 10+, CentOS 7+
- **内存**：512MB（低内存模式）
- **存储**：1GB可用空间
- **网络**：支持IPv4和IPv6

### 推荐配置

- **内存**：2GB+
- **存储**：5GB+可用空间
- **CPU**：2核心+
- **网络**：稳定的网络连接

## 📦 安装后配置

### 访问应用

安装完成后，您可以通过以下方式访问：

```bash
# 获取服务器IP
curl -4 ifconfig.me

# 访问前端界面
http://YOUR_SERVER_IP

# 访问API文档
http://YOUR_SERVER_IP/docs
```

### 默认登录信息

- **用户名**：`admin`
- **密码**：`admin123`

⚠️ **重要**：首次登录后请立即修改默认密码！

### 服务管理

```bash
# 查看服务状态
systemctl status ipv6-wireguard-manager

# 启动服务
systemctl start ipv6-wireguard-manager

# 停止服务
systemctl stop ipv6-wireguard-manager

# 重启服务
systemctl restart ipv6-wireguard-manager

# 查看日志
journalctl -u ipv6-wireguard-manager -f
```

### 配置文件位置

| 组件 | 配置文件位置 |
|------|-------------|
| 应用目录 | `/opt/ipv6-wireguard-manager` |
| Nginx配置 | `/etc/nginx/sites-available/ipv6-wireguard-manager` |
| 系统服务 | `/etc/systemd/system/ipv6-wireguard-manager.service` |
| 数据库配置 | `/opt/ipv6-wireguard-manager/backend/.env` |

## 🐳 Docker安装详情

### Docker Compose配置

Docker安装使用以下配置文件：

- **开发环境**：`docker-compose.yml`
- **生产环境**：`docker-compose.production.yml`

### Docker服务管理

```bash
# 启动所有服务
docker-compose -f docker-compose.production.yml up -d

# 查看服务状态
docker-compose -f docker-compose.production.yml ps

# 查看日志
docker-compose -f docker-compose.production.yml logs -f

# 停止所有服务
docker-compose -f docker-compose.production.yml down
```

## 🔍 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口占用
   ss -tlnp | grep :80
   
   # 使用其他端口
   curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --port 8080
   ```

2. **权限不足**
   ```bash
   # 确保以root用户运行
   sudo su -
   ```

3. **网络连接问题**
   ```bash
   # 检查网络连接
   ping github.com
   curl -I https://raw.githubusercontent.com
   ```

4. **内存不足**
   ```bash
   # 使用低内存模式
   curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s low-memory
   ```

### 日志查看

```bash
# 查看安装日志
tail -f /var/log/ipv6-wireguard-install.log

# 查看应用日志
journalctl -u ipv6-wireguard-manager -f

# 查看Nginx日志
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### 重新安装

```bash
# 停止服务
systemctl stop ipv6-wireguard-manager

# 清理安装
rm -rf /opt/ipv6-wireguard-manager
rm -f /etc/nginx/sites-enabled/ipv6-wireguard-manager
rm -f /etc/systemd/system/ipv6-wireguard-manager.service

# 重新安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

## 📞 获取帮助

如果您在安装过程中遇到问题，可以通过以下方式获取帮助：

1. **查看文档**：阅读项目文档和故障排除指南
2. **GitHub Issues**：在GitHub上提交问题
3. **社区讨论**：参与社区讨论
4. **邮件支持**：发送邮件到 support@ipv6-wireguard-manager.com

## 🔄 更新升级

### 自动更新

```bash
# 更新到最新版本
cd /opt/ipv6-wireguard-manager
git pull origin main
systemctl restart ipv6-wireguard-manager
```

### 手动更新

```bash
# 备份当前配置
cp -r /opt/ipv6-wireguard-manager /opt/ipv6-wireguard-manager.backup

# 下载最新版本
cd /opt/ipv6-wireguard-manager
git fetch origin
git reset --hard origin/main

# 更新依赖
cd backend && pip install -r requirements.txt
cd ../frontend && npm install && npm run build

# 重启服务
systemctl restart ipv6-wireguard-manager
```

---

**IPv6 WireGuard Manager** - 让IPv6 VPN管理变得简单而强大！