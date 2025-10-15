# MySQL数据库迁移总结

## 🎯 迁移目标

根据用户要求，将项目从PostgreSQL/SQLite迁移到MySQL数据库，并支持MySQL的安装和配置。

## 📊 数据库选择说明

### 为什么同时支持多种数据库？

1. **SQLite** - 轻量级，适合开发和测试
2. **PostgreSQL** - 企业级，功能丰富
3. **MySQL** - 广泛使用，性能优秀，易于管理

### MySQL的优势

- **广泛支持**: 大多数云服务商和托管商都支持MySQL
- **性能优秀**: 在高并发场景下表现良好
- **易于管理**: 管理工具丰富，运维简单
- **成本效益**: 开源免费，社区活跃

## 🔧 主要修改内容

### 1. 配置文件修改

**文件**: `backend/app/core/config.py`
- 默认数据库URL改为: `mysql://ipv6wgm:password@localhost:3306/ipv6wgm`
- 保持向后兼容，仍支持PostgreSQL和SQLite

### 2. 数据库连接代码

**文件**: `backend/app/core/database.py`
- 添加MySQL异步驱动支持 (`mysql+aiomysql://`)
- 添加MySQL同步驱动支持 (`mysql://`)
- 配置MySQL连接参数 (字符集、超时等)
- 保持PostgreSQL和SQLite支持

### 3. 安装脚本修改

**文件**: `install.sh`
- 添加MySQL版本参数 (`--mysql VERSION`)
- 修改系统依赖安装，支持MySQL
- 更新数据库配置函数，使用MySQL命令
- 修改环境变量文件生成，使用MySQL URL
- 更新系统服务配置，依赖MySQL服务

### 4. 依赖文件更新

**文件**: `backend/requirements.txt` 和 `backend/requirements-minimal.txt`
- 添加 `pymysql==1.1.0` - MySQL同步驱动
- 添加 `aiomysql==0.2.0` - MySQL异步驱动

### 5. Docker配置更新

**文件**: `docker-compose.yml` 和 `docker-compose.production.yml`
- 将PostgreSQL服务替换为MySQL服务
- 使用MySQL 8.0镜像
- 配置MySQL环境变量和初始化脚本
- 更新服务依赖关系

### 6. 数据库初始化脚本

**文件**: `backend/scripts/init_database_mysql.py`
- 创建新的MySQL专用初始化脚本
- 支持MySQL数据库和用户创建
- 创建基本表结构 (用户表、WireGuard配置表等)
- 插入默认管理员用户

### 7. 环境检查脚本

**文件**: `backend/scripts/check_environment.py`
- 添加MySQL连接检查函数
- 支持MySQL、PostgreSQL、SQLite三种数据库
- 提供相应的安装建议

### 8. 测试脚本更新

**文件**: `test_installation.sh`
- 修改端口检查，从5432改为3306
- 修改服务检查，从postgresql改为mysql
- 更新故障排除建议

### 9. 文档更新

**文件**: `README.md`
- 更新故障排除部分，使用MySQL相关命令
- 修改端口检查命令

## 🔑 SECRET_KEY说明

**关于 `your-secret-key` 是否是随机KEY**:

在配置文件中，`SECRET_KEY` 使用 `secrets.token_urlsafe(32)` 生成，这是**真正的随机密钥**：

```python
SECRET_KEY: str = secrets.token_urlsafe(32)
```

- `secrets.token_urlsafe(32)` 生成32字节的加密安全随机字符串
- 每次应用启动时都会生成新的随机密钥
- 这是安全的做法，符合安全最佳实践

在Docker配置中的 `your-secret-key-here` 只是占位符，实际部署时会替换为随机生成的密钥。

## 📋 支持的安装方式

### 1. 原生安装 (推荐)
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 2. Docker安装
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s docker
```

### 3. 最小化安装
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s minimal
```

## 🗄️ 数据库表结构

MySQL版本包含以下主要表：

1. **users** - 用户表
2. **wireguard_configs** - WireGuard配置表
3. **ipv6_pools** - IPv6地址池表
4. **bgp_sessions** - BGP会话表
5. **monitoring_data** - 监控数据表

## 🔧 连接方法和同步方法

### 异步连接
- **URL格式**: `mysql+aiomysql://user:password@host:port/database`
- **驱动**: `aiomysql`
- **用途**: FastAPI异步操作

### 同步连接
- **URL格式**: `mysql://user:password@host:port/database`
- **驱动**: `pymysql`
- **用途**: Alembic迁移、同步操作

### 连接参数
- **字符集**: `utf8mb4`
- **排序规则**: `utf8mb4_unicode_ci`
- **连接超时**: 30秒
- **连接池**: 20个连接，最大溢出30个

## 🚀 部署建议

### 生产环境
- 使用MySQL 8.0或更高版本
- 配置适当的连接池大小
- 启用二进制日志
- 定期备份数据库

### 开发环境
- 可以使用SQLite进行快速开发
- 使用MySQL进行集成测试

## ✅ 验证方法

1. **安装测试**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/test_installation.sh | bash
   ```

2. **环境检查**:
   ```bash
   cd /opt/ipv6-wireguard-manager/backend
   python scripts/check_environment.py
   ```

3. **数据库连接测试**:
   ```bash
   mysql -u ipv6wgm -p -h localhost ipv6wgm
   ```

## 🎉 迁移完成

所有源代码已成功修改为支持MySQL数据库：

- ✅ 配置文件更新
- ✅ 数据库连接代码修改
- ✅ 安装脚本支持MySQL
- ✅ Docker配置更新
- ✅ 初始化脚本创建
- ✅ 环境检查工具更新
- ✅ 测试脚本修改
- ✅ 文档更新

项目现在完全支持MySQL数据库，同时保持对PostgreSQL和SQLite的向后兼容性。
