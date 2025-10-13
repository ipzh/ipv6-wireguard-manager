# 故障排除指南

本文档提供IPv6 WireGuard Manager常见问题的解决方案和故障排除步骤。

## 📋 目录

- [安装问题](#安装问题)
- [服务启动问题](#服务启动问题)
- [网络连接问题](#网络连接问题)
- [数据库问题](#数据库问题)
- [性能问题](#性能问题)
- [安全问题](#安全问题)
- [日志分析](#日志分析)

## 🔧 安装问题

### 问题1: 安装脚本执行失败

**症状**: 安装脚本无法执行或报错

**解决方案**:
```bash
# 检查脚本权限
chmod +x install.sh

# 检查系统兼容性
cat /etc/os-release

# 手动安装依赖
sudo apt update
sudo apt install -y curl wget git python3 python3-pip nodejs npm
```

### 问题2: Python依赖安装失败

**症状**: pip安装依赖时出现错误

**解决方案**:
```bash
# 升级pip
pip install --upgrade pip

# 使用国内镜像
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/

# 清理缓存
pip cache purge
```

### 问题3: Node.js依赖安装失败

**症状**: npm安装依赖时出现错误

**解决方案**:
```bash
# 清理npm缓存
npm cache clean --force

# 删除node_modules重新安装
rm -rf node_modules package-lock.json
npm install

# 使用国内镜像
npm config set registry https://registry.npmmirror.com
```

## 🚀 服务启动问题

### 问题1: 后端服务无法启动

**症状**: FastAPI服务启动失败

**解决方案**:
```bash
# 检查端口占用
sudo netstat -tlnp | grep :8000

# 检查配置文件
cat /opt/ipv6-wireguard-manager/.env

# 手动启动查看错误
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

### 问题2: 数据库连接失败

**症状**: 应用无法连接到数据库

**解决方案**:
```bash
# 检查PostgreSQL状态
sudo systemctl status postgresql

# 检查数据库配置
sudo -u postgres psql -c "SELECT version();"

# 检查连接字符串
echo $DATABASE_URL

# 测试连接
psql $DATABASE_URL -c "SELECT 1;"
```

### 问题3: Redis连接失败

**症状**: 应用无法连接到Redis

**解决方案**:
```bash
# 检查Redis状态
sudo systemctl status redis-server

# 检查Redis配置
redis-cli ping

# 检查连接字符串
echo $REDIS_URL

# 测试连接
redis-cli -u $REDIS_URL ping
```

## 🌐 网络连接问题

### 问题1: IPv6访问显示空白页面

**症状**: 通过IPv6地址访问时显示空白页面

**解决方案**:
```bash
# 检查IPv6地址
ip -6 addr show

# 检查Nginx IPv6配置
grep -E 'listen.*\[::\]' /etc/nginx/sites-available/ipv6-wireguard-manager

# 修复Nginx配置
sudo sed -i 's/listen 80;/listen 80;\n    listen [::]:80;/' /etc/nginx/sites-available/ipv6-wireguard-manager
sudo nginx -t && sudo systemctl reload nginx

# 检查防火墙
sudo ufw status
sudo ufw allow 80/tcp
```

### 问题2: WebSocket连接失败

**症状**: 前端无法建立WebSocket连接

**解决方案**:
```bash
# 检查WebSocket端点
curl -I http://localhost:8000/ws

# 检查Nginx WebSocket代理配置
grep -A 10 "location /ws" /etc/nginx/sites-available/ipv6-wireguard-manager

# 测试WebSocket连接
wscat -c ws://localhost:8000/ws
```

### 问题3: API请求超时

**症状**: API请求响应缓慢或超时

**解决方案**:
```bash
# 检查系统负载
top
htop

# 检查网络延迟
ping -c 4 8.8.8.8

# 检查应用日志
tail -f /var/log/ipv6-wireguard-manager/app.log

# 优化Nginx配置
sudo nano /etc/nginx/nginx.conf
# 增加超时时间
proxy_read_timeout 300s;
proxy_connect_timeout 75s;
```

## 🗄️ 数据库问题

### 问题1: 数据库迁移失败

**症状**: Alembic迁移执行失败

**解决方案**:
```bash
# 检查迁移状态
alembic current

# 查看迁移历史
alembic history

# 手动执行迁移
alembic upgrade head

# 回滚迁移
alembic downgrade -1

# 重新生成迁移
alembic revision --autogenerate -m "fix migration"
```

### 问题2: 数据库连接池耗尽

**症状**: 数据库连接数过多

**解决方案**:
```bash
# 检查连接数
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# 检查最大连接数
sudo -u postgres psql -c "SHOW max_connections;"

# 优化连接池配置
# 在.env文件中调整
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30
```

### 问题3: 数据库性能问题

**症状**: 数据库查询缓慢

**解决方案**:
```bash
# 检查慢查询
sudo -u postgres psql -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# 分析表统计信息
sudo -u postgres psql -c "ANALYZE;"

# 重建索引
sudo -u postgres psql -c "REINDEX DATABASE ipv6_wireguard_manager;"
```

## ⚡ 性能问题

### 问题1: 系统资源使用过高

**症状**: CPU或内存使用率过高

**解决方案**:
```bash
# 检查系统资源
htop
iostat -x 1

# 检查进程资源使用
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10

# 优化应用配置
# 调整worker数量
WORKERS=4

# 启用缓存
REDIS_CACHE_ENABLED=true
```

### 问题2: 前端加载缓慢

**症状**: 前端页面加载速度慢

**解决方案**:
```bash
# 检查静态文件服务
curl -I http://localhost/static/js/app.js

# 启用Gzip压缩
# 在Nginx配置中添加
gzip on;
gzip_types text/css application/javascript application/json;

# 优化前端构建
cd frontend
npm run build
```

### 问题3: API响应缓慢

**症状**: API接口响应时间长

**解决方案**:
```bash
# 检查API响应时间
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8000/api/v1/status

# 分析慢查询
tail -f /var/log/ipv6-wireguard-manager/slow.log

# 优化数据库查询
# 添加索引
CREATE INDEX idx_users_username ON users(username);
```

## 🔒 安全问题

### 问题1: 认证失败

**症状**: 用户无法登录

**解决方案**:
```bash
# 检查JWT配置
echo $SECRET_KEY

# 检查用户数据
sudo -u postgres psql -c "SELECT username, is_active FROM users;"

# 重置用户密码
# 在数据库中更新密码哈希
```

### 问题2: API密钥验证失败

**症状**: API请求被拒绝

**解决方案**:
```bash
# 检查API密钥格式
echo $API_KEY

# 验证API密钥
curl -H "Authorization: Bearer $API_KEY" http://localhost:8000/api/v1/status

# 重新生成API密钥
# 在管理界面重新生成
```

### 问题3: 权限不足

**症状**: 用户无法访问某些功能

**解决方案**:
```bash
# 检查用户角色
sudo -u postgres psql -c "SELECT u.username, r.name FROM users u JOIN user_roles ur ON u.id = ur.user_id JOIN roles r ON ur.role_id = r.id;"

# 更新用户权限
# 在管理界面修改用户角色
```

## 📊 日志分析

### 应用日志

```bash
# 查看应用日志
tail -f /var/log/ipv6-wireguard-manager/app.log

# 查看错误日志
grep "ERROR" /var/log/ipv6-wireguard-manager/app.log

# 查看访问日志
tail -f /var/log/nginx/access.log
```

### 系统日志

```bash
# 查看系统日志
journalctl -u ipv6-wireguard-manager -f

# 查看Nginx日志
tail -f /var/log/nginx/error.log

# 查看数据库日志
tail -f /var/log/postgresql/postgresql-15-main.log
```

### 性能日志

```bash
# 查看性能监控日志
tail -f /var/log/ipv6-wireguard-manager/performance.log

# 分析慢查询日志
grep "slow query" /var/log/ipv6-wireguard-manager/app.log
```

## 🛠️ 常用诊断命令

### 系统诊断

```bash
# 系统信息
uname -a
cat /etc/os-release

# 资源使用
free -h
df -h
top

# 网络状态
ss -tuln
netstat -tlnp
```

### 服务诊断

```bash
# 服务状态
systemctl status ipv6-wireguard-manager
systemctl status nginx
systemctl status postgresql
systemctl status redis-server

# 服务日志
journalctl -u ipv6-wireguard-manager --since "1 hour ago"
```

### 应用诊断

```bash
# 检查应用进程
ps aux | grep uvicorn
ps aux | grep node

# 检查端口监听
lsof -i :8000
lsof -i :80

# 检查文件权限
ls -la /opt/ipv6-wireguard-manager/
```

## 📞 获取帮助

### 自助诊断

1. 查看本文档的相关章节
2. 检查应用日志和系统日志
3. 使用诊断命令收集信息
4. 尝试重启相关服务

### 社区支持

- **GitHub Issues**: 提交问题报告
- **文档**: 查看项目文档
- **讨论**: 参与社区讨论

### 专业支持

如需专业技术支持，请联系：
- 邮箱: support@ipv6-wireguard-manager.com
- 电话: +86-xxx-xxxx-xxxx

## 📝 问题报告模板

提交问题时，请包含以下信息：

```
**问题描述**:
简要描述遇到的问题

**重现步骤**:
1. 执行的操作
2. 期望的结果
3. 实际的结果

**环境信息**:
- 操作系统: 
- Python版本: 
- Node.js版本: 
- 应用版本: 

**日志信息**:
相关的错误日志和系统日志

**已尝试的解决方案**:
列出已经尝试过的解决方法
```

---

希望这个故障排除指南能帮助您解决问题。如果问题仍然存在，请提交详细的Issue报告。
