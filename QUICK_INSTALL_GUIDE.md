# IPv6 WireGuard Manager - 快速安装指南

## 🚀 一键安装

### 智能安装（推荐）
```bash
# 自动检测系统并选择最佳安装方式
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 静默安装（生产环境推荐）
```bash
# 静默安装，无交互界面
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent
```

### 指定安装类型
```bash
# 最小化安装（低内存环境）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type minimal --silent

# 原生安装（开发环境）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type native

# Docker安装（生产环境）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type docker
```

## 📋 安装选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--type TYPE` | 安装类型 (docker\|native\|minimal) | 自动选择 |
| `--dir DIR` | 安装目录 | `/opt/ipv6-wireguard-manager` |
| `--port PORT` | Web端口 | `80` |
| `--api-port PORT` | API端口 | `8000` |
| `--silent` | 静默安装 | 否 |
| `--production` | 生产环境安装 | 否 |
| `--skip-deps` | 跳过依赖安装 | 否 |
| `--skip-db` | 跳过数据库配置 | 否 |

## 🖥️ 安装类型

### 1. 原生安装 (native) - 推荐
- **适用场景**: 开发环境、性能要求高的环境
- **优点**: 性能最佳、资源占用低、启动快速
- **要求**: 内存 ≥ 2GB，磁盘 ≥ 5GB

### 2. 最小化安装 (minimal) - 资源受限环境
- **适用场景**: 资源受限环境、测试环境
- **优点**: 资源占用最低、启动最快
- **要求**: 内存 ≥ 1GB，磁盘 ≥ 3GB

### 3. Docker安装 (docker) - 生产环境
- **适用场景**: 生产环境、需要隔离的环境
- **优点**: 完全隔离、易于管理、可移植性强
- **要求**: 内存 ≥ 4GB，磁盘 ≥ 10GB

## 📋 系统要求

### 最低要求
- **内存**: 1GB
- **磁盘**: 3GB
- **CPU**: 1核心
- **系统**: Linux (Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora 30+, Arch Linux, openSUSE 15+)

### 推荐配置
- **内存**: 2GB+
- **磁盘**: 5GB+
- **CPU**: 2核心+

## 🌐 安装后访问

安装完成后，访问以下地址：

- **Web界面**: http://your-server-ip/
- **API文档**: http://your-server-ip:8000/docs
- **API健康检查**: http://your-server-ip:8000/api/v1/health

## 👤 默认登录信息

- **用户名**: admin
- **密码**: admin123
- **邮箱**: admin@example.com

> ⚠️ 首次登录后请立即修改默认密码！

## 🔧 安装后管理

### 服务管理
```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager

# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

### 日志查看
```bash
# 查看应用日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看Nginx日志
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### CLI工具
```bash
# 查看服务状态
ipv6-wireguard-manager status

# 查看日志
ipv6-wireguard-manager logs

# 创建备份
ipv6-wireguard-manager backup

# 系统监控
ipv6-wireguard-manager monitor
```

## 🚨 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看详细日志
sudo journalctl -u ipv6-wireguard-manager -n 50
```

#### 2. 端口占用
```bash
# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8000

# 杀死占用进程
sudo kill -9 <PID>
```

#### 3. 数据库连接失败
```bash
# 检查MySQL服务
sudo systemctl status mysql

# 重启MySQL
sudo systemctl restart mysql
```

#### 4. 权限问题
```bash
# 设置正确的文件权限
sudo chown -R www-data:www-data /var/www/html/
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
```

## 📚 相关文档

- [完整安装指南](INSTALLATION_GUIDE.md) - 详细的安装说明
- [API参考文档](API_REFERENCE.md) - API接口文档
- [部署配置](DEPLOYMENT_CONFIG.md) - 部署配置说明
- [CLI管理指南](CLI_MANAGEMENT_GUIDE.md) - 命令行工具使用

## 🆘 获取帮助

- **GitHub仓库**: https://github.com/ipzh/ipv6-wireguard-manager
- **问题反馈**: https://github.com/ipzh/ipv6-wireguard-manager/issues
- **文档中心**: https://github.com/ipzh/ipv6-wireguard-manager/wiki

---

**IPv6 WireGuard Manager 快速安装指南** - 让部署变得简单快速！🚀