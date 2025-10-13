# 远程服务器数据库部署指南

## 概述

本文档详细说明如何在远程服务器上部署和配置IPv6 WireGuard Manager的数据库系统。

## 数据库配置选项

### 1. 本地PostgreSQL数据库（推荐）
- 在远程服务器上安装PostgreSQL
- 配置本地连接
- 性能最佳，安全性好

### 2. 远程PostgreSQL数据库
- 连接到另一台服务器的PostgreSQL实例
- 需要网络连接和权限配置
- 适用于分布式部署

### 3. SQLite回退模式
- 使用SQLite作为轻量级替代方案
- 适用于测试环境或资源受限的服务器
- 性能有限，不适合高并发场景

## 部署步骤

### 方案一：本地PostgreSQL部署

#### 1. 安装PostgreSQL

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# CentOS/RHEL
sudo yum install postgresql-server postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### 2. 创建数据库和用户

```bash
# 切换到postgres用户
sudo -u postgres psql

# 创建数据库
CREATE DATABASE ipv6wgm;

# 创建用户
CREATE USER ipv6wgm WITH PASSWORD 'your_secure_password';

# 授予权限
GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;

# 退出
\q
```

#### 3. 配置PostgreSQL

编辑 `/etc/postgresql/*/main/pg_hba.conf`：

```
# 允许本地连接
local   all             all                                     peer

# 允许IPv4本地连接
host    all             all             127.0.0.1/32            md5

# 允许IPv6本地连接
host    all             all             ::1/128                 md5
```

重启PostgreSQL：
```bash
sudo systemctl restart postgresql
```

### 方案二：远程PostgreSQL连接

#### 1. 配置远程PostgreSQL服务器

编辑 `pg_hba.conf`：
```
# 允许远程连接
host    all             all             your_server_ip/32       md5
host    all             all             ::your_server_ip/128     md5
```

编辑 `postgresql.conf`：
```
listen_addresses = 'localhost,your_server_ip'
port = 5432
```

重启PostgreSQL服务。

#### 2. 配置防火墙

```bash
# 开放PostgreSQL端口
sudo ufw allow 5432/tcp
```

#### 3. 测试远程连接

```bash
psql -h your_postgres_server -U ipv6wgm -d ipv6wgm
```

### 方案三：SQLite回退模式

#### 1. 配置环境变量

```bash
export DATABASE_URL="sqlite:///./ipv6wgm.db"
export USE_SQLITE_FALLBACK=true
```

#### 2. 或修改配置文件

创建 `.env` 文件：
```env
DATABASE_URL=sqlite:///./ipv6wgm.db
USE_SQLITE_FALLBACK=true
```

## 故障排除

### 常见问题及解决方案

#### 1. 连接被拒绝 (Connection refused)

**症状**: `psycopg2.OperationalError: connection to server at "host" port 5432 failed: Connection refused`

**解决方案**:
- 检查PostgreSQL服务是否运行：`sudo systemctl status postgresql`
- 检查监听地址：`sudo netstat -tulpn | grep 5432`
- 检查防火墙设置

#### 2. 认证失败 (Authentication failed)

**症状**: `psycopg2.OperationalError: FATAL: password authentication failed for user "user"`

**解决方案**:
- 检查用户名和密码
- 检查pg_hba.conf中的认证方法
- 重置用户密码：`ALTER USER username WITH PASSWORD 'new_password';`

#### 3. 数据库不存在 (Database does not exist)

**症状**: `psycopg2.OperationalError: FATAL: database "dbname" does not exist`

**解决方案**:
- 创建数据库：`CREATE DATABASE dbname;`
- 检查连接URL中的数据库名称

#### 4. 权限不足 (Permission denied)

**症状**: `psycopg2.OperationalError: permission denied for database "dbname"`

**解决方案**:
- 授予用户权限：`GRANT ALL PRIVILEGES ON DATABASE dbname TO username;`
- 检查用户角色和权限

## 自动化工具

### 1. 数据库配置检查工具

```bash
cd backend
python scripts/check_database_config.py
```

### 2. 远程数据库修复工具

```bash
cd backend
python scripts/fix_remote_database.py
```

### 3. VPS数据库初始化工具

```bash
cd backend
python scripts/init_vps_database.py
```

## 性能优化建议

### PostgreSQL优化

1. **连接池配置**
```python
DATABASE_POOL_SIZE = 20
DATABASE_MAX_OVERFLOW = 30
```

2. **超时设置**
```python
DATABASE_CONNECT_TIMEOUT = 30
DATABASE_STATEMENT_TIMEOUT = 30000
```

3. **数据库参数优化**
```sql
-- 在postgresql.conf中调整
shared_buffers = 256MB
work_mem = 16MB
maintenance_work_mem = 64MB
```

### 监控和日志

1. **启用查询日志**
```sql
log_statement = 'all'
log_duration = on
```

2. **监控工具**
- pg_stat_activity
- pg_stat_statements
- 第三方监控工具如 pgAdmin, Datadog

## 安全建议

1. **使用强密码**
2. **限制网络访问**
3. **定期备份**
4. **更新PostgreSQL版本**
5. **启用SSL连接**

## 备份和恢复

### 备份数据库
```bash
# 使用pg_dump
pg_dump -h host -U username dbname > backup.sql

# 使用pg_dumpall（备份所有数据库）
pg_dumpall -h host -U username > all_backup.sql
```

### 恢复数据库
```bash
# 恢复单个数据库
psql -h host -U username -d dbname < backup.sql

# 恢复所有数据库
psql -h host -U username -f all_backup.sql
```

## 总结

选择适合您环境的数据库部署方案：
- **生产环境**: 本地PostgreSQL
- **测试环境**: SQLite或远程PostgreSQL
- **分布式环境**: 远程PostgreSQL

使用提供的自动化工具来诊断和修复数据库问题，确保系统稳定运行。