# 安装问题修复指南

## 问题描述

安装过程中出现后端文件缺失问题：
```
❌ 后端目录不存在: /opt/ipv6-wireguard-manager/backend
```

## 快速修复方案

### 方案1：手动修复（推荐）

在服务器上运行以下命令：

```bash
# 1. 回到项目根目录
cd /root/ipv6-wireguard-manager/ipv6-wireguard-manager

# 2. 复制后端文件到系统目录
sudo cp -r backend /opt/ipv6-wireguard-manager/

# 3. 设置正确的权限
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager/backend

# 4. 验证修复
ls -la /opt/ipv6-wireguard-manager/backend/
```

### 方案2：一键修复脚本

```bash
# 下载并运行修复脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/quick-fix.sh | bash
```

## 修复后的步骤

修复完成后，继续完成安装：

```bash
# 1. 进入后端目录
cd /opt/ipv6-wireguard-manager/backend

# 2. 激活虚拟环境
source venv/bin/activate

# 3. 初始化数据库
python -c "from app.core.database import engine; from app.models import Base; Base.metadata.create_all(bind=engine)"

# 4. 初始化默认数据
python -c "from app.core.init_db import init_db; init_db()"

# 5. 启动服务
sudo systemctl start ipv6-wireguard-manager
sudo systemctl enable ipv6-wireguard-manager

# 6. 检查服务状态
sudo systemctl status ipv6-wireguard-manager
```

## 验证安装

```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 检查端口
sudo netstat -tlnp | grep :8000

# 检查日志
sudo journalctl -u ipv6-wireguard-manager -f
```

## 访问应用

安装完成后，可以通过以下地址访问：

- **IPv4**: http://localhost:3000
- **IPv6**: http://[::1]:3000
- **外网访问**: http://YOUR_SERVER_IP:3000

## 服务管理命令

```bash
# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 重启服务
sudo systemctl restart ipv6-wireguard-manager

# 查看状态
sudo systemctl status ipv6-wireguard-manager

# 查看日志
sudo journalctl -u ipv6-wireguard-manager -f
```

## 故障排除

### 如果服务启动失败

```bash
# 检查日志
sudo journalctl -u ipv6-wireguard-manager --no-pager

# 检查端口占用
sudo netstat -tlnp | grep :8000

# 检查文件权限
ls -la /opt/ipv6-wireguard-manager/backend/
```

### 如果数据库连接失败

```bash
# 检查PostgreSQL状态
sudo systemctl status postgresql

# 检查Redis状态
sudo systemctl status redis-server

# 测试数据库连接
sudo -u postgres psql -c "SELECT version();"
```

## 完整重新安装

如果问题无法修复，可以完全重新安装：

```bash
# 1. 停止服务
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl disable ipv6-wireguard-manager

# 2. 删除系统目录
sudo rm -rf /opt/ipv6-wireguard-manager

# 3. 重新运行安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

## 注意事项

1. 确保有足够的磁盘空间
2. 确保网络连接正常
3. 确保有sudo权限
4. 如果使用防火墙，确保开放相应端口
