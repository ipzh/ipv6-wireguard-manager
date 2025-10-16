# 权限问题故障排除指南

## 🚨 常见权限问题

### 问题1: Permission denied: 'uploads'

**错误信息**:
```
PermissionError: [Errno 13] Permission denied: 'uploads'
```

**原因**: 应用试图创建 `uploads` 目录但没有权限，或者目录路径配置错误。

**解决方案**:

#### 方案1: 使用权限修复脚本（推荐）
```bash
# 运行权限修复脚本
chmod +x fix_permissions.sh
./fix_permissions.sh
```

#### 方案2: 手动修复
```bash
# 1. 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 2. 创建必要的目录
sudo mkdir -p /opt/ipv6-wireguard-manager/uploads
sudo mkdir -p /opt/ipv6-wireguard-manager/logs
sudo mkdir -p /opt/ipv6-wireguard-manager/temp
sudo mkdir -p /opt/ipv6-wireguard-manager/backups

# 3. 设置目录权限
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager

# 4. 重启服务
sudo systemctl start ipv6-wireguard-manager
```

### 问题2: 服务用户权限不足

**错误信息**:
```
Permission denied: '/opt/ipv6-wireguard-manager/...'
```

**解决方案**:
```bash
# 检查服务用户
id ipv6wgm

# 如果用户不存在，创建用户
sudo useradd -r -s /bin/false ipv6wgm

# 设置目录所有者
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
```

### 问题3: Python虚拟环境权限问题

**错误信息**:
```
Permission denied: '/opt/ipv6-wireguard-manager/venv/bin/python'
```

**解决方案**:
```bash
# 修复虚拟环境权限
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager/venv
sudo chmod -R 755 /opt/ipv6-wireguard-manager/venv
```

### 问题4: systemd服务权限问题

**错误信息**:
```
Failed to start ipv6-wireguard-manager.service: Permission denied
```

**解决方案**:
```bash
# 检查服务文件权限
ls -la /etc/systemd/system/ipv6-wireguard-manager.service

# 修复服务文件权限
sudo chown root:root /etc/systemd/system/ipv6-wireguard-manager.service
sudo chmod 644 /etc/systemd/system/ipv6-wireguard-manager.service

# 重新加载systemd配置
sudo systemctl daemon-reload
```

## 🔧 权限修复脚本

### 自动修复脚本
```bash
# 运行权限修复脚本
chmod +x fix_permissions.sh
./fix_permissions.sh
```

**功能**:
- 停止服务
- 检查用户和组
- 修复安装目录权限
- 创建必要的目录
- 修复Python虚拟环境权限
- 修复配置文件权限
- 修复systemd服务文件权限
- 修复CLI工具权限
- 验证权限设置
- 启动服务

### 手动修复步骤

#### 1. 检查当前权限
```bash
# 检查安装目录权限
ls -la /opt/ipv6-wireguard-manager/

# 检查服务用户
id ipv6wgm

# 检查服务文件权限
ls -la /etc/systemd/system/ipv6-wireguard-manager.service
```

#### 2. 创建必要的目录
```bash
# 创建所有必要的目录
sudo mkdir -p /opt/ipv6-wireguard-manager/{uploads,logs,temp,backups,config,data}

# 设置目录权限
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager
```

#### 3. 修复文件权限
```bash
# 设置文件权限
sudo find /opt/ipv6-wireguard-manager -type f -exec chmod 644 {} \;
sudo find /opt/ipv6-wireguard-manager -name "*.py" -exec chmod 755 {} \;
sudo find /opt/ipv6-wireguard-manager -name "*.sh" -exec chmod 755 {} \;
sudo find /opt/ipv6-wireguard-manager/venv/bin -type f -exec chmod 755 {} \;
```

#### 4. 重启服务
```bash
# 重新加载systemd配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 检查状态
sudo systemctl status ipv6-wireguard-manager
```

## 📋 权限检查清单

### 目录权限检查
```bash
# 检查关键目录权限
ls -la /opt/ipv6-wireguard-manager/
ls -la /opt/ipv6-wireguard-manager/uploads/
ls -la /opt/ipv6-wireguard-manager/venv/bin/
```

**期望结果**:
- 所有目录的所有者应该是 `ipv6wgm:ipv6wgm`
- 目录权限应该是 `755` (drwxr-xr-x)
- 文件权限应该是 `644` (-rw-r--r--)
- 可执行文件权限应该是 `755` (-rwxr-xr-x)

### 服务权限检查
```bash
# 检查服务文件权限
ls -la /etc/systemd/system/ipv6-wireguard-manager.service

# 检查CLI工具权限
ls -la /usr/local/bin/ipv6-wireguard-manager
```

**期望结果**:
- 服务文件所有者应该是 `root:root`
- 服务文件权限应该是 `644` (-rw-r--r--)
- CLI工具权限应该是 `755` (-rwxr-xr-x)

### 用户和组检查
```bash
# 检查服务用户
id ipv6wgm

# 检查服务组
getent group ipv6wgm
```

**期望结果**:
- 用户 `ipv6wgm` 应该存在
- 组 `ipv6wgm` 应该存在
- 用户应该是系统用户 (UID < 1000)

## 🚀 预防措施

### 安装时设置正确权限
```bash
# 在安装过程中确保权限正确
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager
```

### 定期权限检查
```bash
# 创建权限检查脚本
cat > check_permissions.sh << 'EOF'
#!/bin/bash
echo "检查IPv6 WireGuard Manager权限..."

# 检查目录权限
echo "目录权限:"
ls -la /opt/ipv6-wireguard-manager/ | head -10

# 检查服务状态
echo "服务状态:"
systemctl is-active ipv6-wireguard-manager

# 检查API连接
echo "API连接:"
curl -f http://localhost:8000/api/v1/health > /dev/null 2>&1 && echo "正常" || echo "失败"
EOF

chmod +x check_permissions.sh
```

## 🔍 调试技巧

### 查看详细错误信息
```bash
# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看系统日志
sudo journalctl -f

# 查看权限错误
sudo journalctl -u ipv6-wireguard-manager | grep -i permission
```

### 测试权限
```bash
# 以服务用户身份测试
sudo -u ipv6wgm ls -la /opt/ipv6-wireguard-manager/uploads/

# 测试目录创建
sudo -u ipv6wgm mkdir -p /opt/ipv6-wireguard-manager/test-dir
sudo -u ipv6wgm rmdir /opt/ipv6-wireguard-manager/test-dir
```

## 📚 相关文档

- [服务故障排除](SERVICE_TROUBLESHOOTING.md)
- [安装指南](INSTALLATION_GUIDE.md)
- [CLI管理工具](CLI_MANAGEMENT_GUIDE.md)

## 🆘 获取帮助

如果权限问题仍然存在：

1. 运行权限修复脚本：`./fix_permissions.sh`
2. 查看详细日志：`sudo journalctl -u ipv6-wireguard-manager -f`
3. 检查系统权限：`ls -la /opt/ipv6-wireguard-manager/`
4. 提交问题到GitHub Issues

---

**权限问题故障排除指南** - 解决所有权限相关问题！🔧
