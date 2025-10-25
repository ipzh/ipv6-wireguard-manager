# MySQL UTF-8 Encoding Fix

## 问题描述

在安装过程中，数据库连接失败并出现以下错误：

```
Database connection failed: 'latin-1' codec can't encode characters in position 21-34: ordinal not in range(256)
```

这是一个经典的字符编码问题：
- MySQL/MariaDB默认连接使用 `latin-1` 编码
- 当数据（如中文字符）无法在 `latin-1` 中编码时，连接失败
- 需要强制所有MySQL连接使用 `utf8mb4` 编码

## 解决方案

### 1. 核心修改

所有MySQL连接现在强制使用 `utf8mb4` 字符集：

#### 连接URL添加charset参数
所有 `mysql://` URL 自动添加 `?charset=utf8mb4` 参数

#### SQLAlchemy create_engine 添加 connect_args
所有 `create_engine()` 调用添加 `connect_args={"charset": "utf8mb4"}`

#### PyMySQL直连添加charset参数
所有 `pymysql.connect()` 调用添加 `charset='utf8mb4'` 参数

### 2. 修改的文件

#### Backend核心文件
1. **backend/app/core/database_config.py**
   - `get_async_url()`: 添加charset到异步URL
   - `get_sync_url()`: 添加charset到同步URL

2. **backend/app/core/database_enhanced.py**
   - 异步引擎创建：URL添加charset + connect_args
   - 同步引擎创建：URL添加charset + connect_args
   - MultiDatabaseManager.add_database()：MySQL引擎添加charset

3. **backend/app/core/database_health.py**
   - `_check_mysql_connection()`: URL添加charset + connect_args
   - `_create_mysql_database()`: URL添加charset + connect_args
   - 数据库创建：使用 `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`

#### 初始化脚本
4. **backend/init_database.py**
   - 默认DATABASE_URL添加charset
   - create_engine()添加charset参数

5. **backend/scripts/init_database.py**
   - 默认DATABASE_URL添加charset
   - pymysql.connect()添加charset='utf8mb4'

6. **backend/scripts/init_database_mysql.py**
   - 默认DATABASE_URL添加charset
   - pymysql.connect()已有charset='utf8mb4'（无需修改）

7. **backend/scripts/check_environment.py**
   - 默认DATABASE_URL添加charset
   - pymysql.connect()添加charset='utf8mb4'

#### 安装脚本
8. **install.sh**
   - initialize_database_standard()：导出的DATABASE_URL添加charset
   - .env文件生成：DATABASE_URL添加charset
   - 临时init_db_simple.py脚本：URL添加charset + connect_args

#### 检查脚本
9. **scripts/one_click_check.py**
   - check_database_connection()：pymysql.connect()添加charset='utf8mb4'
   - 改进URL解析使用urlparse（更健壮）

### 3. 实施细节

#### URL Charset参数添加逻辑
```python
if "?" not in sync_db_url:
    sync_db_url += "?charset=utf8mb4"
elif "charset=" not in sync_db_url:
    sync_db_url += "&charset=utf8mb4"
```

这确保：
- 如果URL没有查询参数，添加 `?charset=utf8mb4`
- 如果URL有查询参数但没有charset，添加 `&charset=utf8mb4`
- 如果URL已有charset参数，不重复添加

#### SQLAlchemy连接
```python
engine = create_engine(
    sync_db_url,
    pool_size=20,
    max_overflow=30,
    pool_timeout=30,
    pool_recycle=3600,
    pool_pre_ping=True,
    echo=False,
    future=True,
    connect_args={"charset": "utf8mb4"}  # 新增
)
```

#### PyMySQL直连
```python
conn = pymysql.connect(
    host=parsed.hostname,
    port=parsed.port or 3306,
    user=parsed.username,
    password=parsed.password,
    database=db_name,
    charset='utf8mb4'  # 新增
)
```

#### 数据库创建
```python
conn.execute(text(
    f"CREATE DATABASE {db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
))
```

### 4. 验证

修改后，所有MySQL连接将：
1. 使用UTF-8编码（utf8mb4是MySQL的完整UTF-8实现）
2. 支持所有Unicode字符（包括中文、emoji等）
3. 避免 'latin-1' codec 编码错误
4. 确保数据的国际化支持

### 5. 兼容性

- ✅ 向后兼容：已有数据库不受影响
- ✅ 新数据库：自动使用utf8mb4
- ✅ 所有驱动：pymysql、aiomysql均支持
- ✅ MySQL/MariaDB：5.5.3+版本均支持utf8mb4

### 6. 最佳实践

1. **总是明确指定字符集**：不依赖数据库默认设置
2. **使用utf8mb4而非utf8**：utf8mb4是完整的UTF-8，支持4字节字符
3. **URL、连接参数、数据库创建三处一致**：确保端到端UTF-8支持
4. **URL编码密码**：特殊字符密码通过urllib.parse.quote编码

## 测试

安装时应该不再出现编码错误，数据库连接应该成功建立。
