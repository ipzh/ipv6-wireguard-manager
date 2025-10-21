# 配置系统迁移指南

## 📋 迁移概述

本项目已统一使用 `unified_config.py` 作为主要配置系统，其他配置系统已标记为弃用。

## 🔄 迁移状态

### ✅ 已完成迁移
- `backend/app/main.py` - 使用 `unified_config`
- `backend/app/core/database.py` - 使用 `unified_config`
- `backend/app/core/database_manager.py` - 使用 `unified_config`
- `backend/app/core/database_enhanced.py` - 使用 `unified_config`
- `backend/app/dependencies.py` - 使用 `unified_config`
- `backend/app/core/database_health_enhanced.py` - 使用 `unified_config`
- `backend/app/core/security_enhanced.py` - 使用 `unified_config`
- `backend/migrations/env.py` - 使用 `unified_config`

### ⚠️ 已弃用的配置系统
- `backend/app/core/config_enhanced.py` - 已弃用，请使用 `unified_config.py`
- `backend/app/core/config.py` - 已弃用，请使用 `unified_config.py`
- `backend/app/core/simple_config.py` - 已弃用，请使用 `unified_config.py`

## 🚀 使用指南

### 导入配置
```python
# 新的导入方式
from app.core.unified_config import settings

# 访问配置
database_url = settings.DATABASE_URL
secret_key = settings.SECRET_KEY
```

### 环境变量配置
```bash
# 数据库配置
DATABASE_URL=mysql://ipv6wgm:password@mysql:3306/ipv6wgm

# API配置
SECRET_KEY=your-secret-key-here
API_V1_STR=/api/v1

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

## 📝 配置字段说明

### 基础配置
- `APP_NAME`: 应用名称
- `APP_VERSION`: 应用版本
- `DEBUG`: 调试模式
- `ENVIRONMENT`: 环境类型 (development/testing/staging/production)

### 数据库配置
- `DATABASE_URL`: 数据库连接URL
- `DATABASE_POOL_SIZE`: 连接池大小
- `DATABASE_MAX_OVERFLOW`: 最大溢出连接数
- `DATABASE_CONNECT_TIMEOUT`: 连接超时时间

### API配置
- `API_V1_STR`: API版本前缀
- `SECRET_KEY`: JWT密钥
- `ACCESS_TOKEN_EXPIRE_MINUTES`: 访问令牌过期时间
- `BACKEND_CORS_ORIGINS`: CORS允许的源

### 路径配置
- `INSTALL_DIR`: 安装目录
- `WIREGUARD_CONFIG_DIR`: WireGuard配置目录
- `FRONTEND_DIR`: 前端目录
- `NGINX_CONFIG_DIR`: Nginx配置目录

## 🔧 迁移步骤

### 1. 更新导入语句
```python
# 旧方式
from app.core.config_enhanced import settings

# 新方式
from app.core.unified_config import settings
```

### 2. 检查配置字段
确保使用的配置字段在 `unified_config.py` 中存在，如果不存在，请添加或使用替代字段。

### 3. 更新环境变量
确保 `.env` 文件中的环境变量名称与 `unified_config.py` 中的字段名称一致。

## ⚠️ 注意事项

1. **配置验证**: `unified_config.py` 包含严格的配置验证，请确保配置值符合要求
2. **类型安全**: 使用 Pydantic 进行类型验证，确保配置值的类型正确
3. **环境变量**: 优先使用环境变量，其次使用默认值
4. **向后兼容**: 旧的配置系统仍然可用，但建议尽快迁移

## 🆘 故障排除

### 常见问题

1. **配置字段不存在**
   - 检查字段名称是否正确
   - 确认字段在 `unified_config.py` 中已定义

2. **配置验证失败**
   - 检查配置值的类型和格式
   - 查看验证错误信息

3. **环境变量不生效**
   - 确认环境变量名称正确
   - 检查 `.env` 文件是否被正确加载

## 📞 支持

如果在迁移过程中遇到问题，请：
1. 查看 `unified_config.py` 中的字段定义
2. 检查配置验证规则
3. 参考本文档的故障排除部分

---

**迁移完成时间**: $(date)  
**迁移版本**: 3.1.0  
**迁移状态**: ✅ 主要配置已迁移完成
