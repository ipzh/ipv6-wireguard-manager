# 后端脚本说明

这个目录包含了IPv6 WireGuard Manager后端的各种实用脚本。

## 脚本列表

### 1. `init_database.py` - 数据库初始化脚本

**功能**: 初始化数据库，支持PostgreSQL和SQLite

**用法**:
```bash
# 在backend目录下运行
python scripts/init_database.py
```

**特性**:
- 自动检测数据库类型（PostgreSQL/SQLite）
- 创建基本表结构
- 插入默认管理员用户
- 支持环境变量配置

### 2. `check_environment.py` - 环境检查脚本

**功能**: 检查Python环境、依赖和数据库连接

**用法**:
```bash
# 在backend目录下运行
python scripts/check_environment.py
```

**检查项目**:
- Python版本（需要3.8+）
- 虚拟环境状态
- 核心依赖包
- 环境变量文件
- 数据库连接

### 3. `start_server.py` - 服务器启动脚本

**功能**: 简化的服务器启动脚本，用于测试和开发

**用法**:
```bash
# 在backend目录下运行
python scripts/start_server.py
```

**特性**:
- 自动加载.env文件
- 支持调试模式
- 显示启动信息
- 优雅的错误处理

## 环境变量

这些脚本支持以下环境变量：

```bash
# 数据库配置
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
# 或
DATABASE_URL=sqlite:///./ipv6wgm.db

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
DEBUG=false
LOG_LEVEL=info

# 安全配置
SECRET_KEY=your-secret-key
ACCESS_TOKEN_EXPIRE_MINUTES=10080
```

## 快速开始

1. **创建虚拟环境**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # 或
   venv\Scripts\activate     # Windows
   ```

2. **安装依赖**:
   ```bash
   pip install -r requirements-minimal.txt
   ```

3. **初始化数据库**:
   ```bash
   python scripts/init_database.py
   ```

4. **检查环境**:
   ```bash
   python scripts/check_environment.py
   ```

5. **启动服务器**:
   ```bash
   python scripts/start_server.py
   ```

## 故障排除

### 常见问题

1. **缺少依赖包**:
   ```bash
   pip install -r requirements-minimal.txt
   ```

2. **数据库连接失败**:
   - 检查DATABASE_URL环境变量
   - 确保数据库服务正在运行
   - 检查网络连接和防火墙设置

3. **权限问题**:
   ```bash
   chmod +x scripts/*.py
   ```

4. **虚拟环境问题**:
   ```bash
   # 重新创建虚拟环境
   rm -rf venv
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements-minimal.txt
   ```

### 日志和调试

- 设置`DEBUG=true`启用调试模式
- 设置`LOG_LEVEL=debug`获取详细日志
- 查看服务器启动日志了解错误信息

## 默认账户

数据库初始化后会创建默认管理员账户：

- **用户名**: admin
- **密码**: admin123
- **邮箱**: admin@example.com

**注意**: 生产环境中请立即修改默认密码！
