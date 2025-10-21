# 依赖注入容器使用指南

## 概述

IPv6 WireGuard Manager 现在使用依赖注入容器来管理服务依赖关系，这提供了更好的测试性、可维护性和灵活性。

## 核心概念

### 服务类型

1. **单例 (Singleton)**: 整个应用生命周期中只有一个实例
2. **工厂 (Factory)**: 每次请求时创建新实例
3. **服务 (Service)**: 预创建的实例

### 容器功能

- 服务注册和解析
- 作用域管理
- 线程安全
- 装饰器支持

## 快速开始

### 基本导入

```python
from app.core.di_container import (
    DIContainer, container,
    register_singleton, register_factory, register_service,
    get_service, has_service, remove_service,
    singleton, inject, ServiceNames
)
```

### 注册服务

```python
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

## 服务名称常量

```python
class ServiceNames:
    """服务名称常量"""
    CONFIG = "config"
    DATABASE = "database"
    LOGGER = "logger"
    SECURITY = "security"
    PATH_CONFIG = "path_config"
    CACHE = "cache"
    EMAIL = "email"
    MONITORING = "monitoring"
```

## 装饰器使用

### 单例装饰器

```python
@singleton(ServiceNames.CACHE)
class CacheManager:
    def __init__(self):
        self.cache = {}
        print("CacheManager 初始化")
    
    def get(self, key):
        return self.cache.get(key)
    
    def set(self, key, value):
        self.cache[key] = value

# 使用单例
cache1 = get_service(ServiceNames.CACHE)
cache2 = get_service(ServiceNames.CACHE)
# cache1 和 cache2 是同一个实例
```

### 依赖注入装饰器

```python
@inject(ServiceNames.CACHE)
def process_data(cache, data):
    # cache 参数会自动注入
    cached_result = cache.get(data['key'])
    if cached_result:
        return cached_result
    
    # 处理数据
    result = expensive_operation(data)
    cache.set(data['key'], result)
    return result

# 调用时不需要传递 cache 参数
result = process_data({'key': 'test', 'value': 'data'})
```

## 高级用法

### 作用域容器

```python
# 创建作用域容器
with container.scoped() as scoped_container:
    # 在作用域内注册服务
    scoped_container.register_singleton('temp_service', temp_instance)
    
    # 使用作用域服务
    service = scoped_container.get('temp_service')
    
    # 作用域结束时自动清理
```

### 自定义容器

```python
# 创建自定义容器
custom_container = DIContainer()

# 注册服务
custom_container.register_singleton('custom_service', custom_instance)

# 使用服务
service = custom_container.get('custom_service')
```

### 服务移除和清理

```python
# 移除特定服务
remove_service(ServiceNames.CACHE)

# 清空所有服务
clear_services()
```

## 实际应用示例

### 1. 数据库服务

```python
# 注册数据库服务
@singleton(ServiceNames.DATABASE)
class DatabaseManager:
    def __init__(self):
        self.connection = None
        self.connect()
    
    def connect(self):
        config = get_service(ServiceNames.CONFIG)
        self.connection = create_connection(config.DATABASE_URL)
    
    def get_connection(self):
        return self.connection

# 使用数据库服务
@inject(ServiceNames.DATABASE)
def get_user_by_id(db, user_id):
    connection = db.get_connection()
    return connection.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

### 2. 缓存服务

```python
# 注册缓存服务
@singleton(ServiceNames.CACHE)
class RedisCache:
    def __init__(self):
        config = get_service(ServiceNames.CONFIG)
        self.redis_client = redis.Redis.from_url(config.REDIS_URL)
    
    def get(self, key):
        return self.redis_client.get(key)
    
    def set(self, key, value, expire=None):
        return self.redis_client.set(key, value, ex=expire)

# 使用缓存服务
@inject(ServiceNames.CACHE)
def get_cached_data(cache, key):
    cached_data = cache.get(key)
    if cached_data:
        return cached_data
    
    # 从数据库获取数据
    db = get_service(ServiceNames.DATABASE)
    data = db.get_data(key)
    
    # 缓存数据
    cache.set(key, data, expire=3600)
    return data
```

### 3. 邮件服务

```python
# 注册邮件服务
@singleton(ServiceNames.EMAIL)
class EmailService:
    def __init__(self):
        config = get_service(ServiceNames.CONFIG)
        self.smtp_config = {
            'host': config.SMTP_HOST,
            'port': config.SMTP_PORT,
            'user': config.SMTP_USER,
            'password': config.SMTP_PASSWORD
        }
    
    def send_email(self, to, subject, body):
        # 发送邮件逻辑
        pass

# 使用邮件服务
@inject(ServiceNames.EMAIL)
def send_notification(email_service, user_email, message):
    email_service.send_email(
        to=user_email,
        subject="系统通知",
        body=message
    )
```

### 4. 监控服务

```python
# 注册监控服务
@singleton(ServiceNames.MONITORING)
class MonitoringService:
    def __init__(self):
        self.metrics = {}
    
    def record_metric(self, name, value):
        self.metrics[name] = value
    
    def get_metrics(self):
        return self.metrics

# 使用监控服务
@inject(ServiceNames.MONITORING)
def track_api_call(monitoring, endpoint, duration):
    monitoring.record_metric(f"api.{endpoint}.duration", duration)
    monitoring.record_metric(f"api.{endpoint}.count", 1)
```

## 测试支持

### 单元测试

```python
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

def test_service_injection(test_container):
    # 在测试中使用依赖注入
    config = test_container.get('test_config')
    assert config.ENVIRONMENT == 'testing'
    
    db = test_container.get('test_database')
    assert db is not None
```

### 集成测试

```python
@pytest.fixture
def app_with_di():
    # 设置应用依赖
    register_singleton(ServiceNames.CONFIG, test_settings)
    register_singleton(ServiceNames.DATABASE, test_database)
    
    # 创建应用
    app = create_app()
    
    yield app
    
    # 清理
    clear_services()

def test_api_endpoint(app_with_di):
    # 测试 API 端点
    response = app_with_di.test_client().get('/api/users')
    assert response.status_code == 200
```

## 最佳实践

### 1. 服务注册

```python
# 推荐：在应用启动时注册所有服务
def setup_services():
    """设置所有服务"""
    # 注册核心服务
    register_singleton(ServiceNames.CONFIG, settings)
    register_singleton(ServiceNames.LOGGER, get_logger(__name__))
    
    # 注册数据库服务
    register_factory(ServiceNames.DATABASE, create_database_connection)
    
    # 注册业务服务
    register_singleton(ServiceNames.CACHE, CacheManager())
    register_singleton(ServiceNames.EMAIL, EmailService())
    register_singleton(ServiceNames.MONITORING, MonitoringService())

# 在应用启动时调用
setup_services()
```

### 2. 错误处理

```python
def safe_get_service(service_name, default=None):
    """安全获取服务"""
    try:
        return get_service(service_name)
    except ValueError:
        if default is not None:
            return default
        raise ValueError(f"服务 {service_name} 未找到且未提供默认值")

# 使用安全获取
cache = safe_get_service(ServiceNames.CACHE, MockCache())
```

### 3. 服务生命周期管理

```python
class ServiceLifecycleManager:
    def __init__(self):
        self.services = {}
    
    def register_with_lifecycle(self, name, service_class):
        """注册带生命周期的服务"""
        instance = service_class()
        self.services[name] = instance
        register_singleton(name, instance)
    
    def shutdown_all(self):
        """关闭所有服务"""
        for name, service in self.services.items():
            if hasattr(service, 'shutdown'):
                service.shutdown()
        clear_services()
```

### 4. 配置驱动

```python
def setup_services_from_config():
    """从配置设置服务"""
    config = get_service(ServiceNames.CONFIG)
    
    # 根据配置决定服务实现
    if config.USE_REDIS:
        register_singleton(ServiceNames.CACHE, RedisCache())
    else:
        register_singleton(ServiceNames.CACHE, MemoryCache())
    
    # 根据环境设置日志级别
    if config.is_development():
        register_singleton(ServiceNames.LOGGER, get_logger(__name__, level=logging.DEBUG))
    else:
        register_singleton(ServiceNames.LOGGER, get_logger(__name__, level=logging.INFO))
```

## 故障排除

### 常见问题

1. **服务未找到**
   ```python
   # 检查服务是否已注册
   if not has_service(ServiceNames.CACHE):
       print("缓存服务未注册")
       register_singleton(ServiceNames.CACHE, CacheManager())
   ```

2. **循环依赖**
   ```python
   # 避免循环依赖
   # 错误示例
   class ServiceA:
       def __init__(self):
           self.service_b = get_service(ServiceNames.SERVICE_B)
   
   class ServiceB:
       def __init__(self):
           self.service_a = get_service(ServiceNames.SERVICE_A)
   
   # 正确示例：使用延迟加载
   class ServiceA:
       def get_service_b(self):
           return get_service(ServiceNames.SERVICE_B)
   ```

3. **线程安全问题**
   ```python
   # 容器本身是线程安全的，但服务可能不是
   # 确保服务实现是线程安全的
   import threading
   
   class ThreadSafeService:
       def __init__(self):
           self._lock = threading.Lock()
           self._data = {}
       
       def get(self, key):
           with self._lock:
               return self._data.get(key)
       
       def set(self, key, value):
           with self._lock:
               self._data[key] = value
   ```

### 调试技巧

```python
# 调试服务注册
def debug_services():
    """调试服务注册情况"""
    print("=== 服务调试信息 ===")
    
    # 检查核心服务
    core_services = [
        ServiceNames.CONFIG,
        ServiceNames.DATABASE,
        ServiceNames.LOGGER,
        ServiceNames.CACHE
    ]
    
    for service_name in core_services:
        if has_service(service_name):
            service = get_service(service_name)
            print(f"✅ {service_name}: {type(service).__name__}")
        else:
            print(f"❌ {service_name}: 未注册")

# 监控服务使用
def monitor_service_usage():
    """监控服务使用情况"""
    original_get_service = get_service
    
    def monitored_get_service(name):
        print(f"获取服务: {name}")
        return original_get_service(name)
    
    # 替换原始函数（仅用于调试）
    import app.core.di_container
    app.core.di_container.get_service = monitored_get_service
```

## 性能考虑

### 1. 服务创建开销

```python
# 对于重量级服务，使用单例
@singleton(ServiceNames.DATABASE)
class DatabaseManager:
    def __init__(self):
        # 重量级初始化
        self.connection = create_expensive_connection()

# 对于轻量级服务，可以使用工厂
def create_lightweight_service():
    return LightweightService()

register_factory(ServiceNames.LIGHTWEIGHT, create_lightweight_service)
```

### 2. 内存使用

```python
# 监控内存使用
import psutil
import os

def monitor_memory_usage():
    """监控内存使用情况"""
    process = psutil.Process(os.getpid())
    memory_info = process.memory_info()
    print(f"内存使用: {memory_info.rss / 1024 / 1024:.2f} MB")
```

## 更新日志

### v3.1.0 (2024-10-19)
- ✅ 实现了依赖注入容器
- ✅ 添加了单例和工厂模式支持
- ✅ 提供了装饰器支持
- ✅ 实现了作用域管理
- ✅ 添加了线程安全支持

### 迁移指南

如果你正在从旧版本迁移，请参考 [迁移指南](./MIGRATION_GUIDE.md)。

## 支持

如果你在使用过程中遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查应用日志中的错误信息
3. 参考项目的 GitHub Issues
4. 联系开发团队
