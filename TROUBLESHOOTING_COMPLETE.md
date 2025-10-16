# 完整故障排除指南

## 🚨 服务状态问题诊断

根据您提供的服务状态信息：
```
Active: activating (auto-restart) (Result: exit-code)
Process: 17521 ExecStart=... (code=exited, status=1/FAILURE)
```

这表明服务启动失败并不断重启。以下是完整的解决方案：

## 🔧 立即解决方案

### 方案1: 使用诊断脚本（推荐）
```bash
# 在Linux服务器上运行
chmod +x diagnose_service.sh
./diagnose_service.sh
```

### 方案2: 使用快速修复脚本
```bash
# 在Linux服务器上运行
chmod +x quick_fix_service.sh
./quick_fix_service.sh
```

### 方案3: 手动修复步骤
```bash
# 1. 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 2. 查看详细错误日志
sudo journalctl -u ipv6-wireguard-manager --no-pager -n 50

# 3. 重新安装Python依赖
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt

# 4. 重新创建环境配置
cp .env.example .env

# 5. 重新加载systemd配置
sudo systemctl daemon-reload

# 6. 启动服务
sudo systemctl start ipv6-wireguard-manager

# 7. 检查状态
sudo systemctl status ipv6-wireguard-manager
```

## 📋 可用工具列表

### 诊断工具
| 脚本 | 功能 | 使用方法 |
|------|------|----------|
| `diagnose_service.sh` | 全面诊断服务问题 | `./diagnose_service.sh` |
| `check_api_service.sh` | 检查API服务状态 | `./check_api_service.sh` |
| `test_system_compatibility.sh` | 测试系统兼容性 | `./test_system_compatibility.sh` |
| `verify_installation.sh` | 验证安装完整性 | `./verify_installation.sh` |

### 修复工具
| 脚本 | 功能 | 使用方法 |
|------|------|----------|
| `quick_fix_service.sh` | 快速修复服务问题 | `./quick_fix_service.sh` |
| `fix_api_service.sh` | 修复API服务问题 | `./fix_api_service.sh` |
| `fix_php_fpm.sh` | 修复PHP-FPM问题 | `./fix_php_fpm.sh` |
| `quick_fix_mysql.sh` | 快速修复MySQL问题 | `./quick_fix_mysql.sh` |
| `fix_mysql_install.sh` | 修复MySQL安装问题 | `./fix_mysql_install.sh` |

### 权限设置
| 文件 | 功能 | 使用方法 |
|------|------|----------|
| `setup_scripts.bat` | Windows环境权限设置 | 双击运行 |
| 手动设置 | Linux环境权限设置 | `chmod +x *.sh` |

## 🔍 常见问题及解决方案

### 1. 服务启动失败 (exit-code)
**症状**: 服务不断重启，状态显示 `activating (auto-restart)`
**原因**: 通常是Python依赖、配置或端口问题
**解决**: 运行 `./quick_fix_service.sh`

### 2. API服务检查失败
**症状**: 安装时显示 `✗ API服务异常`
**原因**: 服务刚启动，需要时间初始化
**解决**: 运行 `./check_api_service.sh` 或等待30秒

### 3. MySQL安装失败
**症状**: `E: Package 'mysql-server' has no installation candidate`
**原因**: Debian 12等系统包名变化
**解决**: 运行 `./quick_fix_mysql.sh`

### 4. PHP-FPM启动失败
**症状**: `Failed to start php-fpm.service: Unit file php-fpm.service not found`
**原因**: PHP-FPM服务名不匹配
**解决**: 运行 `./fix_php_fpm.sh`

### 5. 端口占用
**症状**: `[Errno 98] Address already in use`
**原因**: 端口8000被其他进程占用
**解决**: 检查并杀死占用进程

## 📊 诊断流程

### 第一步: 基础检查
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager --no-pager -n 20
```

### 第二步: 运行诊断脚本
```bash
# 全面诊断
./diagnose_service.sh
```

### 第三步: 根据诊断结果修复
```bash
# 如果是依赖问题
./quick_fix_service.sh

# 如果是API问题
./fix_api_service.sh

# 如果是MySQL问题
./quick_fix_mysql.sh

# 如果是PHP问题
./fix_php_fpm.sh
```

### 第四步: 验证修复结果
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 测试API连接
curl -f http://localhost:8000/api/v1/health

# 检查前端访问
curl -f http://localhost/
```

## 🚀 快速命令参考

### 服务管理
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

### 系统检查
```bash
# 检查端口占用
sudo netstat -tlnp | grep :8000

# 检查进程
ps aux | grep uvicorn

# 检查磁盘空间
df -h

# 检查内存使用
free -h
```

### 数据库检查
```bash
# 检查MySQL服务
sudo systemctl status mysql

# 测试数据库连接
mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;"

# 重启数据库
sudo systemctl restart mysql
```

## 📚 详细文档

- [服务故障排除指南](SERVICE_TROUBLESHOOTING.md)
- [API服务故障排除](API_SERVICE_TROUBLESHOOTING.md)
- [MySQL安装故障排除](MYSQL_INSTALL_TROUBLESHOOTING.md)
- [安装指南](INSTALLATION_GUIDE.md)

## 🆘 获取帮助

如果所有方法都无效，请：

1. 运行完整诊断：`./diagnose_service.sh`
2. 查看详细日志：`sudo journalctl -u ipv6-wireguard-manager -f`
3. 检查系统资源：`top`, `df -h`, `free -h`
4. 提交问题到GitHub Issues
5. 查看社区讨论

---

**完整故障排除指南** - 解决所有服务问题！🔧
