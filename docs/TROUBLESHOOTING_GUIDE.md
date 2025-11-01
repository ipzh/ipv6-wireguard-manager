# IPv6 WireGuard Manager - 故障排除指南

## 📋 目录

- [常见问题](#常见问题)
- [安装问题](#安装问题)
- [服务启动问题](#服务启动问题)
- [API 路由问题](#api-路由问题)
- [数据库问题](#数据库问题)
- [认证和安全问题](#认证和安全问题)
- [权限问题](#权限问题)
- [网络问题](#网络问题)
- [日志分析](#日志分析)
- [性能问题](#性能问题)

## 🔍 常见问题

### 问题 1: API 健康检查返回 404

**症状**:
```bash
curl http://localhost:8000/api/v1/health
# 返回: {"detail":"Not Found"}
```

**可能原因**:
1. API 路由未正确注册
2. health endpoint 模块导入失败
3. 路由 prefix 配置错误

**解决方案**:

1. **检查服务日志**:
```bash
sudo journalctl -u ipv6-wireguard-manager --no-pager | grep -E "(注册路由|成功注册|health|HealthCheck)" | tail -30
```

2. **验证路由注册**:
```bash
# 进入项目目录
cd /opt/ipv6-wireguard-manager

# 检查 Python 代码
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager')
try:
    from backend.app.api.api_v1.api import api_router
    print("API Router 路由:")
    for route in api_router.routes:
        if 'health' in route.path.lower():
            print(f"  ✓ {route.path} - {route.methods}")
except Exception as e:
    print(f"❌ 导入失败: {e}")
    import traceback
    traceback.print_exc()
EOF
```

3. **测试多个健康检查端点**:
```bash
# 测试主端点
curl http://localhost:8000/api/v1/health

# 测试备用端点
curl http://localhost:8000/health

# 测试根路径
curl http://localhost:8000/api/v1/
```

4. **重启服务**:
```bash
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl status ipv6-wireguard-manager
```

### 问题 2: 服务启动失败 - 权限错误

**症状**:
```
PermissionError: Cannot access WireGuard config directory: /etc/wireguard
```

**解决方案**:

1. **自动降级方案**（已在代码中实现）:
   - 系统会自动使用 `/tmp/ipv6-wireguard-config` 作为备用目录
   - 检查日志确认降级是否生效

2. **手动修复权限**:
```bash
# 创建 WireGuard 配置目录
sudo mkdir -p /etc/wireguard
sudo chmod 700 /etc/wireguard
sudo chown root:root /etc/wireguard

# 或者使用临时目录（推荐用于测试）
sudo mkdir -p /tmp/ipv6-wireguard-config
sudo mkdir -p /tmp/ipv6-wireguard-clients
sudo chmod 755 /tmp/ipv6-wireguard-config
sudo chmod 755 /tmp/ipv6-wireguard-clients
```

3. **检查服务配置**:
```bash
# 查看服务配置
sudo systemctl cat ipv6-wireguard-manager

# 检查环境变量
sudo systemctl show ipv6-wireguard-manager | grep -i wireguard
```

### 问题 3: 安装脚本错误 - 未绑定变量

**症状**:
```
install.sh: line X: admin_password: unbound variable
```

**解决方案**:

1. **已修复**: 最新版本的 `install.sh` 已修复此问题
2. **检查脚本版本**:
```bash
grep -n "admin_password=" install.sh | head -5
```

3. **使用正确的作用域**:
   - 确保 `admin_password` 变量在函数外部定义
   - 或者使用 `bash -x install.sh` 调试

### 问题 4: 数据库连接失败

**症状**:
```
ConnectionError: Could not connect to database
OperationalError: (2003, "Can't connect to MySQL server")
```

**解决方案**:

1. **检查数据库服务**:
```bash
# MySQL
sudo systemctl status mysql
sudo systemctl start mysql

# 检查端口
sudo netstat -tulpn | grep 3306
```

2. **验证数据库配置**:
```bash
# 检查环境变量
cat /opt/ipv6-wireguard-manager/.env | grep DATABASE

# 测试连接
mysql -h localhost -u ipv6wgm -p ipv6wgm
```

3. **检查数据库是否存在**:
```bash
mysql -u root -p -e "SHOW DATABASES LIKE 'ipv6wgm';"
```

4. **重新初始化数据库**:
```bash
cd /opt/ipv6-wireguard-manager
python3 backend/init_database.py
```

### 问题 5: API 端口未监听

**症状**:
```
curl: (7) Failed to connect to localhost port 8000
```

**解决方案**:

1. **检查服务状态**:
```bash
sudo systemctl status ipv6-wireguard-manager
```

2. **检查端口占用**:
```bash
sudo netstat -tulpn | grep 8000
sudo lsof -i :8000
```

3. **检查防火墙**:
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 8000/tcp

# CentOS/RHEL
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=8000/tcp --permanent
sudo firewall-cmd --reload
```

4. **查看服务日志**:
```bash
sudo journalctl -u ipv6-wireguard-manager -n 100 --no-pager
```

## 📦 安装问题

### 安装脚本执行失败

**检查清单**:

1. **系统要求**:
   - Python 3.9+ (推荐 3.11)
   - Bash 4.0+
   - curl 或 wget
   - sudo 权限

2. **依赖安装**:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv curl

# CentOS/RHEL
sudo yum install -y python3 python3-pip curl
```

3. **脚本权限**:
```bash
chmod +x install.sh
```

4. **调试模式**:
```bash
bash -x install.sh 2>&1 | tee install_debug.log
```

### 安装后验证失败

**检查步骤**:

1. **检查所有服务**:
```bash
# API 服务
sudo systemctl status ipv6-wireguard-manager

# Nginx
sudo systemctl status nginx

# MySQL
sudo systemctl status mysql

# Redis (如果使用)
sudo systemctl status redis
```

2. **检查配置文件**:
```bash
# 环境变量
ls -la /opt/ipv6-wireguard-manager/.env

# 检查配置有效性
cd /opt/ipv6-wireguard-manager
python3 -c "from backend.app.core.unified_config import settings; print('Config OK')"
```

## 🚀 服务启动问题

### 服务无法启动

**诊断步骤**:

1. **查看详细日志**:
```bash
sudo journalctl -u ipv6-wireguard-manager -n 200 --no-pager
```

2. **检查 Python 环境**:
```bash
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
python3 --version
pip list | grep fastapi
```

3. **手动启动测试**:
```bash
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
uvicorn backend.app.main:app --host :: --port 8000
```

### 服务启动但立即退出

**可能原因**:
- 配置文件错误
- 数据库连接失败
- 权限问题
- 端口被占用

**解决方案**:
```bash
# 检查 systemd 服务配置
sudo systemctl cat ipv6-wireguard-manager

# 检查退出代码
sudo systemctl status ipv6-wireguard-manager
echo $?

# 查看详细错误
sudo journalctl -u ipv6-wireguard-manager --since "5 minutes ago" --no-pager
```

## 🔗 API 路由问题

### 路由未注册

**检查清单**:

1. **验证路由模块**:
```bash
cd /opt/ipv6-wireguard-manager
python3 << 'EOF'
import sys
sys.path.insert(0, '.')
try:
    from backend.app.api.api_v1.endpoints.health import router
    print(f"✓ Health router loaded: {len(router.routes)} routes")
    for route in router.routes:
        print(f"  - {route.path} ({route.methods})")
except Exception as e:
    print(f"❌ Failed: {e}")
    import traceback
    traceback.print_exc()
EOF
```

2. **检查路由注册日志**:
```bash
sudo journalctl -u ipv6-wireguard-manager | grep -i "注册路由\|路由加载" | tail -20
```

3. **验证主应用导入**:
```bash
grep -n "from .api import" backend/app/main_production.py
```

### 路由冲突

**症状**: 某些端点返回 404，但其他端点正常

**解决方案**:
- 检查路由 prefix 配置
- 确保没有重复的路由定义
- 验证路由注册顺序

## 💾 数据库问题

### 数据库连接超时

**解决方案**:

1. **检查网络连接**:
```bash
# 本地数据库
mysql -h localhost -u root -p -e "SELECT 1;"

# 远程数据库
mysql -h <host> -u <user> -p -e "SELECT 1;"
```

2. **检查数据库用户权限**:
```sql
SHOW GRANTS FOR 'ipv6wgm'@'localhost';
```

3. **调整连接超时**:
```python
# 在 .env 中添加
DATABASE_POOL_TIMEOUT=30
DATABASE_POOL_RECYCLE=3600
```

### 数据库迁移失败

**解决方案**:

```bash
cd /opt/ipv6-wireguard-manager/backend

# 检查当前迁移版本
alembic current

# 查看迁移历史
alembic history

# 手动应用迁移
alembic upgrade head

# 如果需要，回退迁移
alembic downgrade -1
```

## 🔐 认证和安全问题

### 问题 1: 登录失败 - 429 Too Many Requests

**症状**:
```json
{
  "detail": "登录尝试次数过多，请5分钟后再试"
}
```

**原因**: 防暴力破解机制触发

**解决方案**:
1. **等待5分钟** - 自动解锁
2. **检查日志** - 确认是否被攻击
```bash
sudo journalctl -u ipv6-wireguard-manager | grep "登录尝试次数过多"
```

3. **配置调整**（如需）:
```python
# backend/app/api/api_v1/endpoints/auth.py
_MAX_LOGIN_ATTEMPTS = 5  # 可调整
_LOGIN_WINDOW_SECONDS = 300  # 可调整
```

### 问题 2: Cookie未设置或不工作

**症状**:
- 登录后浏览器中看不到Cookie
- 后续请求返回401未授权

**诊断步骤**:

1. **检查Cookie标志**:
```bash
# 使用浏览器开发者工具
# Application -> Cookies
# 检查Cookie是否设置了HttpOnly, Secure, SameSite标志
```

2. **检查前端配置**:
```javascript
// 确认axios配置
const apiClient = axios.create({
  withCredentials: true  // 必须设置为true
});

// 确认fetch配置
fetch('/api/v1/endpoint', {
  credentials: 'include'  // 必须设置
});
```

3. **检查API代理**:
```php
// php-frontend/api_proxy.php
// 确认Cookie转发代码存在
$cookieHeaders = [];
foreach ($_COOKIE as $name => $value) {
    $cookieHeaders[] = $name . '=' . urlencode($value);
}
```

4. **检查环境配置**:
```bash
# 开发环境 - secure应该为false（允许HTTP）
# 生产环境 - secure应该为true（强制HTTPS）
```

**解决方案**:
- 开发环境：确保`DEBUG=true`，使用HTTP
- 生产环境：必须使用HTTPS，确保`DEBUG=false`
- 检查CORS配置：确保`Access-Control-Allow-Credentials: true`

### 问题 3: 令牌验证失败 - 401 Unauthorized

**症状**:
```
401 Unauthorized
"Could not validate credentials"
```

**可能原因**:
1. 令牌过期
2. 令牌在黑名单中（已撤销）
3. 令牌格式错误
4. Cookie未正确传递

**诊断步骤**:

1. **检查令牌有效性**:
```bash
# 检查令牌是否在黑名单中
python3 << 'EOF'
from backend.app.core.token_blacklist import is_blacklisted
token = "your_token_here"
if is_blacklisted(token):
    print("令牌在黑名单中")
else:
    print("令牌不在黑名单中")
EOF
```

2. **检查令牌过期时间**:
```python
# 解码JWT查看过期时间
import jwt
token = "your_token_here"
payload = jwt.decode(token, options={"verify_signature": False})
print(f"过期时间: {payload.get('exp')}")
```

3. **检查Cookie传递**:
```bash
# 使用curl测试
curl -v -b cookies.txt http://localhost:8000/api/v1/auth/me
# 查看请求头中是否包含Cookie
```

**解决方案**:
- 刷新令牌：调用`/api/v1/auth/refresh`端点
- 重新登录：如果刷新令牌也过期
- 检查网络：确认Cookie正确传递

### 问题 4: 登出后令牌仍可使用

**症状**:
- 登出后，使用原令牌仍能访问API

**原因**: 令牌未正确加入黑名单

**诊断**:
```bash
# 检查登出日志
sudo journalctl -u ipv6-wireguard-manager | grep "已登出"

# 检查黑名单
python3 << 'EOF'
from backend.app.core.token_blacklist import get_blacklisted_count
print(f"黑名单中的令牌数: {get_blacklisted_count()}")
EOF
```

**解决方案**:
- 检查logout端点是否正确调用`add_to_blacklist`
- 检查黑名单存储是否正常工作
- 生产环境建议使用Redis存储

### 问题 5: 密码验证失败

**症状**:
- 密码正确但无法登录
- 提示"用户名或密码错误"

**可能原因**:
1. 密码哈希算法变更（从pbkdf2_sha256到bcrypt）
2. 密码格式问题

**解决方案**:
1. **重置密码**:
```python
from backend.app.core.security_enhanced import security_manager
hashed = security_manager.get_password_hash("new_password")
# 更新数据库中的密码哈希
```

2. **检查密码哈希格式**:
```bash
# bcrypt哈希格式: $2b$...
# pbkdf2_sha256格式: $pbkdf2-sha256$...
```

3. **迁移现有密码**（如需要）:
- 用户下次登录时自动更新为bcrypt格式
- 或批量重置密码

## 🔒 权限问题

### 文件权限错误

**常见错误**:
- WireGuard 配置文件无法访问
- 日志文件无法写入
- 上传文件权限不足

**解决方案**:

```bash
# 修复项目目录权限
sudo chown -R www-data:www-data /opt/ipv6-wireguard-manager
sudo find /opt/ipv6-wireguard-manager -type d -exec chmod 755 {} \;
sudo find /opt/ipv6-wireguard-manager -type f -exec chmod 644 {} \;

# 修复特定目录权限
sudo chmod -R 755 /opt/ipv6-wireguard-manager/logs
sudo chmod -R 755 /tmp/ipv6-wireguard-config

# WireGuard 配置（如果需要）
sudo chmod 600 /etc/wireguard/*.key
sudo chmod 644 /etc/wireguard/*.conf
```

## 🌐 网络问题

### IPv6 支持问题

**检查**:
```bash
# 检查 IPv6 地址
ip -6 addr show

# 测试 IPv6 连接
ping6 -c 4 ::1

# 检查 WireGuard IPv6
sudo wg show
```

### 防火墙配置

**Ubuntu/Debian**:
```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 51820/udp  # WireGuard
```

**CentOS/RHEL**:
```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --reload
```

## 📊 日志分析

### 查看应用日志

```bash
# 系统日志
sudo journalctl -u ipv6-wireguard-manager -f

# 应用日志（如果存在）
tail -f /opt/ipv6-wireguard-manager/logs/app.log
tail -f /opt/ipv6-wireguard-manager/logs/error.log

# Nginx 日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 日志过滤

```bash
# 仅显示错误
sudo journalctl -u ipv6-wireguard-manager | grep -i error

# 显示最近的路由注册信息
sudo journalctl -u ipv6-wireguard-manager | grep -i "路由\|route"

# 显示数据库相关
sudo journalctl -u ipv6-wireguard-manager | grep -i "database\|mysql"
```

## ⚡ 性能问题

### API 响应慢

**诊断**:
```bash
# 测试响应时间
curl -w "@-" -o /dev/null -s http://localhost:8000/api/v1/health <<'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF
```

**优化建议**:
- 检查数据库查询性能
- 启用 Redis 缓存
- 调整 uvicorn workers 数量
- 检查系统资源使用

### 内存使用过高

**检查**:
```bash
# 查看进程内存
ps aux | grep uvicorn

# 系统内存
free -h

# Python 内存分析
pip install memory-profiler
python3 -m memory_profiler backend/app/main_production.py
```

## 🆘 获取帮助

### 提供诊断信息

如果问题仍然存在，请提供以下信息：

1. **系统信息**:
```bash
uname -a
python3 --version
pip list | grep -E "fastapi|uvicorn|sqlalchemy"
```

2. **服务状态**:
```bash
sudo systemctl status ipv6-wireguard-manager
```

3. **相关日志**:
```bash
sudo journalctl -u ipv6-wireguard-manager --since "1 hour ago" > error_log.txt
```

4. **配置文件**（移除敏感信息）:
```bash
cat /opt/ipv6-wireguard-manager/.env | grep -v PASSWORD
```

---

**最后更新**: 2025-11-01  
**版本**: 3.0.0

