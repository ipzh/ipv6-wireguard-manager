# 配置系统迁移指南

## 概述

本项目已统一使用 `unified_config.py` 作为唯一的配置管理系统，逐步废弃 `config_enhanced.py`。

## 迁移状态

### ✅ 已完成迁移
- `backend/app/main.py` - 已更新为使用 `unified_config`
- `backend/app/api/api_v1/endpoints/health.py` - 已使用 `unified_config`
- 所有新功能使用 `unified_config`

### 🔄 待迁移模块
以下模块仍在使用 `config_enhanced`，需要逐步迁移：

1. **数据库相关模块**
   - `backend/app/core/database_manager.py`
   - `backend/app/core/database_enhanced.py`
   - `backend/app/core/database_health.py`

2. **服务模块**
   - `backend/app/services/` 下的所有服务

3. **API端点**
   - 部分API端点仍在使用 `config_enhanced`

## 迁移步骤

### 1. 更新导入语句
```python
# 旧方式
from .core.config_enhanced import settings

# 新方式
from .core.unified_config import settings
```

### 2. 配置字段映射
`unified_config` 包含所有 `config_enhanced` 的字段，但有一些命名差异：

| config_enhanced | unified_config | 说明 |
|----------------|----------------|------|
| `APP_VERSION` | `APP_VERSION` | 版本号 |
| `DATABASE_URL` | `DATABASE_URL` | 数据库URL |
| `SECRET_KEY` | `SECRET_KEY` | 密钥 |
| `DEBUG` | `DEBUG` | 调试模式 |

### 3. 验证配置
迁移后需要验证配置是否正确加载：

```python
from .core.unified_config import settings

# 验证关键配置
print(f"App Version: {settings.APP_VERSION}")
print(f"Database URL: {settings.DATABASE_URL}")
print(f"Debug Mode: {settings.DEBUG}")
```

## 废弃计划

### 第一阶段（当前）
- 新功能使用 `unified_config`
- 修复关键错误
- 更新主要模块

### 第二阶段（1-2周后）
- 迁移所有服务模块
- 更新API端点
- 移除 `config_enhanced` 的引用

### 第三阶段（1个月后）
- 完全移除 `config_enhanced.py`
- 清理相关导入
- 更新文档

## 注意事项

1. **向后兼容性**: 在完全迁移前，两个配置系统会并存
2. **配置验证**: 迁移后需要测试所有配置是否正确加载
3. **环境变量**: 确保环境变量在两个系统中都能正确读取
4. **文档更新**: 更新所有相关文档，移除对 `config_enhanced` 的引用

## 验证清单

- [ ] 所有模块使用 `unified_config`
- [ ] 配置字段正确映射
- [ ] 环境变量正确读取
- [ ] 应用启动正常
- [ ] 所有功能正常工作
- [ ] 文档已更新
