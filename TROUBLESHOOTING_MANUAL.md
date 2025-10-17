# IPv6 WireGuard Manager - 故障排除手册

## 📋 目录

- [常见问题](#常见问题)
- [服务启动问题](#服务启动问题)
- [数据库连接问题](#数据库连接问题)
- [网络访问问题](#网络访问问题)
- [性能问题](#性能问题)
- [安全相关问题](#安全相关问题)
- [日志分析](#日志分析)
- [紧急恢复](#紧急恢复)

## 目录结构说明

### 标准安装目录

```
/opt/ipv6-wireguard-manager/          # 后端安装目录
├── backend/                          # 后端Python代码
├── php-frontend/                     # 前端源码（备份）
├── venv/                             # Python虚拟环境
├── logs/                              # 后端日志
├── config/                            # 配置文件
├── data/                              # 数据文件
└── ...

/var/www/html/                        # 前端Web目录
├── classes/                          # PHP类文件
├── controllers/                       # 控制器
├── views/                            # 视图模板
├── config/                           # 配置文件
├── logs/                              # 前端日志（777权限）
├── assets/                           # 静态资源
├── index.php                         # 主入口文件
└── index_jwt.php                     # JWT版本入口
```

### 权限配置

| 目录/文件 | 所有者 | 权限 | 说明 |
|-----------|--------|------|------|
| `/opt/ipv6-wireguard-manager/` | `ipv6wgm:ipv6wgm` | `755` | 后端安装目录 |
| `/var/www/html/` | `www-data:www-data` | `755` | 前端Web目录 |
| `/var/www/html/logs/` | `www-data:www-data` | `777` | 前端日志目录 |

## 常见问题

### 1. 服务路径错误

**问题描述**: `ExecStart=/tmp/ipv6-wireguard-manager/venv/bin/uvicorn` 路径错误

**解决方案**:

```bash
# 检查当前服务配置
sudo systemctl cat ipv6-wireguard-manager

# 更新服务配置
sudo systemctl edit --full ipv6-wireguard-manager

# 或者重新创建服务配置
sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service

[Service]
Type=exec
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=/opt/ipv6-wireguard-manager
Environment=PATH=/opt/ipv6-wireguard-manager/venv/bin
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 重新加载并启动服务
sudo systemctl daemon-reload
sudo systemctl restart ipv6-wireguard-manager
```

### 2. PHP-FPM服务启动失败

**问题描述**: `Failed to start php-fpm.service: Unit file php-fpm.service not found`

**解决方案**:

```bash
# 检查PHP版本
php --version

# 检查可用的PHP-FPM服务
systemctl list-units --type=service | grep php

# 正确的服务名称通常是 php8.1-fpm 或 php-fpm
sudo systemctl start php8.1-fpm
sudo systemctl enable php8.1-fpm

# 或者
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# 检查服务状态
sudo systemctl status php8.1-fpm
```

**预防措施**:
```bash
# 在安装脚本中添加服务检测
detect_php_fpm_service() {
    local services=("php8.1-fpm" "php8.0-fpm" "php-fpm" "php7.4-fpm")
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^${service}.service"; then
            echo "$service"
            return 0
        fi
    done
    return 1
}
```

### 2. 数据库连接失败

**问题描述**: `ModuleNotFoundError: No module named 'MySQLdb'`

**解决方案**:

```bash
# 安装MySQL客户端库
sudo apt install -y python3-dev libmysqlclient-dev

# 重新安装PyMySQL
pip uninstall pymysql
pip install pymysql

# 或者使用aiomysql
pip install aiomysql

# 检查数据库连接字符串
# 确保使用 mysql+pymysql:// 而不是 mysql://
DATABASE_URL="mysql+pymysql://username:password@localhost:3306/database"
```

### 3. 端口占用问题

**问题描述**: `Address already in use`

**解决方案**:

```bash
# 查找占用端口的进程
sudo netstat -tlnp | grep :8000
sudo lsof -i :8000

# 杀死占用进程
sudo kill -9 <PID>

# 或者更改端口
# 在 .env 文件中修改
SERVER_PORT=8001
```

### 4. 权限问题

**问题描述**: `Permission denied`

**解决方案**:

```bash
# 设置正确的文件权限
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# 设置日志目录权限
sudo mkdir -p /var/log/ipv6-wireguard-manager
sudo chown -R www-data:www-data /var/log/ipv6-wireguard-manager
sudo chmod -R 755 /var/log/ipv6-wireguard-manager
```

## 服务启动问题

### 后端服务无法启动

**检查步骤**:

```bash
# 1. 检查Python环境
python3.11 --version
which python3.11

# 2. 检查虚拟环境
source venv/bin/activate
which python
pip list

# 3. 检查依赖安装
pip install -r backend/requirements.txt

# 4. 检查配置文件
cat .env | grep -E "(DATABASE|SECRET)"

# 5. 测试数据库连接
python -c "
import pymysql
try:
    conn = pymysql.connect(host='localhost', user='ipv6wgm', password='password', database='ipv6wgm')
    print('数据库连接成功')
    conn.close()
except Exception as e:
    print(f'数据库连接失败: {e}')
"

# 6. 手动启动服务
cd backend
uvicorn app.main:app --host :: --port 8000 --reload
```

**常见错误及解决方案**:

```bash
# 错误: ImportError: No module named 'fastapi'
pip install fastapi uvicorn

# 错误: ModuleNotFoundError: No module named 'app'
# 确保在正确的目录下运行
cd /opt/ipv6-wireguard-manager/backend
uvicorn app.main:app --host :: --port 8000

# 错误: PermissionError: [Errno 13] Permission denied
sudo chown -R www-data:www-data /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager
```

### Nginx服务问题

**检查步骤**:

```bash
# 1. 检查Nginx配置
sudo nginx -t

# 2. 检查配置文件语法
sudo nginx -T

# 3. 检查端口监听
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# 4. 检查错误日志
sudo tail -f /var/log/nginx/error.log

# 5. 重启Nginx
sudo systemctl restart nginx
```

**常见配置错误**:

```nginx
# 错误: duplicate listen [::]:80
# 解决: 检查是否有重复的listen指令
server {
    listen 80;
    listen [::]:80;  # 确保没有重复
    # ...
}

# 错误: nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
# 解决: 检查端口占用
sudo lsof -i :80
sudo systemctl stop apache2  # 如果Apache在运行
```

### MySQL服务问题

**检查步骤**:

```bash
# 1. 检查MySQL服务状态
sudo systemctl status mysql

# 2. 检查MySQL进程
ps aux | grep mysql

# 3. 检查MySQL日志
sudo tail -f /var/log/mysql/error.log

# 4. 测试MySQL连接
mysql -u root -p -e "SELECT 1"

# 5. 检查数据库和用户
mysql -u root -p -e "SHOW DATABASES;"
mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
```

**常见问题解决**:

```bash
# 问题: MySQL服务启动失败
sudo systemctl start mysql
sudo systemctl enable mysql

# 问题: 数据库不存在
mysql -u root -p -e "CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 问题: 用户权限不足
mysql -u root -p -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
mysql -u root -p -e "FLUSH PRIVILEGES;"
```

## 数据库连接问题

### 连接超时

**问题诊断**:

```bash
# 1. 检查网络连接
ping localhost
telnet localhost 3306

# 2. 检查MySQL配置
sudo grep -E "(bind-address|port)" /etc/mysql/mysql.conf.d/mysqld.cnf

# 3. 检查防火墙
sudo ufw status
sudo iptables -L

# 4. 检查MySQL用户权限
mysql -u root -p -e "SELECT User, Host FROM mysql.user WHERE User='ipv6wgm';"
```

**解决方案**:

```bash
# 1. 修改MySQL配置允许远程连接
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# 注释掉或修改 bind-address = 127.0.0.1

# 2. 重启MySQL服务
sudo systemctl restart mysql

# 3. 创建远程用户
mysql -u root -p -e "CREATE USER 'ipv6wgm'@'%' IDENTIFIED BY 'password';"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'%';"
mysql -u root -p -e "FLUSH PRIVILEGES;"
```

### 数据库不存在

**解决方案**:

```bash
# 1. 创建数据库
mysql -u root -p -e "CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 2. 初始化数据库结构
python backend/scripts/init_database.py

# 3. 检查表结构
mysql -u ipv6wgm -p ipv6wgm -e "SHOW TABLES;"
```

### 权限问题

**解决方案**:

```bash
# 1. 重新创建用户
mysql -u root -p -e "DROP USER IF EXISTS 'ipv6wgm'@'localhost';"
mysql -u root -p -e "DROP USER IF EXISTS 'ipv6wgm'@'%';"

# 2. 创建新用户
mysql -u root -p -e "CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'secure_password';"
mysql -u root -p -e "CREATE USER 'ipv6wgm'@'%' IDENTIFIED BY 'secure_password';"

# 3. 授权
mysql -u root -p -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'%';"
mysql -u root -p -e "FLUSH PRIVILEGES;"

# 4. 测试连接
mysql -u ipv6wgm -p -e "SELECT 1;"
```

## 网络访问问题

### 前端页面无法访问

**检查步骤**:

```bash
# 1. 检查Nginx状态
sudo systemctl status nginx

# 2. 检查端口监听
sudo netstat -tlnp | grep :80

# 3. 检查防火墙
sudo ufw status
sudo iptables -L

# 4. 检查PHP-FPM
sudo systemctl status php8.1-fpm

# 5. 测试本地访问
curl -I http://localhost/
curl -I http://127.0.0.1/
```

**解决方案**:

```bash
# 1. 重启服务
sudo systemctl restart nginx
sudo systemctl restart php8.1-fpm

# 2. 检查配置文件
sudo nginx -t
sudo cp php-frontend/nginx.conf /etc/nginx/sites-available/ipv6-wireguard-manager

# 3. 启用站点
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 4. 重新加载配置
sudo nginx -s reload
```

### API无法访问

**检查步骤**:

```bash
# 1. 检查后端服务
sudo systemctl status ipv6-wireguard-manager

# 2. 检查端口监听
sudo netstat -tlnp | grep :8000

# 3. 测试API连接
curl -f http://localhost:8000/api/v1/health
curl -f http://localhost:8000/docs

# 4. 检查CORS配置
curl -H "Origin: http://localhost" http://localhost:8000/api/v1/health
```

**解决方案**:

```bash
# 1. 重启后端服务
sudo systemctl restart ipv6-wireguard-manager

# 2. 检查环境变量
cat .env | grep -E "(CORS|HOST|PORT)"

# 3. 修改CORS配置
# 在 .env 文件中添加
BACKEND_CORS_ORIGINS=["http://localhost", "http://your-domain.com"]

# 4. 检查防火墙规则
sudo ufw allow 8000/tcp
```

### IPv6访问问题

**检查步骤**:

```bash
# 1. 检查IPv6支持
ip -6 addr show
ping6 ::1

# 2. 检查Nginx IPv6配置
sudo grep -r "listen.*\[" /etc/nginx/

# 3. 检查后端IPv6绑定
sudo netstat -tlnp | grep :::8000

# 4. 测试IPv6连接
curl -6 http://[::1]:8000/api/v1/health
```

**解决方案**:

```bash
# 1. 启用IPv6支持
# 在Nginx配置中添加
server {
    listen 80;
    listen [::]:80;
    # ...
}

# 2. 修改后端启动参数
# 在systemd服务文件中
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/uvicorn backend.app.main:app --host :: --port 8000

# 3. 重启服务
sudo systemctl restart nginx
sudo systemctl restart ipv6-wireguard-manager
```

## 性能问题

### 响应缓慢

**诊断步骤**:

```bash
# 1. 检查系统资源
htop
free -h
df -h

# 2. 检查数据库性能
mysql -u root -p -e "SHOW PROCESSLIST;"
mysql -u root -p -e "SHOW STATUS LIKE 'Slow_queries';"

# 3. 检查网络延迟
ping localhost
ping your-domain.com

# 4. 检查应用日志
tail -f /var/log/ipv6-wireguard-manager/app.log | grep -i slow
```

**优化方案**:

```bash
# 1. 数据库优化
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# 添加以下配置
[mysqld]
innodb_buffer_pool_size = 1G
query_cache_size = 32M
max_connections = 200

# 2. PHP-FPM优化
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
# 修改以下参数
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20

# 3. Nginx优化
sudo nano /etc/nginx/nginx.conf
# 添加以下配置
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
gzip on;
gzip_types text/plain text/css application/json application/javascript;

# 4. 重启服务
sudo systemctl restart mysql
sudo systemctl restart php8.1-fpm
sudo systemctl restart nginx
```

### 内存不足

**诊断步骤**:

```bash
# 1. 检查内存使用
free -h
cat /proc/meminfo

# 2. 检查进程内存使用
ps aux --sort=-%mem | head -10

# 3. 检查交换空间
swapon -s
```

**解决方案**:

```bash
# 1. 增加交换空间
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 2. 优化MySQL内存使用
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# 减少以下参数
innodb_buffer_pool_size = 512M
query_cache_size = 16M

# 3. 优化PHP-FPM内存使用
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
# 减少以下参数
pm.max_children = 20
pm.max_requests = 500

# 4. 重启服务
sudo systemctl restart mysql
sudo systemctl restart php8.1-fpm
```

## 安全相关问题

### SSL证书问题

**检查步骤**:

```bash
# 1. 检查证书文件
ls -la /etc/ssl/certs/your-domain.com.crt
ls -la /etc/ssl/private/your-domain.com.key

# 2. 检查证书有效期
openssl x509 -in /etc/ssl/certs/your-domain.com.crt -text -noout | grep -A2 "Validity"

# 3. 测试SSL连接
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

**解决方案**:

```bash
# 1. 重新生成证书
sudo certbot --nginx -d your-domain.com

# 2. 检查自动续期
sudo crontab -l | grep certbot

# 3. 手动续期
sudo certbot renew --dry-run
```

### 防火墙问题

**检查步骤**:

```bash
# 1. 检查UFW状态
sudo ufw status verbose

# 2. 检查iptables规则
sudo iptables -L -n

# 3. 检查端口开放情况
sudo netstat -tlnp
```

**解决方案**:

```bash
# 1. 重置防火墙规则
sudo ufw --force reset

# 2. 重新配置防火墙
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 51820/udp
sudo ufw enable

# 3. 检查状态
sudo ufw status verbose
```

## 日志分析

### 应用日志分析

```bash
# 1. 查看错误日志
grep -i error /var/log/ipv6-wireguard-manager/app.log | tail -20

# 2. 查看访问日志
tail -f /var/log/nginx/access.log

# 3. 分析响应时间
awk '{print $NF}' /var/log/nginx/access.log | sort -n | tail -10

# 4. 分析IP访问
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10
```

### 系统日志分析

```bash
# 1. 查看系统日志
sudo journalctl -u ipv6-wireguard-manager -f

# 2. 查看MySQL日志
sudo tail -f /var/log/mysql/error.log

# 3. 查看PHP-FPM日志
sudo tail -f /var/log/php8.1-fpm.log

# 4. 查看Nginx日志
sudo tail -f /var/log/nginx/error.log
```

### 性能日志分析

```bash
# 1. 分析慢查询
sudo tail -f /var/log/mysql/slow.log

# 2. 分析系统负载
sar -u 1 10

# 3. 分析网络流量
iftop

# 4. 分析磁盘IO
iotop
```

## 紧急恢复

### 服务完全无法启动

**紧急恢复步骤**:

```bash
# 1. 停止所有服务
sudo systemctl stop nginx
sudo systemctl stop php8.1-fpm
sudo systemctl stop mysql
sudo systemctl stop ipv6-wireguard-manager

# 2. 检查系统资源
free -h
df -h
ps aux | head -10

# 3. 清理临时文件
sudo rm -rf /tmp/*
sudo systemctl restart systemd-tmpfiles-clean

# 4. 重启系统服务
sudo systemctl restart systemd-resolved
sudo systemctl restart networking

# 5. 逐步启动服务
sudo systemctl start mysql
sleep 10
sudo systemctl start php8.1-fpm
sleep 5
sudo systemctl start nginx
sleep 5
sudo systemctl start ipv6-wireguard-manager

# 6. 检查服务状态
sudo systemctl status mysql php8.1-fpm nginx ipv6-wireguard-manager
```

### 数据库损坏

**恢复步骤**:

```bash
# 1. 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 2. 备份当前数据库
mysqldump -u root -p ipv6wgm > emergency_backup_$(date +%Y%m%d_%H%M%S).sql

# 3. 检查数据库完整性
mysqlcheck -u root -p --check ipv6wgm

# 4. 修复数据库
mysqlcheck -u root -p --repair ipv6wgm

# 5. 如果修复失败，从备份恢复
mysql -u root -p ipv6wgm < backup_20240101.sql

# 6. 重启服务
sudo systemctl start ipv6-wireguard-manager
```

### 配置文件丢失

**恢复步骤**:

```bash
# 1. 从备份恢复配置文件
sudo tar -xzf config_backup_20240101.tar.gz -C /

# 2. 如果没有备份，重新创建配置
sudo cp php-frontend/nginx.conf /etc/nginx/sites-available/ipv6-wireguard-manager
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 3. 重新创建环境变量文件
cp backend/env.example .env
nano .env  # 编辑配置

# 4. 重新创建systemd服务文件
sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null <<EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/opt/ipv6-wireguard-manager
Environment=PATH=/opt/ipv6-wireguard-manager/venv/bin
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/uvicorn backend.app.main:app --host :: --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 5. 重新加载配置
sudo systemctl daemon-reload
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl restart ipv6-wireguard-manager
```

### 完全重新安装

**重新安装步骤**:

```bash
# 1. 停止所有服务
sudo systemctl stop nginx php8.1-fpm mysql ipv6-wireguard-manager

# 2. 备份重要数据
mysqldump -u root -p ipv6wgm > data_backup_$(date +%Y%m%d).sql
sudo tar -czf config_backup_$(date +%Y%m%d).tar.gz /etc/nginx/ /etc/php/ /etc/mysql/

# 3. 清理旧安装
sudo rm -rf /opt/ipv6-wireguard-manager
sudo rm -rf /var/www/html/*

# 4. 重新运行安装脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 5. 恢复数据
mysql -u ipv6wgm -p ipv6wgm < data_backup_20240101.sql

# 6. 验证安装
curl -f http://localhost/api/v1/health
```

---

**IPv6 WireGuard Manager 故障排除手册** - 完整的问题诊断和解决方案 🛠️

通过本手册，您可以快速诊断和解决IPv6 WireGuard Manager在生产环境中遇到的各种问题！
