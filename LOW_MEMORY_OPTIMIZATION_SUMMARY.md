# 低内存优化总结

## 🎯 优化目标

针对低于2GB内存的系统，对项目进行全面的低内存优化，只保留MySQL数据库，移除PostgreSQL和SQLite支持，并实现智能内存检测和最小安装方式。

## 📊 内存检测逻辑

### 智能推荐算法
- **< 1GB**: 强制最小化安装
- **< 2GB**: 推荐最小化安装（优化MySQL配置）
- **≥ 2GB**: 可选择Docker或原生安装

### 安装选项调整
- **低内存系统**: 只显示最小化安装选项，其他选项标记为"不推荐"
- **高内存系统**: 显示所有安装选项

## 🔧 主要优化内容

### 1. 配置文件优化

**文件**: `backend/app/core/config.py`
- 降低数据库连接池大小: `DATABASE_POOL_SIZE = 10`
- 降低最大溢出连接数: `DATABASE_MAX_OVERFLOW = 15`
- 移除PostgreSQL和SQLite配置
- 仅支持MySQL数据库

### 2. 数据库连接优化

**文件**: `backend/app/core/database.py`
- 移除PostgreSQL和SQLite支持代码
- 仅保留MySQL异步/同步连接
- 优化连接参数配置
- 简化连接逻辑

### 3. 安装脚本优化

**文件**: `install.sh`

#### 内存检测增强
- 智能推荐算法优化
- 低内存系统强制最小化安装
- 安装选项动态调整

#### 最小化安装优化
- 创建 `configure_minimal_mysql_database()` 函数
- MySQL低内存配置优化
- 环境变量优化配置

#### MySQL低内存配置
```ini
[mysqld]
innodb_buffer_pool_size = 64M
innodb_log_buffer_size = 8M
max_connections = 50
thread_cache_size = 4
query_cache_size = 8M
```

### 4. 依赖文件优化

**文件**: `backend/requirements.txt` 和 `backend/requirements-minimal.txt`
- 移除PostgreSQL驱动: `psycopg2-binary`, `asyncpg`
- 移除SQLite相关依赖
- 仅保留MySQL驱动: `pymysql`, `aiomysql`

### 5. Docker配置优化

#### 标准配置 (`docker-compose.yml`)
- Redis内存限制: `--maxmemory 64mb`
- Redis使用profile控制，低内存环境可禁用

#### 低内存配置 (`docker-compose.low-memory.yml`)
- 移除Redis服务
- MySQL内存优化配置
- 容器内存限制
- 工作进程数量限制

#### MySQL低内存配置 (`docker/mysql/low-memory.cnf`)
```ini
innodb_buffer_pool_size = 64M
innodb_log_buffer_size = 8M
max_connections = 50
skip-name-resolve
skip-innodb-doublewrite
```

### 6. 数据库初始化优化

**文件**: `backend/scripts/init_database_mysql.py`
- 移除PostgreSQL和SQLite初始化函数
- 仅保留MySQL初始化逻辑
- 优化错误处理

### 7. 环境检查优化

**文件**: `backend/scripts/check_environment.py`
- 移除PostgreSQL和SQLite检查
- 仅支持MySQL连接检查
- 默认数据库URL改为MySQL

## 🚀 安装方式对比

### 低内存系统 (< 2GB)

| 安装方式 | 内存占用 | 推荐度 | 说明 |
|---------|---------|--------|------|
| 最小化安装 | ~512MB | ⭐⭐⭐⭐⭐ | 强制推荐，MySQL优化配置 |
| Docker安装 | ~2GB+ | ❌ | 不推荐，内存不足 |
| 原生安装 | ~1GB+ | ❌ | 不推荐，内存不足 |

### 高内存系统 (≥ 2GB)

| 安装方式 | 内存占用 | 推荐度 | 说明 |
|---------|---------|--------|------|
| Docker安装 | ~2GB+ | ⭐⭐⭐⭐ | 推荐新手，环境隔离 |
| 原生安装 | ~1GB+ | ⭐⭐⭐⭐⭐ | 推荐VPS，性能最优 |
| 最小化安装 | ~512MB | ⭐⭐⭐ | 适合低配置服务器 |

## 📋 内存优化配置

### MySQL优化配置
```ini
# 低内存优化
innodb_buffer_pool_size = 64M
innodb_log_buffer_size = 8M
innodb_log_file_size = 16M
key_buffer_size = 16M
max_connections = 50
thread_cache_size = 4
query_cache_size = 8M
tmp_table_size = 16M
max_heap_table_size = 16M
sort_buffer_size = 256K
read_buffer_size = 128K
read_rnd_buffer_size = 256K
join_buffer_size = 128K
```

### 应用优化配置
```bash
# 环境变量优化
DATABASE_POOL_SIZE=5
DATABASE_MAX_OVERFLOW=10
MAX_WORKERS=2
```

### Docker容器限制
```yaml
deploy:
  resources:
    limits:
      memory: 512M
    reservations:
      memory: 256M
```

## 🔍 安装流程

### 自动检测安装
```bash
# 一键安装（自动检测内存并选择最佳方式）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 手动选择安装
```bash
# 最小化安装（低内存优化）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s minimal

# Docker安装（低内存优化）
docker-compose -f docker-compose.low-memory.yml up -d
```

## 📊 性能对比

### 内存使用对比

| 组件 | 标准配置 | 低内存优化 | 节省 |
|------|---------|-----------|------|
| MySQL | 256MB | 64MB | 75% |
| 应用服务 | 512MB | 256MB | 50% |
| Redis | 128MB | 禁用 | 100% |
| 总计 | 896MB | 320MB | 64% |

### 功能对比

| 功能 | 标准配置 | 低内存优化 | 说明 |
|------|---------|-----------|------|
| 数据库 | MySQL + Redis | MySQL only | 移除Redis缓存 |
| 连接池 | 20个连接 | 5个连接 | 降低并发 |
| 工作进程 | 4个进程 | 2个进程 | 降低CPU使用 |
| 监控功能 | 完整 | 基础 | 保留核心功能 |

## ✅ 优化完成

所有源代码已成功优化为低内存版本：

- ✅ 配置文件优化（降低连接池大小）
- ✅ 数据库连接代码简化（仅MySQL）
- ✅ 安装脚本智能检测（内存检测）
- ✅ 最小化安装优化（MySQL低内存配置）
- ✅ 依赖文件精简（移除PostgreSQL/SQLite）
- ✅ Docker配置优化（低内存版本）
- ✅ 环境检查简化（仅MySQL）
- ✅ 数据库初始化简化（仅MySQL）

## 🎉 使用建议

### 低内存系统 (< 2GB)
1. 使用最小化安装方式
2. 系统会自动应用MySQL低内存配置
3. 禁用不必要的服务（如Redis）
4. 监控系统资源使用情况

### 高内存系统 (≥ 2GB)
1. 可选择Docker或原生安装
2. 使用标准配置获得最佳性能
3. 可启用Redis缓存提升性能
4. 支持更多并发连接

项目现在完全针对低内存系统进行了优化，同时保持对高内存系统的兼容性。
