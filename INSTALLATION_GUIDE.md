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

## 📋 系统要求

### 最低要求
- **操作系统**：Ubuntu 18.04+, Debian 10+, CentOS 7+
- **内存**：1GB RAM
- **存储**：2GB 可用空间
- **网络**：支持IPv4和IPv6

### 推荐配置
- **操作系统**：Ubuntu 20.04+ 或 Debian 11+
- **内存**：2GB+ RAM
- **存储**：5GB+ 可用空间
- **CPU**：2核心+

## 🔧 安装流程

### 1. 环境准备

#### 系统要求检查
```bash
# 检查系统版本
cat /etc/os-release

# 检查Python版本
python3 --version

# 检查Docker版本
docker --version

# 检查可用内存
free -h

# 检查磁盘空间
df -h

# 检查CPU核心数
nproc

# 检查系统负载
uptime
```

#### 性能优化检查
```bash
# 检查系统性能参数
cat /proc/sys/vm/swappiness
cat /proc/sys/net/core/somaxconn

# 检查文件描述符限制
ulimit -n

# 检查网络连接限制
sysctl net.ipv4.ip_local_port_range

# 检查内存分配策略
cat /proc/sys/vm/overcommit_memory
```

#### 依赖安装
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3 python3-pip docker.io docker-compose curl wget htop iotop

# CentOS/RHEL
sudo yum install -y python3 python3-pip docker docker-compose curl wget htop iotop

# macOS
brew install python3 docker docker-compose curl wget htop
```

## 🔧 安装方式详解

### 1. Docker安装（推荐新手）

**优点**：
- 环境隔离，不影响系统
- 易于管理和升级
- 一键部署

**缺点**：
- 资源占用较高
- 性能略有损失

**适用场景**：
- 测试环境
- 开发环境
- 对性能要求不高的场景

**安装命令**：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s docker
```

#### 性能优化配置
```bash
# 配置系统性能参数（Linux系统）
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'net.core.somaxconn=65535' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog=65535' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 配置文件描述符限制
echo '* soft nofile 65535' | sudo tee -a /etc/security/limits.conf
echo '* hard nofile 65535' | sudo tee -a /etc/security/limits.conf

# 配置Docker性能优化
sudo mkdir -p /etc/docker
echo '{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65535,
      "Soft": 65535
    }
  },
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3
}' | sudo tee /etc/docker/daemon.json

# 重启Docker服务
sudo systemctl restart docker
```

### 2. 原生安装（推荐VPS）

**优点**：
- 性能最优
- 资源占用最小
- 启动速度快

**缺点**：
- 需要手动管理依赖
- 环境配置相对复杂

**适用场景**：
- 生产环境
- VPS部署
- 对性能要求高的场景

**安装命令**：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s native
```

### 3. 低内存安装（1GB内存）

**特点**：
- 专为小内存服务器优化
- 使用轻量级配置
- 最小化资源占用

**适用场景**：
- 小内存VPS
- 测试服务器
- 资源受限环境

**安装命令**：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s low-memory
```

## 📦 安装过程详解

### 自动安装流程

1. **系统检测**
   - 检测操作系统和版本
   - 检查内存和磁盘空间
   - 验证网络连接

2. **依赖安装**
   - 安装系统依赖包
   - 配置Python环境
   - 安装Node.js和npm

3. **项目下载**
   - 从GitHub下载最新代码
   - 设置文件权限
   - 创建系统用户

4. **数据库配置**
   - 安装和配置PostgreSQL
   - 创建数据库和用户
   - 初始化数据库结构

5. **后端安装**
   - 创建Python虚拟环境
   - 安装Python依赖
   - 配置环境变量
   - 修复所有API端点问题

6. **前端安装**
   - 安装Node.js依赖
   - 构建前端应用
   - 配置静态文件服务

7. **服务配置**
   - 配置Nginx反向代理
   - 创建systemd服务
   - 配置防火墙规则

8. **服务启动**
   - 启动所有服务
   - 验证安装结果
   - 显示访问信息

## 🔍 安装验证

### 检查服务状态

```bash
# 检查所有服务状态
systemctl status nginx postgresql redis-server ipv6-wireguard-manager

# 检查端口监听
netstat -tlnp | grep -E ':(80|8000|5432|6379)'
```

### 测试API

```bash
# 健康检查
curl http://localhost:8000/health

# 状态检查
curl http://localhost:8000/api/v1/status/
```

### 访问Web界面

- **前端界面**：http://your-server-ip
- **API文档**：http://your-server-ip/docs
- **默认登录**：admin / admin123

## 🐛 故障排除

### 常见问题及解决方案

#### 1. 安装失败

**问题**：安装过程中出现错误

**解决方案**：
```bash
# 检查系统要求
free -m  # 检查内存
df -h    # 检查磁盘空间

# 重新安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

#### 2. 后端服务无法启动

**问题**：ipv6-wireguard-manager服务启动失败

**解决方案**：
```bash
# 查看服务状态
systemctl status ipv6-wireguard-manager

# 查看详细日志
journalctl -u ipv6-wireguard-manager -f

# 修复API端点问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-all-endpoints.sh | bash
```

#### 3. 数据库连接失败

**问题**：PostgreSQL连接错误

**解决方案**：
```bash
# 检查PostgreSQL状态
systemctl status postgresql

# 重启PostgreSQL
systemctl restart postgresql

# 检查数据库配置
sudo -u postgres psql -c "\l"
```

#### 4. 前端无法访问

**问题**：Web界面显示空白或错误

**解决方案**：
```bash
# 检查Nginx状态
systemctl status nginx

# 检查Nginx配置
nginx -t

# 重启Nginx
systemctl restart nginx
```

#### 5. API无响应

**问题**：API端点返回错误

**解决方案**：
```bash
# 检查后端服务
curl http://localhost:8000/health

# 诊断后端问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/diagnose-backend-issue.sh | bash

# 修复所有端点
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-all-endpoints.sh | bash
```

### 修复脚本

项目提供了多个修复脚本来解决常见问题：

```bash
# 修复所有API端点问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-all-endpoints.sh | bash

# 诊断后端问题
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/diagnose-backend-issue.sh | bash

# 快速修复后端服务
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/quick-fix-backend.sh | bash
```

## 🔄 升级指南

### 自动升级

```bash
# 停止服务
systemctl stop ipv6-wireguard-manager

# 备份数据
cp -r /opt/ipv6-wireguard-manager /opt/ipv6-wireguard-manager.backup

# 重新安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 恢复数据（如需要）
# cp -r /opt/ipv6-wireguard-manager.backup/data /opt/ipv6-wireguard-manager/
```

### 手动升级

```bash
# 进入项目目录
cd /opt/ipv6-wireguard-manager

# 拉取最新代码
git pull origin main

# 更新后端依赖
cd backend
source venv/bin/activate
pip install -r requirements.txt

# 更新前端依赖
cd ../frontend
npm install
npm run build

# 重启服务
systemctl restart ipv6-wireguard-manager
```

## 🗑️ 卸载指南

### 完全卸载

```bash
# 停止所有服务
systemctl stop ipv6-wireguard-manager nginx postgresql redis-server

# 删除服务文件
rm -f /etc/systemd/system/ipv6-wireguard-manager.service
systemctl daemon-reload

# 删除Nginx配置
rm -f /etc/nginx/sites-enabled/ipv6-wireguard-manager
rm -f /etc/nginx/sites-available/ipv6-wireguard-manager
systemctl restart nginx

# 删除应用目录
rm -rf /opt/ipv6-wireguard-manager

# 删除系统用户
userdel -r ipv6wgm

# 删除数据库（可选）
sudo -u postgres psql -c "DROP DATABASE ipv6wgm;"
sudo -u postgres psql -c "DROP USER ipv6wgm;"
```

## 📞 获取帮助

如果您在安装过程中遇到问题：

1. 查看本文档的故障排除部分
2. 运行诊断脚本获取详细信息
3. 查看项目Issues页面
4. 创建新的Issue描述问题

---

**注意**：安装完成后请立即修改默认密码！