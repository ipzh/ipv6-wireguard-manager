# 安装指南

## 🚀 快速安装

### 一键安装（推荐）
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-simple.sh | bash
```

## 🔧 其他安装方式

### 1. 健壮安装（解决目录问题）
适用于遇到目录结构问题的用户：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-robust.sh | bash
```

### 2. VPS快速安装（原生安装）
专为VPS环境优化，无需Docker：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-vps-quick.sh | bash
```

### 3. Docker安装
使用Docker容器部署：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-curl.sh | bash
```

### 4. 调试安装
查看详细的安装过程和错误信息：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-debug.sh | bash
```

## 📋 系统要求

### 最低配置
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

## 🎯 安装方式选择

| 场景 | 推荐安装方式 | 说明 |
|------|-------------|------|
| **新手用户** | 一键安装 | 自动选择最佳方式 |
| **VPS部署** | VPS快速安装 | 原生安装，性能最优 |
| **容器环境** | Docker安装 | 使用Docker容器 |
| **遇到问题** | 健壮安装 | 解决目录结构问题 |
| **调试问题** | 调试安装 | 查看详细错误信息 |

## ⚙️ 安装后配置

### 访问地址
安装完成后，您可以通过以下地址访问：

- **前端界面**: `http://your-server-ip`
- **后端API**: `http://your-server-ip/api`
- **API文档**: `http://your-server-ip/api/docs`

### 默认登录信息
- **用户名**: `admin`
- **密码**: `admin123`

⚠️ **重要**: 请立即修改默认密码！

## 🛠️ 服务管理

### Docker安装管理
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

### 原生安装管理
```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f

# 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

## 🔧 故障排除

### 常见问题

**1. 安装失败**
```bash
# 运行调试安装查看详细错误
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-debug.sh | bash
```

**2. 目录结构问题**
```bash
# 使用健壮安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-robust.sh | bash
```

**3. 依赖问题**
```bash
# 运行依赖修复脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-dependencies.sh | bash
```

**4. Docker构建问题**
```bash
# 运行构建修复脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-build.sh | bash
```

### 日志查看

**Docker安装**:
```bash
docker-compose logs backend
docker-compose logs frontend
```

**原生安装**:
```bash
sudo journalctl -u ipv6-wireguard-manager -f
sudo journalctl -u nginx -f
```

## 📞 获取帮助

如果遇到问题：

1. 查看本文档的故障排除部分
2. 运行相应的调试脚本
3. 在GitHub上提交Issue
4. 查看项目README.md获取更多信息

---

**提示**: 建议在生产环境中使用VPS快速安装方式，以获得最佳性能。