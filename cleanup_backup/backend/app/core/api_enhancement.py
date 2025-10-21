"""
API路径标准化增强实现
基于您的分析，实现自动文档生成、路径验证、性能优化等功能
"""

import re
import time
import json
from typing import Dict, List, Any, Optional, Callable
from functools import wraps
from dataclasses import dataclass
from enum import Enum
import logging

logger = logging.getLogger(__name__)

class HTTPMethod(Enum):
    """HTTP方法枚举"""
    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    DELETE = "DELETE"
    PATCH = "PATCH"
    HEAD = "HEAD"
    OPTIONS = "OPTIONS"

@dataclass
class APIEndpoint:
    """API端点定义"""
    path: str
    method: HTTPMethod
    handler: Callable
    description: str
    tags: List[str]
    parameters: List[Dict[str, Any]]
    responses: Dict[int, Dict[str, Any]]
    deprecated: bool = False
    rate_limit: Optional[int] = None
    cache_ttl: Optional[int] = None

class APIPathValidator:
    """API路径验证器"""
    
    def __init__(self):
        self.path_patterns = {
            'api_version': r'^/api/v\d+$',
            'resource': r'^/api/v\d+/[a-z][a-z0-9-]*$',
            'resource_id': r'^/api/v\d+/[a-z][a-z0-9-]*/\d+$',
            'nested_resource': r'^/api/v\d+/[a-z][a-z0-9-]*/\d+/[a-z][a-z0-9-]*$',
            'action': r'^/api/v\d+/[a-z][a-z0-9-]*/[a-z][a-z0-9-]*$'
        }
    
    def validate_path(self, path: str) -> Dict[str, Any]:
        """验证API路径格式"""
        validation_result = {
            'valid': False,
            'pattern': None,
            'errors': [],
            'suggestions': []
        }
        
        # 检查基本格式
        if not path.startswith('/api/v'):
            validation_result['errors'].append("路径必须以 /api/v 开头")
            validation_result['suggestions'].append("使用格式: /api/v1/resource")
            return validation_result
        
        # 检查版本号
        version_match = re.match(r'^/api/v(\d+)/', path)
        if not version_match:
            validation_result['errors'].append("版本号格式错误")
            validation_result['suggestions'].append("使用格式: /api/v1/")
            return validation_result
        
        version = int(version_match.group(1))
        if version < 1:
            validation_result['errors'].append("版本号必须大于等于1")
            validation_result['suggestions'].append("使用版本号: v1, v2, v3...")
            return validation_result
        
        # 检查路径模式
        for pattern_name, pattern in self.path_patterns.items():
            if re.match(pattern, path):
                validation_result['valid'] = True
                validation_result['pattern'] = pattern_name
                break
        
        if not validation_result['valid']:
            validation_result['errors'].append("路径格式不符合RESTful规范")
            validation_result['suggestions'].extend([
                "资源路径: /api/v1/users",
                "资源ID路径: /api/v1/users/123",
                "嵌套资源: /api/v1/users/123/posts",
                "操作路径: /api/v1/users/search"
            ])
        
        return validation_result
    
    def suggest_path(self, current_path: str) -> List[str]:
        """建议标准化的路径"""
        suggestions = []
        
        # 移除多余斜杠
        clean_path = re.sub(r'/+', '/', current_path)
        if clean_path != current_path:
            suggestions.append(clean_path)
        
        # 转换为小写
        lower_path = current_path.lower()
        if lower_path != current_path:
            suggestions.append(lower_path)
        
        # 添加版本号
        if not current_path.startswith('/api/v'):
            suggestions.append(f"/api/v1{current_path}")
        
        return suggestions

class APIDocumentationGenerator:
    """API文档自动生成器"""
    
    def __init__(self):
        self.endpoints: List[APIEndpoint] = []
        self.openapi_spec = {
            "openapi": "3.0.0",
            "info": {
                "title": "IPv6 WireGuard Manager API",
                "version": "1.0.0",
                "description": "IPv6 WireGuard Manager RESTful API"
            },
            "servers": [
                {"url": "http://localhost:${API_PORT}", "description": "开发环境"},
                {"url": "https://api.example.com", "description": "生产环境"}
            ],
            "paths": {},
            "components": {
                "schemas": {},
                "securitySchemes": {
                    "bearerAuth": {
                        "type": "http",
                        "scheme": "bearer",
                        "bearerFormat": "JWT"
                    }
                }
            }
        }
    
    def register_endpoint(self, endpoint: APIEndpoint):
        """注册API端点"""
        self.endpoints.append(endpoint)
        self._update_openapi_spec(endpoint)
    
    def _update_openapi_spec(self, endpoint: APIEndpoint):
        """更新OpenAPI规范"""
        path = endpoint.path
        method = endpoint.method.value.lower()
        
        if path not in self.openapi_spec["paths"]:
            self.openapi_spec["paths"][path] = {}
        
        self.openapi_spec["paths"][path][method] = {
            "summary": endpoint.description,
            "tags": endpoint.tags,
            "parameters": endpoint.parameters,
            "responses": endpoint.responses,
            "deprecated": endpoint.deprecated
        }
        
        if endpoint.rate_limit:
            self.openapi_spec["paths"][path][method]["x-rate-limit"] = endpoint.rate_limit
        
        if endpoint.cache_ttl:
            self.openapi_spec["paths"][path][method]["x-cache-ttl"] = endpoint.cache_ttl
    
    def generate_openapi_json(self) -> str:
        """生成OpenAPI JSON文档"""
        return json.dumps(self.openapi_spec, indent=2, ensure_ascii=False)
    
    def generate_swagger_html(self) -> str:
        """生成Swagger UI HTML"""
        return f"""
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager API</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui.css" />
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js"></script>
    <script>
        SwaggerUIBundle({{
            url: '/api/docs/openapi.json',
            dom_id: '#swagger-ui',
            presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIBundle.presets.standalone
            ]
        }});
    </script>
</body>
</html>
"""

class APICacheManager:
    """API响应缓存管理器"""
    
    def __init__(self):
        self.cache: Dict[str, Dict[str, Any]] = {}
        self.cache_stats = {
            'hits': 0,
            'misses': 0,
            'evictions': 0
        }
    
    def get_cache_key(self, path: str, method: str, params: Dict[str, Any]) -> str:
        """生成缓存键"""
        # 排序参数以确保一致性
        sorted_params = sorted(params.items()) if params else []
        param_str = "&".join([f"{k}={v}" for k, v in sorted_params])
        return f"{method}:{path}:{param_str}"
    
    def get(self, cache_key: str) -> Optional[Any]:
        """获取缓存数据"""
        if cache_key in self.cache:
            cache_entry = self.cache[cache_key]
            if time.time() < cache_entry['expires_at']:
                self.cache_stats['hits'] += 1
                return cache_entry['data']
            else:
                # 缓存过期，删除
                del self.cache[cache_key]
                self.cache_stats['evictions'] += 1
        
        self.cache_stats['misses'] += 1
        return None
    
    def set(self, cache_key: str, data: Any, ttl: int = 300):
        """设置缓存数据"""
        self.cache[cache_key] = {
            'data': data,
            'expires_at': time.time() + ttl,
            'created_at': time.time()
        }
    
    def clear(self, pattern: Optional[str] = None):
        """清除缓存"""
        if pattern:
            # 清除匹配模式的缓存
            keys_to_remove = [k for k in self.cache.keys() if pattern in k]
            for key in keys_to_remove:
                del self.cache[key]
        else:
            # 清除所有缓存
            self.cache.clear()
    
    def get_stats(self) -> Dict[str, Any]:
        """获取缓存统计"""
        total_requests = self.cache_stats['hits'] + self.cache_stats['misses']
        hit_rate = self.cache_stats['hits'] / total_requests if total_requests > 0 else 0
        
        return {
            'cache_size': len(self.cache),
            'hit_rate': hit_rate,
            'stats': self.cache_stats
        }

def api_endpoint(
    path: str,
    method: HTTPMethod = HTTPMethod.GET,
    description: str = "",
    tags: List[str] = None,
    parameters: List[Dict[str, Any]] = None,
    responses: Dict[int, Dict[str, Any]] = None,
    deprecated: bool = False,
    rate_limit: Optional[int] = None,
    cache_ttl: Optional[int] = None
):
    """API端点装饰器"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 性能监控
            start_time = time.time()
            
            try:
                # 执行原始函数
                result = await func(*args, **kwargs)
                
                # 记录性能指标
                execution_time = time.time() - start_time
                logger.info(f"API调用完成: {method.value} {path} - {execution_time:.3f}s")
                
                return result
                
            except Exception as e:
                # 记录错误
                execution_time = time.time() - start_time
                logger.error(f"API调用失败: {method.value} {path} - {execution_time:.3f}s - {e}")
                raise
        
        # 注册端点
        endpoint = APIEndpoint(
            path=path,
            method=method,
            handler=wrapper,
            description=description,
            tags=tags or [],
            parameters=parameters or [],
            responses=responses or {},
            deprecated=deprecated,
            rate_limit=rate_limit,
            cache_ttl=cache_ttl
        )
        
        # 注册到文档生成器
        doc_generator.register_endpoint(endpoint)
        
        return wrapper
    
    return decorator

# 全局实例
path_validator = APIPathValidator()
doc_generator = APIDocumentationGenerator()
cache_manager = APICacheManager()

# 使用示例
@api_endpoint(
    path="/api/v1/users",
    method=HTTPMethod.GET,
    description="获取用户列表",
    tags=["用户管理"],
    parameters=[
        {
            "name": "page",
            "in": "query",
            "schema": {"type": "integer", "default": 1},
            "description": "页码"
        },
        {
            "name": "size",
            "in": "query",
            "schema": {"type": "integer", "default": 10},
            "description": "每页数量"
        }
    ],
    responses={
        200: {
            "description": "成功",
            "content": {
                "application/json": {
                    "schema": {
                        "type": "object",
                        "properties": {
                            "users": {"type": "array"},
                            "total": {"type": "integer"}
                        }
                    }
                }
            }
        }
    },
    cache_ttl=300
)
async def get_users(page: int = 1, size: int = 10):
    """获取用户列表"""
    # 检查缓存
    cache_key = cache_manager.get_cache_key("/api/v1/users", "GET", {"page": page, "size": size})
    cached_result = cache_manager.get(cache_key)
    
    if cached_result:
        return cached_result
    
    # 模拟数据库查询
    users = [{"id": i, "name": f"user{i}"} for i in range(1, size + 1)]
    result = {"users": users, "total": 100}
    
    # 设置缓存
    cache_manager.set(cache_key, result, 300)
    
    return result

if __name__ == "__main__":
    # 测试路径验证
    test_paths = [
        "/api/v1/users",
        "/api/v1/users/123",
        "/api/v1/users/123/posts",
        "/api/v1/users/search",
        "/invalid/path",
        "/api/v0/users"  # 无效版本
    ]
    
    print("API路径验证测试:")
    for path in test_paths:
        result = path_validator.validate_path(path)
        print(f"{path}: {'✓' if result['valid'] else '✗'} {result['pattern']}")
        if result['errors']:
            print(f"  错误: {result['errors']}")
        if result['suggestions']:
            print(f"  建议: {result['suggestions']}")
    
    # 生成API文档
    print("\n生成API文档:")
    openapi_json = doc_generator.generate_openapi_json()
    print("OpenAPI JSON长度:", len(openapi_json))
    
    # 测试缓存
    print("\n缓存测试:")
    cache_key = cache_manager.get_cache_key("/api/v1/users", "GET", {"page": 1})
    cache_manager.set(cache_key, {"test": "data"}, 60)
    cached_data = cache_manager.get(cache_key)
    print("缓存数据:", cached_data)
    print("缓存统计:", cache_manager.get_stats())
