# 服务故障排除指南

## 🚨 常见服务问题

### 问题1: 服务启动失败 (exit-code)

**错误信息**:
```
Active: activating (auto-restart) (Result: exit-code)
Process: 17521 ExecStart=... (code=exited, status=1/FAILURE)
```

**原因**: 服务启动时遇到错误，可能是依赖问题、配置问题或端口冲突。

**解决方案**:

#### 方案1: 运行诊断脚本
```bash
# 运行服务诊断脚本
chmod +x diagnose_service.sh
./diagnose_service.sh
```

#### 方案2: 快速修复
```bash
# 运行快速修复脚本
chmod +x quick_fix_service.sh
./quick_fix_service.sh
```

#### 方案3: 手动修复
```bash
# 1. 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 2. 重新安装依赖
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
pip install -r backend/requirements.txt

# 3. 重新创建环境配置
cp .env.example .env

# 4. 重新加载systemd配置
sudo systemctl daemon-reload

# 5. 启动服务
sudo systemctl start ipv6-wireguard-manager
```

### 问题2: 端口占用

**错误信息**:
```
[Errno 98] Address already in use
```

**解决方案**:
```bash
# 检查端口占用
sudo netstat -tlnp | grep :8000
sudo lsof -i :8000

# 杀死占用进程
sudo kill -9 <PID>

# 或更改端口
sudo nano /etc/systemd/system/ipv6-wireguard-manager.service
# 修改 --port 8000 为其他端口
```

### 问题3: Python模块导入错误

**错误信息**:
```
ModuleNotFoundError: No module named 'fastapi'
```

**解决方案**:
```bash
# 重新安装Python依赖
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt
```

### 问题4: 数据库连接失败

**错误信息**:
```
sqlalchemy.exc.OperationalError: (pymysql.err.OperationalError)
```

**解决方案**:
```bash
# 检查数据库服务
sudo systemctl status mysql
sudo systemctl status mariadb

# 测试数据库连接
mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;"

# 重启数据库服务
sudo systemctl restart mysql
sudo systemctl restart mariadb
```

### 问题5: 权限问题

**错误信息**:
```
Permission denied
```

**解决方案**:
```bash
# 设置正确的文件权限
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod +x /opt/ipv6-wireguard-manager/venv/bin/uvicorn
```

## 🔧 诊断工具

### 服务诊断脚本
```bash
# 全面诊断服务问题
chmod +x diagnose_service.sh
./diagnose_service.sh
```

**功能**:
- 检查服务状态和配置
- 验证安装目录和文件
- 测试Python环境和模块
- 检查端口占用和数据库连接
- 显示详细的错误日志

### 快速修复脚本
```bash
# 自动修复常见问题
chmod +x quick_fix_service.sh
./quick_fix_service.sh
```

**功能**:
- 重新安装Python依赖
- 重新创建配置文件
- 重新配置systemd服务
- 自动启动和验证服务

### API服务检查脚本
```bash
# 检查API服务状态
chmod +x check_api_service.sh
./check_api_service.sh
```

**功能**:
- 检查服务运行状态
- 测试API连接
- 显示网络连接信息
- 提供重启选项

## 📋 手动诊断步骤

### 1. 检查服务状态
```bash
# 检查服务是否运行
sudo systemctl is-active ipv6-wireguard-manager

# 检查服务是否启用
sudo systemctl is-enabled ipv6-wireguard-manager

# 查看详细状态
sudo systemctl status ipv6-wireguard-manager
```

### 2. 检查服务日志
```bash
# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看最近的日志
sudo journalctl -u ipv6-wireguard-manager --no-pager -n 50

# 查看错误日志
sudo journalctl -u ipv6-wireguard-manager --no-pager -p err
```

### 3. 检查配置文件
```bash
# 查看服务配置
sudo systemctl cat ipv6-wireguard-manager

# 检查环境配置
cat /opt/ipv6-wireguard-manager/.env

# 检查Python环境
ls -la /opt/ipv6-wireguard-manager/venv/bin/
```

### 4. 测试手动启动
```bash
# 切换到安装目录
cd /opt/ipv6-wireguard-manager

# 激活虚拟环境
source venv/bin/activate

# 测试应用导入
python -c "from backend.app.main import app; print('应用导入成功')"

# 手动启动服务
uvicorn backend.app.main:app --host :: --port 8000
```

### 5. 检查系统资源
```bash
# 检查内存使用
free -h

# 检查磁盘空间
df -h

# 检查CPU使用
top

# 检查网络连接
netstat -tlnp | grep :8000
```

## 🚀 服务管理命令

### 基本操作
```bash
# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 重启服务
sudo systemctl restart ipv6-wireguard-manager

# 重新加载配置
sudo systemctl reload ipv6-wireguard-manager

# 启用服务
sudo systemctl enable ipv6-wireguard-manager

# 禁用服务
sudo systemctl disable ipv6-wireguard-manager
```

### 状态检查
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 检查服务是否运行
sudo systemctl is-active ipv6-wireguard-manager

# 检查服务是否启用
sudo systemctl is-enabled ipv6-wireguard-manager

# 检查服务是否失败
sudo systemctl is-failed ipv6-wireguard-manager
```

### 日志查看
```bash
# 实时查看日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看最近的日志
sudo journalctl -u ipv6-wireguard-manager --no-pager -n 100

# 查看今天的日志
sudo journalctl -u ipv6-wireguard-manager --since today

# 查看错误日志
sudo journalctl -u ipv6-wireguard-manager -p err
```

## 🔍 高级故障排除

### 检查systemd配置
```bash
# 查看服务文件
sudo systemctl cat ipv6-wireguard-manager

# 验证服务文件语法
sudo systemd-analyze verify /etc/systemd/system/ipv6-wireguard-manager.service

# 重新加载systemd配置
sudo systemctl daemon-reload
```

### 检查环境变量
```bash
# 查看服务环境
sudo systemctl show ipv6-wireguard-manager -p Environment

# 测试环境变量
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
env | grep -E "(DATABASE|SECRET|HOST|PORT)"
```

### 检查文件权限
```bash
# 检查安装目录权限
ls -la /opt/ipv6-wireguard-manager/

# 检查服务用户
id ipv6wgm

# 修复权限
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager/
```

## 🆘 紧急恢复

### 如果服务完全无法启动
```bash
# 1. 停止所有相关服务
sudo systemctl stop ipv6-wireguard-manager

# 2. 检查配置文件
sudo systemctl cat ipv6-wireguard-manager

# 3. 检查Python环境
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
python -c "import fastapi; print('FastAPI OK')"

# 4. 手动启动服务测试
uvicorn backend.app.main:app --host :: --port 8000

# 5. 如果手动启动成功，重新配置systemd服务
sudo systemctl daemon-reload
sudo systemctl start ipv6-wireguard-manager
```

### 如果数据库连接失败
```bash
# 1. 检查数据库服务
sudo systemctl status mysql
sudo systemctl status mariadb

# 2. 测试数据库连接
mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;"

# 3. 如果连接失败，重新配置数据库
mysql -u root -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"
```

## 📚 相关文档

- [安装指南](INSTALLATION_GUIDE.md)
- [API服务故障排除](API_SERVICE_TROUBLESHOOTING.md)
- [MySQL安装故障排除](MYSQL_INSTALL_TROUBLESHOOTING.md)
- [生产部署指南](PRODUCTION_DEPLOYMENT_GUIDE.md)

## 🆘 获取帮助

如果问题仍然存在，请：

1. 运行诊断脚本：`./diagnose_service.sh`
2. 运行快速修复：`./quick_fix_service.sh`
3. 查看详细日志：`sudo journalctl -u ipv6-wireguard-manager -f`
4. 提交问题到GitHub Issues
5. 查看社区讨论

---

**服务故障排除指南** - 解决所有服务启动问题！🔧
