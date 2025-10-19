# 快速安装指南

## 概述

本指南提供IPv6 WireGuard Manager的快速安装方法，帮助您在几分钟内完成部署。

## 系统要求

### 最低配置
- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+
- **内存**: 2GB RAM
- **存储**: 10GB 可用空间
- **网络**: 支持IPv6的网络连接

### 推荐配置
- **操作系统**: Ubuntu 20.04+, Debian 10+
- **内存**: 4GB RAM
- **存储**: 20GB 可用空间
- **CPU**: 2核心以上

## 安装方法

### 方法一：一键安装（推荐）

```bash
# 下载并执行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 或者使用wget
wget -qO- https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 方法二：下载后安装

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh

# 添加执行权限
chmod +x install.sh

# 执行安装
./install.sh
```

### 方法三：Docker安装

```bash
# 使用Docker Compose快速部署
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/docker-compose.yml -o docker-compose.yml

# 启动服务
docker-compose up -d
```

## 安装选项

### 智能安装模式

自动配置参数，适合快速部署：

```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --auto
```

### 自定义安装

指定安装参数：

```bash
./install.sh --type=native --dir=/opt/my-wireguard --port=8080
```

### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--type` | 安装类型 (docker/native/minimal) | docker |
| `--dir` | 安装目录 | /opt/ipv6-wireguard-manager |
| `--port` | Web端口 | 80 |
| `--api-port` | API端口 | 8000 |
| `--auto` | 智能安装模式 | false |
| `--production` | 生产模式 | false |
| `--performance` | 性能优化 | false |

## 安装后配置

### 1. 访问管理界面

安装完成后，通过浏览器访问：
- **Web界面**: http://your-server-ip
- **API文档**: http://your-server-ip/api/v1/docs

### 2. 首次登录

默认管理员账户：
- **用户名**: admin
- **密码**: admin123

> **安全提示**: 首次登录后请立即修改默认密码

### 3. 配置WireGuard

1. 登录管理界面
2. 导航到"WireGuard服务器"
3. 创建新的服务器实例
4. 配置网络参数
5. 启动服务器

## 验证安装

### 检查服务状态

```bash
# Docker安装
docker-compose ps

# 原生安装
sudo systemctl status ipv6-wireguard-manager
```

### 测试API连接

```bash
# 测试API端点
curl http://your-server-ip/api/v1/health

# 预期响应
{"status": "ok", "version": "x.x.x"}
```

### 检查日志

```bash
# Docker安装
docker-compose logs -f

# 原生安装
sudo journalctl -u ipv6-wireguard-manager -f
```

## 常见问题

### 1. 端口冲突

如果遇到端口冲突，可以指定其他端口：

```bash
./install.sh --port=8080 --api-port=8001
```

### 2. 权限问题

确保以root权限执行安装脚本：

```bash
sudo ./install.sh
```

### 3. 防火墙配置

开放必要端口：

```bash
# Ubuntu/Debian
sudo ufw allow 80
sudo ufw allow 8000
sudo ufw allow 51820/udp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --reload
```

### 4. 内存不足

如果系统内存不足，可以启用最小化安装：

```bash
./install.sh --type=minimal
```

## 卸载

### Docker安装卸载

```bash
# 停止并删除容器
docker-compose down -v

# 删除镜像
docker rmi ipv6-wireguard-manager
```

### 原生安装卸载

```bash
# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 禁用服务
sudo systemctl disable ipv6-wireguard-manager

# 删除文件
sudo rm -rf /opt/ipv6-wireguard-manager

# 删除服务文件
sudo rm -f /etc/systemd/system/ipv6-wireguard-manager.service

# 删除Nginx配置
sudo rm -f /etc/nginx/sites-available/ipv6-wireguard-manager
sudo rm -f /etc/nginx/sites-enabled/ipv6-wireguard-manager

# 重载服务
sudo systemctl daemon-reload
sudo systemctl reload nginx
```

## 升级

### Docker安装升级

```bash
# 拉取最新镜像
docker-compose pull

# 重启服务
docker-compose up -d
```

### 原生安装升级

```bash
# 备份配置
sudo cp -r /opt/ipv6-wireguard-manager/.env /opt/ipv6-wireguard-manager/.env.bak

# 下载最新版本
cd /tmp
wget https://github.com/ipzh/ipv6-wireguard-manager/archive/main.zip
unzip main.zip

# 更新文件
sudo cp -r ipv6-wireguard-manager-main/* /opt/ipv6-wireguard-manager/

# 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

## 技术支持

- **文档**: [完整文档](https://github.com/ipzh/ipv6-wireguard-manager/tree/main/docs)
- **问题反馈**: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **社区讨论**: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)

## 下一步

安装完成后，建议您：

1. 阅读[用户手册](USER_MANUAL.md)了解系统功能
2. 查看[API文档](API_DOCUMENTATION.md)了解接口使用
3. 参考[部署指南](DEPLOYMENT_GUIDE.md)进行生产环境部署
4. 了解[API路径构建器](API_PATH_BUILDER_USAGE.md)的使用方法

---

**注意**: 本指南基于当前版本，如有更新请查看最新版本文档。