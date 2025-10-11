# IPv6 WireGuard Manager 安装指南

## 🚀 一键安装

### 推荐方式：统一安装脚本

```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

这个脚本会：
1. 自动检测您的系统IP地址（IPv4/IPv6）
2. 显示安装方式选择菜单
3. 根据您的选择执行相应的安装
4. 显示完整的访问信息

### 自动选择安装方式

```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --auto
```

脚本会自动检测：
- 系统内存大小
- CPU核心数
- 是否为VPS环境
- 根据检测结果选择最佳安装方式

### 强制指定安装方式

**强制Docker安装**
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --docker
```

**强制原生安装**
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --native
```

## 📋 安装方式选择

### 🐳 Docker安装
**适合场景**：
- 新手用户
- 测试环境
- 开发环境
- 对性能要求不高的场景

**优点**：
- 环境隔离，易于管理
- 支持一键部署
- 配置简单

**缺点**：
- 资源占用较高（2GB+内存）
- 性能略有损失
- 启动速度较慢

### ⚡ 原生安装
**适合场景**：
- VPS部署
- 生产环境
- 对性能要求高的场景
- 资源受限的环境

**优点**：
- 性能最优
- 资源占用最小（1GB+内存）
- 启动速度快
- 内存使用减少50%

**缺点**：
- 需要手动管理依赖
- 环境配置相对复杂

## 🔧 系统要求

### 支持的操作系统
- **Ubuntu** (18.04+)
- **Debian** (9+)
- **CentOS** (7+)
- **RHEL** (7+)
- **Fedora** (30+)
- **Alpine Linux** (3.10+)

### 硬件要求

#### Docker安装
- **内存**: 2GB+
- **磁盘**: 5GB+
- **CPU**: 2核心+

#### 原生安装
- **内存**: 1GB+
- **磁盘**: 3GB+
- **CPU**: 1核心+

## 📊 自动选择逻辑

统一安装脚本的自动选择逻辑：

1. **内存检测**
   - 内存 < 2GB → 选择原生安装
   - 内存 ≥ 2GB → 继续检测

2. **环境检测**
   - VPS环境 + 内存 < 4GB → 选择原生安装
   - 其他情况 → 选择Docker安装

3. **显示选择原因**
   - 脚本会显示选择的具体原因
   - 用户可以根据原因了解选择逻辑

## 🎯 安装后访问

安装完成后，脚本会显示访问信息：

### IPv4访问地址
- 前端界面: `http://您的IP地址`
- 后端API: `http://您的IP地址/api`
- API文档: `http://您的IP地址/api/docs`

### IPv6访问地址（如果支持）
- 前端界面: `http://[您的IPv6地址]`
- 后端API: `http://[您的IPv6地址]/api`
- API文档: `http://[您的IPv6地址]/api/docs`

### 默认登录信息
- 用户名: `admin`
- 密码: `admin123`

## 🛠️ 管理命令

### Docker安装管理
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

### 原生安装管理
```bash
# 查看状态
sudo systemctl status ipv6-wireguard-manager

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f

# 重启服务
sudo systemctl restart ipv6-wireguard-manager

# 重启Nginx
sudo systemctl restart nginx
```

## 🔒 安全配置

### 修改默认密码
1. 登录管理界面
2. 进入用户设置
3. 修改默认密码

### 防火墙配置
脚本会自动配置基本防火墙规则：
- 允许SSH (22端口)
- 允许HTTP (80端口)
- 允许HTTPS (443端口)

### 生产环境建议
1. 修改默认密码
2. 配置HTTPS证书
3. 定期备份数据
4. 监控系统资源

## ❓ 常见问题

### Q: 如何选择安装方式？
A: 推荐使用统一安装脚本，它会根据您的系统自动选择最佳方式。

### Q: 可以切换安装方式吗？
A: 可以，但需要先卸载当前安装，然后重新安装。

### Q: 支持哪些VPS提供商？
A: 支持所有主流VPS提供商，包括但不限于：AWS、Google Cloud、Azure、DigitalOcean、Vultr、Linode等。

### Q: 如何卸载？
A: 
- Docker安装：`docker-compose down && docker system prune -f`
- 原生安装：`sudo systemctl stop ipv6-wireguard-manager && sudo systemctl disable ipv6-wireguard-manager`

## 📞 技术支持

如果遇到安装问题，请：
1. 检查系统要求
2. 查看安装日志
3. 提交Issue到GitHub仓库
4. 提供详细的错误信息

---

**快速开始**：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```
