# 后端配置管理指南

## 概述

本文档介绍 IPv6 WireGuard Manager 后端的新配置管理系统，包括统一配置、路径管理和依赖注入。

## 快速开始

### 基本导入

```python
# 导入统一配置
from app.core.unified_config import settings

# 导入路径配置工厂函数（推荐）
from app.core.path_config import create_path_config

# 导入依赖注入容器（推荐）
from app.core.di_container import register_singleton, get_service, ServiceNames
```

### 使用统一配置

```python
# 访问配置值
print(f"应用名称: {settings.APP_NAME}")
print(f"API 版本: {settings.API_V1_STR}")
print(f"服务器端口: {settings.SERVER_PORT}")
print(f"数据库 URL: {settings.DATABASE_URL}")

# 环境检查
if settings.is_development():
    print("运行在开发环境")
elif settings.is_production():
    print("运行在生产环境")
```

## 路径配置管理

### 使用工厂函数（推荐）

```python
from app.core.path_config import create_path_config

# 创建路径配置实例
config = create_path_config('/custom/install/dir')

# 获取路径
wireguard_dir = config.get_path('wireguard_config_dir')
frontend_dir = config.get_path('frontend_dir')

# 确保路径存在
config.ensure_path_exists('wireguard_config_dir')

# 验证所有路径
validation_result = config.validate_all_paths()
if not validation_result['valid']:
    print("路径验证失败:", validation_result['errors'])
```

### 便捷函数

```python
from app.core.path_config import get_path, ensure_path_exists, validate_paths

# 获取单个路径
wireguard_dir = get_path('wireguard_config_dir', '/custom/install/dir')

# 确保路径存在
ensure_path_exists('wireguard_config_dir', '/custom/install/dir')

# 验证路径
validation_result = validate_paths('/custom/install/dir')
```

### 路径配置类

```python
from app.core.path_config import PathConfig

# 创建自定义路径配置
config = PathConfig('/custom/install/dir')

# 获取所有路径信息
all_paths = config.get_all_paths()
print("所有路径:", all_paths)

# 更新路径
config.update_path('wireguard_config_dir', '/new/wireguard/path')

# 验证路径权限
validation = config.validate_all_paths()
```

## 依赖注入容器

### 注册服务

```python
from app.core.di_container import (
    register_singleton, register_factory, register_service,
    get_service, ServiceNames
)

# 注册单例
register_singleton(ServiceNames.CONFIG, settings)

# 注册工厂函数
def create_database():
    return get_database_connection()

register_factory(ServiceNames.DATABASE, create_database)

# 注册服务实例
logger = get_logger(__name__)
register_service(ServiceNames.LOGGER, logger)
```

### 获取服务

```python
# 获取服务
config = get_service(ServiceNames.CONFIG)
database = get_service(ServiceNames.DATABASE)
logger = get_service(ServiceNames.LOGGER)

# 检查服务是否存在
if has_service(ServiceNames.CACHE):
    cache = get_service(ServiceNames.CACHE)
```

### 使用装饰器

```python
from app.core.di_container import singleton, inject, ServiceNames

# 单例装饰器
@singleton(ServiceNames.CACHE)
class CacheManager:
    def __init__(self):
        self.cache = {}
    
    def get(self, key):
        return self.cache.get(key)
    
    def set(self, key, value):
        self.cache[key] = value

# 依赖注入装饰器
@inject(ServiceNames.CACHE)
def process_data(cache, data):
    # 使用注入的缓存服务
    cached_result = cache.get(data['key'])
    if cached_result:
        return cached_result
    
    # 处理数据
    result = expensive_operation(data)
    cache.set(data['key'], result)
    return result
```

## 环境变量配置

### 环境变量列表

```bash
# 应用配置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.0.0"
DEBUG=false
ENVIRONMENT=production

# 路径配置
INSTALL_DIR=/opt/ipv6-wireguard-manager
WIREGUARD_CONFIG_DIR=/etc/wireguard
FRONTEND_DIR=/var/www/html

# API 配置
API_V1_STR=/api/v1
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=11520

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# 数据库配置
DATABASE_URL=mysql://ipv6wgm:password@localhost:3306/ipv6wgm
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=ipv6wgm
DATABASE_PASSWORD=password
DATABASE_NAME=ipv6wgm

# WireGuard 配置
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
WIREGUARD_NETWORK=10.0.0.0/24
WIREGUARD_IPV6_NETWORK=fd00::/64

# 监控配置
ENABLE_METRICS=true
METRICS_PORT=9090
ENABLE_HEALTH_CHECK=true

# 日志配置
LOG_LEVEL=INFO
LOG_FORMAT=json
```

### 配置文件

```python
# .env 文件示例
# 复制 env.template 为 .env 并根据需要修改

# 生产环境配置
ENVIRONMENT=production
DEBUG=false
SECRET_KEY=your-production-secret-key

# 开发环境配置
# ENVIRONMENT=development
# DEBUG=true
# SECRET_KEY=dev-secret-key
```

## 配置验证

### 自动验证

```python
# 配置会自动验证
try:
    from app.core.unified_config import settings
    print("配置验证通过")
except ValueError as e:
    print(f"配置验证失败: {e}")
```

### 手动验证

```python
# 验证特定配置
if len(settings.SECRET_KEY) < 32:
    raise ValueError("SECRET_KEY 长度不足")

if settings.SERVER_PORT < 1 or settings.SERVER_PORT > 65535:
    raise ValueError("SERVER_PORT 必须在 1-65535 范围内")

if settings.ENVIRONMENT not in ['development', 'testing', 'staging', 'production']:
    raise ValueError("ENVIRONMENT 必须是有效的环境类型")
```

## 高级用法

### 作用域容器

```python
from app.core.di_container import DIContainer

# 创建作用域容器
with DIContainer().scoped() as scoped_container:
    # 在作用域内注册服务
    scoped_container.register_singleton('temp_service', temp_instance)
    
    # 使用作用域服务
    service = scoped_container.get('temp_service')
    
    # 作用域结束时自动清理
```

### 配置热重载

```python
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class ConfigReloadHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path.endswith('.env'):
            # 重新加载配置
            os.environ.clear()
            load_dotenv()
            print("配置已重新加载")

# 监控配置文件变化
observer = Observer()
observer.schedule(ConfigReloadHandler(), path='.', recursive=False)
observer.start()
```

### 多环境配置

```python
# config/environments.py
class EnvironmentConfig:
    @staticmethod
    def get_database_url(environment):
        if environment == 'development':
            return 'mysql://dev:dev@localhost:3306/ipv6wgm_dev'
        elif environment == 'testing':
            return 'mysql://test:test@localhost:3306/ipv6wgm_test'
        elif environment == 'production':
            return 'mysql://prod:prod@localhost:3306/ipv6wgm_prod'
        else:
            raise ValueError(f"未知环境: {environment}")

# 使用环境特定配置
db_url = EnvironmentConfig.get_database_url(settings.ENVIRONMENT)
```

## 最佳实践

### 1. 配置管理

```python
# 推荐：使用依赖注入
from app.core.di_container import register_singleton, get_service, ServiceNames

# 在应用启动时注册配置
register_singleton(ServiceNames.CONFIG, settings)

# 在需要的地方获取配置
def get_database_config():
    config = get_service(ServiceNames.CONFIG)
    return {
        'url': config.DATABASE_URL,
        'pool_size': config.DATABASE_POOL_SIZE,
        'max_overflow': config.DATABASE_MAX_OVERFLOW
    }
```

### 2. 路径管理

```python
# 推荐：使用工厂函数而不是全局实例
from app.core.path_config import create_path_config

def setup_wireguard():
    # 为每个操作创建新的配置实例
    config = create_path_config()
    
    # 确保 WireGuard 配置目录存在
    config.ensure_path_exists('wireguard_config_dir')
    
    # 获取配置路径
    wg_dir = config.get_path('wireguard_config_dir')
    return wg_dir
```

### 3. 错误处理

```python
# 配置错误处理
def safe_get_config(key, default=None):
    try:
        return getattr(settings, key)
    except AttributeError:
        if default is not None:
            return default
        raise ValueError(f"配置项 {key} 不存在且未提供默认值")

# 路径错误处理
def safe_get_path(path_name, install_dir=None):
    try:
        config = create_path_config(install_dir)
        return config.get_path(path_name)
    except Exception as e:
        logger.error(f"获取路径失败 {path_name}: {e}")
        return None
```

### 4. 测试支持

```python
# 测试环境配置
import pytest
from app.core.di_container import DIContainer

@pytest.fixture
def test_container():
    container = DIContainer()
    
    # 注册测试服务
    container.register_singleton('test_config', test_settings)
    container.register_factory('test_database', create_test_db)
    
    yield container
    
    # 清理
    container.clear()

def test_with_injection(test_container):
    # 在测试中使用依赖注入
    config = test_container.get('test_config')
    assert config.ENVIRONMENT == 'testing'
```

## 故障排除

### 常见问题

1. **配置加载失败**
   ```python
   # 检查环境变量
   import os
   print("环境变量:", os.environ.get('SECRET_KEY'))
   
   # 检查 .env 文件
   from dotenv import load_dotenv
   load_dotenv()
   ```

2. **路径权限问题**
   ```python
   # 检查路径权限
   import os
   path = '/etc/wireguard'
   if os.path.exists(path):
       print(f"路径存在: {path}")
       print(f"可读: {os.access(path, os.R_OK)}")
       print(f"可写: {os.access(path, os.W_OK)}")
   ```

3. **依赖注入问题**
   ```python
   # 检查服务注册
   from app.core.di_container import has_service, get_service
   
   if has_service('config'):
       config = get_service('config')
   else:
       print("配置服务未注册")
   ```

### 调试技巧

```python
# 启用详细日志
import logging
logging.basicConfig(level=logging.DEBUG)

# 打印配置信息
def debug_config():
    print("=== 配置调试信息 ===")
    print(f"环境: {settings.ENVIRONMENT}")
    print(f"调试模式: {settings.DEBUG}")
    print(f"安装目录: {settings.INSTALL_DIR}")
    print(f"数据库 URL: {settings.DATABASE_URL}")
    
    # 验证路径
    config = create_path_config()
    validation = config.validate_all_paths()
    print(f"路径验证: {validation['valid']}")
    if not validation['valid']:
        print(f"错误: {validation['errors']}")
```

## 更新日志

### v3.0.0 (2024-10-19)
- ✅ 创建了统一配置管理系统
- ✅ 添加了路径配置工厂函数
- ✅ 实现了依赖注入容器
- ✅ 改进了配置验证机制
- ✅ 简化了配置管理复杂性

### 迁移指南

如果你正在从旧版本迁移，请参考 [迁移指南](./MIGRATION_GUIDE.md)。

## 支持

如果你在使用过程中遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查应用日志中的错误信息
3. 参考项目的 GitHub Issues
4. 联系开发团队
