# API服务故障排除指南

## 🚨 常见问题

### 问题1: API服务检查失败

**错误信息**:
```
[ERROR] ✗ API服务异常
[ERROR] 环境检查失败，请检查安装日志
```

**原因**: API服务刚启动，需要时间初始化，或者服务配置有问题。

**解决方案**:

#### 方案1: 等待服务启动
```bash
# 等待30秒后重试
sleep 30
curl -f http://localhost:8000/api/v1/health
```

#### 方案2: 运行API服务修复脚本
```bash
# 运行API服务修复脚本
./fix_api_service.sh
```

#### 方案3: 手动检查服务状态
```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

### 问题2: 服务启动失败

**错误信息**:
```
Failed to start ipv6-wireguard-manager.service: Unit ipv6-wireguard-manager.service failed to load
```

**解决方案**:
```bash
# 检查服务文件
sudo systemctl cat ipv6-wireguard-manager

# 重新加载systemd配置
sudo systemctl daemon-reload

# 重新启动服务
sudo systemctl restart ipv6-wireguard-manager
```

### 问题3: 端口占用

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

### 问题4: Python模块导入错误

**错误信息**:
```
ModuleNotFoundError: No module named 'fastapi'
```

**解决方案**:
```bash
# 重新安装Python依赖
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
pip install -r backend/requirements.txt

# 重启服务
sudo systemctl restart ipv6-wireguard-manager
```

### 问题5: 数据库连接失败

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

## 🔧 修复脚本

### API服务检查脚本
```bash
# 检查API服务状态
chmod +x check_api_service.sh
./check_api_service.sh

# 显示服务日志
./check_api_service.sh --logs

# 显示网络连接
./check_api_service.sh --network

# 重启服务
./check_api_service.sh --restart
```

### API服务修复脚本
```bash
# 运行API服务修复脚本
chmod +x fix_api_service.sh
./fix_api_service.sh
```

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

### 2. 检查端口监听
```bash
# 检查8000端口
sudo netstat -tlnp | grep :8000
sudo ss -tlnp | grep :8000

# 检查80端口
sudo netstat -tlnp | grep :80
```

### 3. 检查进程
```bash
# 检查uvicorn进程
ps aux | grep uvicorn
ps aux | grep ipv6-wireguard

# 检查进程树
pstree -p | grep uvicorn
```

### 4. 检查日志
```bash
# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看最近的日志
sudo journalctl -u ipv6-wireguard-manager --no-pager -n 50

# 查看错误日志
sudo journalctl -u ipv6-wireguard-manager --no-pager -p err
```

### 5. 测试API连接
```bash
# 测试健康检查端点
curl -f http://localhost:8000/api/v1/health

# 测试API文档
curl -f http://localhost:8000/docs

# 测试根路径
curl -f http://localhost:8000/
```

## 🚀 重启服务

### 完全重启
```bash
# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 等待服务完全停止
sleep 5

# 重新加载配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start ipv6-wireguard-manager

# 检查状态
sudo systemctl status ipv6-wireguard-manager
```

### 软重启
```bash
# 重启服务
sudo systemctl restart ipv6-wireguard-manager

# 检查状态
sudo systemctl status ipv6-wireguard-manager
```

## 🔍 配置检查

### 检查服务配置
```bash
# 查看服务文件内容
sudo systemctl cat ipv6-wireguard-manager

# 检查服务文件路径
sudo systemctl show ipv6-wireguard-manager -p FragmentPath
```

### 检查环境配置
```bash
# 检查环境变量文件
cat /opt/ipv6-wireguard-manager/.env

# 检查Python虚拟环境
ls -la /opt/ipv6-wireguard-manager/venv/bin/

# 检查应用文件
ls -la /opt/ipv6-wireguard-manager/backend/app/
```

### 检查权限
```bash
# 检查安装目录权限
ls -la /opt/ipv6-wireguard-manager/

# 检查服务用户
id ipv6wgm

# 检查文件所有者
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager/
```

## 📊 性能监控

### 监控服务资源使用
```bash
# 监控CPU和内存使用
top -p $(pgrep -f uvicorn)

# 监控系统资源
htop

# 监控网络连接
netstat -an | grep :8000
```

### 监控API响应时间
```bash
# 测试API响应时间
time curl -f http://localhost:8000/api/v1/health

# 持续监控
watch -n 5 'curl -s -o /dev/null -w "%{http_code} %{time_total}s" http://localhost:8000/api/v1/health'
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
- [故障排除手册](TROUBLESHOOTING_MANUAL.md)
- [生产部署指南](PRODUCTION_DEPLOYMENT_GUIDE.md)
- [MySQL安装故障排除](MYSQL_INSTALL_TROUBLESHOOTING.md)

## 🆘 获取帮助

如果问题仍然存在，请：

1. 运行API服务检查：`./check_api_service.sh`
2. 运行API服务修复：`./fix_api_service.sh`
3. 查看详细日志：`sudo journalctl -u ipv6-wireguard-manager -f`
4. 提交问题到GitHub Issues
5. 查看社区讨论

---

**API服务故障排除指南** - 解决所有API服务问题！🔧
