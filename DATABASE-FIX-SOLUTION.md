# VPS数据库问题解决方案

## 问题分析

根据调试脚本的执行结果，发现了以下关键问题：

### 1. 主要错误
- **PostgreSQL权限问题**: `permission denied for schema public`
- **异步数据库引擎不可用**: 配置了PostgreSQL但asyncpg驱动有问题
- **配置冲突**: 服务配置使用PostgreSQL，但应用配置使用SQLite

### 2. 错误详情
```
sqlalchemy.exc.ProgrammingError: (sqlalchemy.dialects.postgresql.asyncpg.ProgrammingError) 
<class 'asyncpg.exceptions.InsufficientPrivilegeError'>: permission denied for schema public
[SQL: CREATE TYPE sessionstatus AS ENUM ('ESTABLISHED', 'IDLE', 'CONNECT', 'ACTIVE', 'OPENSENT', 'OPENCONFIRM', 'UNKNOWN')]
```

## 解决方案

### 方案一：使用SQLite模式（推荐）

对于大多数VPS部署，使用SQLite模式更简单可靠：

#### 1. 运行修复脚本
```bash
# 在VPS上运行
chmod +x fix-vps-database.sh
./fix-vps-database.sh
```

#### 2. 手动修复步骤
1. **更新服务配置**: 将数据库URL改为SQLite
2. **创建环境文件**: 配置SQLite数据库路径
3. **重启服务**: 重新加载配置

### 方案二：修复PostgreSQL权限

如果必须使用PostgreSQL：

#### 1. 授予数据库权限
```sql
# 连接到PostgreSQL
sudo -u postgres psql

# 授予权限
GRANT ALL ON SCHEMA public TO ipv6wgm;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ipv6wgm;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ipv6wgm;
```

#### 2. 重新创建数据库
```bash
# 删除并重新创建数据库
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ipv6wgm;"
sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;"
```

## 修复脚本功能

### fix-vps-database.sh (Linux/VPS)
- 自动检测PostgreSQL服务状态
- 修复数据库权限问题
- 创建正确的环境配置文件
- 更新系统服务配置
- 测试修复结果

### fix-database.bat (Windows)
- 检测PostgreSQL安装状态
- 配置合适的数据库连接
- 创建环境变量文件
- 测试数据库连接

## 代码修复详情

### 1. 数据库初始化逻辑修复
修改了 `backend/app/core/database.py` 中的 `init_db()` 函数：

```python
async def init_db():
    """初始化数据库"""
    if not async_engine:
        # 如果异步引擎不可用，使用同步引擎
        print("警告: 异步数据库引擎不可用，使用同步模式")
        Base.metadata.create_all(bind=sync_engine)
        return
    
    async with async_engine.begin() as conn:
        # 创建所有表
        await conn.run_sync(Base.metadata.create_all)
```

### 2. 配置优先级
1. **环境变量** > **配置文件** > **默认值**
2. 优先使用SQLite避免PostgreSQL权限问题
3. 提供回退机制确保服务可用性

## 部署建议

### 生产环境
- 使用PostgreSQL（性能更好）
- 确保正确的权限配置
- 配置数据库连接池
- 启用SSL连接

### 开发/测试环境
- 使用SQLite（简单快捷）
- 避免权限配置问题
- 便于快速部署测试

## 验证修复

### 1. 测试数据库连接
```bash
cd backend
source venv/bin/activate
python -c "
from app.core.database import sync_engine
from sqlalchemy import text
try:
    with sync_engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('数据库连接测试成功')
except Exception as e:
    print(f'数据库连接失败: {e}')
"
```

### 2. 测试应用启动
```bash
python -c "
from app.main import app
print('应用导入成功')
"
```

### 3. 检查服务状态
```bash
sudo systemctl status ipv6-wireguard-manager
sudo journalctl -u ipv6-wireguard-manager -f
```

## 常见问题

### Q: 修复后服务仍然无法启动？
A: 检查日志文件，可能是其他依赖问题

### Q: 如何切换回PostgreSQL？
A: 运行修复脚本选择PostgreSQL选项

### Q: 数据库迁移如何处理？
A: 使用Alembic进行数据库迁移

## 总结

通过以上修复方案，可以解决VPS部署中的数据库权限和配置冲突问题。推荐使用SQLite模式进行快速部署，生产环境再考虑切换到PostgreSQL。

修复脚本会自动处理所有配置问题，确保服务能够正常启动和运行。