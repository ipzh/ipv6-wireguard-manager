# MySQL安装问题故障排除指南

## 🚨 常见问题

### 问题1: Debian 12 MySQL包不可用

**错误信息**:
```
Package mysql-server is not available, but is referred to by another package.
Package mysql-client is not available, but is referred to by another package.
E: Package 'mysql-server' has no installation candidate
E: Package 'mysql-client' has no installation candidate
```

**原因**: Debian 12默认不包含MySQL包，需要使用MariaDB或添加MySQL官方软件源。

**解决方案**:

#### 方案1: 使用MariaDB（推荐）
```bash
# 运行快速修复脚本
./quick_fix_mysql.sh

# 或手动安装
sudo apt-get update
sudo apt-get install -y mariadb-server mariadb-client
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

#### 方案2: 添加MySQL官方软件源
```bash
# 下载MySQL APT配置包
wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb

# 安装配置包
sudo dpkg -i mysql-apt-config_0.8.24-1_all.deb

# 更新包列表
sudo apt-get update

# 安装MySQL
sudo apt-get install -y mysql-server mysql-client
```

### 问题2: 数据库连接失败

**错误信息**:
```
ERROR 1045 (28000): Access denied for user 'ipv6wgm'@'localhost' (using password: YES)
```

**解决方案**:
```bash
# 重置MySQL root密码
sudo mysql -u root
```

```sql
-- 在MySQL命令行中执行
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
EXIT;
```

```bash
# 重新创建用户
mysql -u root -p -e "DROP USER IF EXISTS 'ipv6wgm'@'localhost';"
mysql -u root -p -e "CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'ipv6wgm_password';"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
mysql -u root -p -e "FLUSH PRIVILEGES;"
```

### 问题3: 服务启动失败

**错误信息**:
```
Failed to start mysql.service: Unit mysql.service not found.
```

**解决方案**:
```bash
# 检查服务名称
systemctl list-units --type=service | grep -i mysql
systemctl list-units --type=service | grep -i mariadb

# 启动正确的服务
sudo systemctl start mariadb  # 对于MariaDB
sudo systemctl start mysql    # 对于MySQL

# 启用服务
sudo systemctl enable mariadb
sudo systemctl enable mysql
```

### 问题4: 端口占用

**错误信息**:
```
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock'
```

**解决方案**:
```bash
# 检查端口占用
sudo netstat -tlnp | grep :3306
sudo lsof -i :3306

# 检查MySQL进程
ps aux | grep mysql
ps aux | grep mariadb

# 重启服务
sudo systemctl restart mariadb
sudo systemctl restart mysql
```

## 🔧 修复脚本

### 快速修复脚本
```bash
# 运行快速修复脚本
chmod +x quick_fix_mysql.sh
./quick_fix_mysql.sh
```

### 完整修复脚本
```bash
# 运行完整修复脚本
chmod +x fix_mysql_install.sh
./fix_mysql_install.sh
```

## 📋 手动安装步骤

### 1. 安装MariaDB（推荐）
```bash
# 更新包列表
sudo apt-get update

# 安装MariaDB
sudo apt-get install -y mariadb-server mariadb-client

# 启动服务
sudo systemctl start mariadb
sudo systemctl enable mariadb

# 安全配置
sudo mysql_secure_installation
```

### 2. 配置数据库
```bash
# 登录MySQL
sudo mysql -u root

# 创建数据库和用户
CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'ipv6wgm_password';
GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. 测试连接
```bash
# 测试数据库连接
mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;"

# 测试数据库访问
mysql -u ipv6wgm -pipv6wgm_password ipv6wgm -e "SHOW TABLES;"
```

## 🔍 诊断命令

### 检查服务状态
```bash
# 检查MySQL/MariaDB服务状态
sudo systemctl status mysql
sudo systemctl status mariadb

# 检查服务是否启用
sudo systemctl is-enabled mysql
sudo systemctl is-enabled mariadb
```

### 检查端口监听
```bash
# 检查3306端口
sudo netstat -tlnp | grep :3306
sudo ss -tlnp | grep :3306
```

### 检查进程
```bash
# 检查MySQL进程
ps aux | grep mysql
ps aux | grep mariadb

# 检查进程树
pstree -p | grep mysql
```

### 检查日志
```bash
# 查看系统日志
sudo journalctl -u mysql -f
sudo journalctl -u mariadb -f

# 查看MySQL错误日志
sudo tail -f /var/log/mysql/error.log
sudo tail -f /var/log/mariadb/mariadb.log
```

## 🚀 继续安装

修复MySQL问题后，可以继续运行安装脚本：

```bash
# 跳过依赖和数据库安装步骤
./install.sh --skip-deps --skip-db

# 或重新运行完整安装
./install.sh --type minimal --silent
```

## 📚 相关文档

- [安装指南](INSTALLATION_GUIDE.md)
- [故障排除手册](TROUBLESHOOTING_MANUAL.md)
- [生产部署指南](PRODUCTION_DEPLOYMENT_GUIDE.md)

## 🆘 获取帮助

如果问题仍然存在，请：

1. 运行系统兼容性测试：`./test_system_compatibility.sh`
2. 查看详细日志：`sudo journalctl -u mysql -f`
3. 提交问题到GitHub Issues
4. 查看社区讨论

---

**MySQL安装问题故障排除指南** - 解决所有MySQL安装问题！🔧
