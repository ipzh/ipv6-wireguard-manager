"""
统一API路由管理器
集中管理所有API端点，确保路径一致性
"""

from typing import Dict, List, Callable, Any
from fastapi import APIRouter, Depends
from functools import wraps
import inspect

class APIEndpoint:
    """API端点定义"""
    def __init__(
        self,
        path: str,
        method: str,
        handler: Callable,
        tags: List[str] = None,
        summary: str = None,
        description: str = None,
        deprecated: bool = False,
        include_in_schema: bool = True
    ):
        self.path = path
        self.method = method.upper()
        self.handler = handler
        self.tags = tags or []
        self.summary = summary
        self.description = description
        self.deprecated = deprecated
        self.include_in_schema = include_in_schema

class APIRouterManager:
    """API路由管理器"""
    
    def __init__(self, prefix: str = "/api/v1"):
        self.prefix = prefix
        self.endpoints: Dict[str, List[APIEndpoint]] = {}
        self.router = APIRouter(prefix=prefix)
    
    def register_endpoint(
        self,
        path: str,
        method: str,
        handler: Callable,
        tags: List[str] = None,
        summary: str = None,
        description: str = None,
        deprecated: bool = False,
        include_in_schema: bool = True
    ):
        """注册API端点"""
        endpoint = APIEndpoint(
            path=path,
            method=method,
            handler=handler,
            tags=tags,
            summary=summary,
            description=description,
            deprecated=deprecated,
            include_in_schema=include_in_schema
        )
        
        # 按模块分组
        module_name = handler.__module__.split('.')[-1]
        if module_name not in self.endpoints:
            self.endpoints[module_name] = []
        
        self.endpoints[module_name].append(endpoint)
        
        # 添加到FastAPI路由器
        self._add_to_router(endpoint)
    
    def _add_to_router(self, endpoint: APIEndpoint):
        """将端点添加到FastAPI路由器"""
        # 根据HTTP方法选择相应的装饰器
        if endpoint.method == "GET":
            decorator = self.router.get
        elif endpoint.method == "POST":
            decorator = self.router.post
        elif endpoint.method == "PUT":
            decorator = self.router.put
        elif endpoint.method == "DELETE":
            decorator = self.router.delete
        elif endpoint.method == "PATCH":
            decorator = self.router.patch
        else:
            raise ValueError(f"不支持的HTTP方法: {endpoint.method}")
        
        # 应用装饰器
        decorator(
            endpoint.path,
            tags=endpoint.tags,
            summary=endpoint.summary,
            description=endpoint.description,
            deprecated=endpoint.deprecated,
            include_in_schema=endpoint.include_in_schema
        )(endpoint.handler)
    
    def get_all_endpoints(self) -> Dict[str, List[APIEndpoint]]:
        """获取所有端点"""
        return self.endpoints
    
    def get_endpoints_by_module(self, module: str) -> List[APIEndpoint]:
        """按模块获取端点"""
        return self.endpoints.get(module, [])
    
    def get_endpoint_paths(self) -> List[str]:
        """获取所有端点路径"""
        paths = []
        for module_endpoints in self.endpoints.values():
            for endpoint in module_endpoints:
                paths.append(f"{self.prefix}{endpoint.path}")
        return paths

# 创建全局API路由管理器
api_router_manager = APIRouterManager()

# 装饰器函数，用于简化端点注册
def api_endpoint(
    path: str,
    method: str = "GET",
    tags: List[str] = None,
    summary: str = None,
    description: str = None,
    deprecated: bool = False,
    include_in_schema: bool = True
):
    """API端点装饰器"""
    def decorator(func):
        # 从函数签名中提取参数信息
        sig = inspect.signature(func)
        parameters = list(sig.parameters.values())
        
        # 包装函数，添加依赖注入
        @wraps(func)
        async def wrapper(*args, **kwargs):
            return await func(*args, **kwargs)
        
        # 注册端点
        api_router_manager.register_endpoint(
            path=path,
            method=method,
            handler=wrapper,
            tags=tags,
            summary=summary,
            description=description,
            deprecated=deprecated,
            include_in_schema=include_in_schema
        )
        
        return wrapper
    
    return decorator

# 导出主要组件
__all__ = [
    "APIRouterManager", "api_router_manager",
    "APIEndpoint", "api_endpoint"
]
