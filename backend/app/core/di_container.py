"""
依赖注入容器
用于管理全局状态和依赖关系
"""
from typing import Any, Dict, Type, TypeVar, Optional, Callable
import threading
from contextlib import contextmanager

T = TypeVar('T')

class DIContainer:
    """依赖注入容器"""
    
    def __init__(self):
        self._services: Dict[str, Any] = {}
        self._factories: Dict[str, Callable] = {}
        self._singletons: Dict[str, Any] = {}
        self._lock = threading.RLock()
    
    def register_singleton(self, name: str, instance: Any) -> None:
        """注册单例实例"""
        with self._lock:
            self._singletons[name] = instance
    
    def register_factory(self, name: str, factory: Callable[[], Any]) -> None:
        """注册工厂函数"""
        with self._lock:
            self._factories[name] = factory
    
    def register_service(self, name: str, service: Any) -> None:
        """注册服务实例"""
        with self._lock:
            self._services[name] = service
    
    def get(self, name: str) -> Any:
        """获取服务实例"""
        with self._lock:
            # 首先检查单例
            if name in self._singletons:
                return self._singletons[name]
            
            # 然后检查工厂函数
            if name in self._factories:
                instance = self._factories[name]()
                # 如果工厂函数返回的是单例，缓存它
                if hasattr(instance, '__singleton__') and instance.__singleton__:
                    self._singletons[name] = instance
                return instance
            
            # 最后检查服务
            if name in self._services:
                return self._services[name]
            
            raise ValueError(f"Service '{name}' not found")
    
    def has(self, name: str) -> bool:
        """检查服务是否存在"""
        with self._lock:
            return name in self._singletons or name in self._factories or name in self._services
    
    def remove(self, name: str) -> None:
        """移除服务"""
        with self._lock:
            self._singletons.pop(name, None)
            self._factories.pop(name, None)
            self._services.pop(name, None)
    
    def clear(self) -> None:
        """清空所有服务"""
        with self._lock:
            self._singletons.clear()
            self._factories.clear()
            self._services.clear()
    
    @contextmanager
    def scoped(self):
        """创建作用域容器"""
        scoped_container = DIContainer()
        try:
            yield scoped_container
        finally:
            scoped_container.clear()

# 全局容器实例
container = DIContainer()

# 便捷函数
def register_singleton(name: str, instance: Any) -> None:
    """注册单例实例"""
    container.register_singleton(name, instance)

def register_factory(name: str, factory: Callable[[], Any]) -> None:
    """注册工厂函数"""
    container.register_factory(name, factory)

def register_service(name: str, service: Any) -> None:
    """注册服务实例"""
    container.register_service(name, service)

def get_service(name: str) -> Any:
    """获取服务实例"""
    return container.get(name)

def has_service(name: str) -> bool:
    """检查服务是否存在"""
    return container.has(name)

def remove_service(name: str) -> None:
    """移除服务"""
    container.remove(name)

def clear_services() -> None:
    """清空所有服务"""
    container.clear()

# 装饰器
def singleton(name: str):
    """单例装饰器"""
    def decorator(cls):
        def factory():
            if not has_service(name):
                instance = cls()
                instance.__singleton__ = True
                register_singleton(name, instance)
            return get_service(name)
        
        register_factory(name, factory)
        return cls
    return decorator

def inject(name: str):
    """依赖注入装饰器"""
    def decorator(func):
        def wrapper(*args, **kwargs):
            service = get_service(name)
            return func(service, *args, **kwargs)
        return wrapper
    return decorator

# 服务名称常量
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

__all__ = [
    "DIContainer", "container",
    "register_singleton", "register_factory", "register_service",
    "get_service", "has_service", "remove_service", "clear_services",
    "singleton", "inject", "ServiceNames"
]
