"""
API路径构建器的FastAPI中间件
提供与FastAPI框架的集成功能
"""

from typing import Callable, Dict, Any, Optional, List, Tuple
from fastapi import Request, Response, HTTPException, status
from fastapi.routing import APIRoute
from fastapi.dependencies import utils
import inspect
from .builder import APIPathBuilder
from .version_manager import APIVersion


class APIPathMiddleware:
    """API路径中间件"""
    
    def __init__(self, path_builder: APIPathBuilder):
        """
        初始化API路径中间件
        
        Args:
            path_builder: API路径构建器实例
        """
        self.path_builder = path_builder
    
    async def __call__(self, request: Request, call_next: Callable) -> Response:
        """
        中间件处理函数
        
        Args:
            request: FastAPI请求对象
            call_next: 下一个中间件或路由处理函数
            
        Returns:
            Response: FastAPI响应对象
        """
        # 获取请求路径
        path = request.url.path
        
        # 标准化路径
        normalized_path = self.path_builder.normalize_path(path)
        
        # 如果路径被标准化，重定向到标准化路径
        if normalized_path != path:
            return Response(
                status_code=status.HTTP_301_MOVED_PERMANENTLY,
                headers={"Location": normalized_path}
            )
        
        # 继续处理请求
        response = await call_next(request)
        return response


class VersionedAPIRoute(APIRoute):
    """支持版本控制的API路由"""
    
    def __init__(self, path: str, *, path_builder: APIPathBuilder = None, 
                 category: str = None, action: str = None, 
                 version: APIVersion = None, **kwargs):
        """
        初始化版本化API路由
        
        Args:
            path: 路由路径
            path_builder: API路径构建器实例
            category: 路径类别
            action: 路径动作
            version: API版本
            **kwargs: 其他APIRoute参数
        """
        self.path_builder = path_builder or APIPathBuilder()
        self.category = category
        self.action = action
        self.version = version or self.path_builder.get_current_version()
        
        # 如果提供了类别和动作，使用路径构建器构建路径
        if category and action:
            path = self.path_builder.build_path(category, action)
        
        super().__init__(path, **kwargs)
    
    def get_route_handler(self) -> Callable:
        """获取路由处理函数"""
        original_route_handler = super().get_route_handler()
        
        async def custom_route_handler(request: Request) -> Response:
            # 检查路径是否已弃用
            if self.category and self.action:
                if self.path_builder.is_deprecated(self.category, self.action):
                    deprecation_message = self.path_builder.get_deprecation_message(
                        self.category, self.action
                    )
                    if deprecation_message:
                        # 在响应头中添加弃用警告
                        response = await original_route_handler(request)
                        response.headers["X-API-Deprecated"] = "true"
                        response.headers["X-API-Deprecation-Message"] = deprecation_message
                        return response
            
            # 正常处理请求
            return await original_route_handler(request)
        
        return custom_route_handler


class APIPathDocumentation:
    """API路径文档生成器"""
    
    def __init__(self, path_builder: APIPathBuilder):
        """
        初始化API路径文档生成器
        
        Args:
            path_builder: API路径构建器实例
        """
        self.path_builder = path_builder
    
    def generate_openapi_paths(self) -> Dict[str, Any]:
        """
        生成OpenAPI路径规范
        
        Returns:
            Dict[str, Any]: OpenAPI路径规范
        """
        paths = {}
        
        for category in self.path_builder.get_categories():
            for action in self.path_builder.get_actions_for_category(category):
                # 获取路径定义
                path_def = self.path_builder.get_path_definition(category, action)
                if not path_def:
                    continue
                
                # 构建路径
                path = path_def.path
                metadata = path_def.metadata
                
                # 初始化路径条目
                if path not in paths:
                    paths[path] = {}
                
                # 为每个允许的方法添加操作
                for method in metadata.methods:
                    method_lower = method.lower()
                    
                    # 构建操作对象
                    operation = {
                        "summary": metadata.description or f"{category}.{action}",
                        "description": metadata.description or "",
                        "tags": [category],
                        "responses": {
                            "200": {
                                "description": "Successful Response"
                            }
                        }
                    }
                    
                    # 添加认证要求
                    if metadata.auth_required:
                        operation["security"] = [{"BearerAuth": []}]
                    
                    # 添加参数
                    if metadata.parameters:
                        parameters = []
                        for param_name, param_info in metadata.parameters.items():
                            param = {
                                "name": param_name,
                                "in": "path",
                                "required": True,
                                "schema": {"type": "string"}
                            }
                            
                            # 如果有参数类型信息
                            if isinstance(param_info, dict) and "type" in param_info:
                                param["schema"]["type"] = param_info["type"]
                            
                            parameters.append(param)
                        
                        operation["parameters"] = parameters
                    
                    # 添加请求体模式
                    if metadata.request_schema:
                        operation["requestBody"] = {
                            "content": {
                                "application/json": {
                                    "schema": {"$ref": f"#/components/schemas/{metadata.request_schema}"}
                                }
                            }
                        }
                    
                    # 添加响应模式
                    if metadata.response_schema:
                        operation["responses"]["200"]["content"] = {
                            "application/json": {
                                "schema": {"$ref": f"#/components/schemas/{metadata.response_schema}"}
                            }
                        }
                    
                    # 添加弃用信息
                    if metadata.deprecated:
                        operation["deprecated"] = True
                        if metadata.deprecation_message:
                            operation["description"] += f"\n\n**已弃用**: {metadata.deprecation_message}"
                    
                    # 添加版本信息
                    operation["x-api-version"] = metadata.version
                    
                    # 将操作添加到路径
                    paths[path][method_lower] = operation
        
        return paths
    
    def generate_path_summary(self) -> Dict[str, Any]:
        """
        生成路径摘要
        
        Returns:
            Dict[str, Any]: 路径摘要
        """
        summary = {
            "categories": {},
            "total_paths": 0,
            "paths_by_method": {},
            "paths_by_version": {},
            "auth_required_paths": 0,
            "deprecated_paths": 0
        }
        
        for category in self.path_builder.get_categories():
            category_paths = []
            for action in self.path_builder.get_actions_for_category(category):
                path_def = self.path_builder.get_path_definition(category, action)
                if not path_def:
                    continue
                
                # 获取路径信息
                path_info = {
                    "action": action,
                    "path": path_def.path,
                    "methods": self.path_builder.get_allowed_methods(category, action),
                    "version": self.path_builder.get_path_version(category, action),
                    "auth_required": self.path_builder.is_auth_required(category, action),
                    "deprecated": self.path_builder.is_deprecated(category, action),
                    "description": self.path_builder.get_path_metadata(category, action).description
                }
                
                category_paths.append(path_info)
                
                # 更新统计信息
                summary["total_paths"] += 1
                
                for method in path_info["methods"]:
                    if method not in summary["paths_by_method"]:
                        summary["paths_by_method"][method] = 0
                    summary["paths_by_method"][method] += 1
                
                version = path_info["version"]
                if version not in summary["paths_by_version"]:
                    summary["paths_by_version"][version] = 0
                summary["paths_by_version"][version] += 1
                
                if path_info["auth_required"]:
                    summary["auth_required_paths"] += 1
                
                if path_info["deprecated"]:
                    summary["deprecated_paths"] += 1
            
            summary["categories"][category] = category_paths
        
        return summary


def setup_fastapi_integration(app, path_builder: APIPathBuilder = None) -> APIPathBuilder:
    """
    设置FastAPI与API路径构建器的集成
    
    Args:
        app: FastAPI应用实例
        path_builder: API路径构建器实例（可选）
        
    Returns:
        APIPathBuilder: API路径构建器实例
    """
    # 创建路径构建器（如果未提供）
    if path_builder is None:
        path_builder = APIPathBuilder()
    
    # 添加路径中间件
    app.add_middleware(APIPathMiddleware, path_builder=path_builder)
    
    # 创建文档生成器
    doc_generator = APIPathDocumentation(path_builder)
    
    # 添加路径摘要端点
    @app.get("/api/paths/summary", tags=["API路径"])
    async def get_path_summary():
        """获取API路径摘要"""
        return doc_generator.generate_path_summary()
    
    # 添加路径验证端点
    @app.get("/api/paths/validation", tags=["API路径"])
    async def get_path_validation():
        """获取API路径验证结果"""
        return path_builder.validate_all_paths()
    
    # 添加配置导出端点
    @app.get("/api/paths/config", tags=["API路径"])
    async def export_path_config():
        """导出API路径配置"""
        return path_builder.export_config()
    
    # 更新OpenAPI路径
    original_openapi = app.openapi
    
    def custom_openapi():
        if app.openapi_schema:
            return app.openapi_schema
        
        openapi_schema = original_openapi()
        
        # 添加路径
        openapi_schema["paths"].update(doc_generator.generate_openapi_paths())
        
        # 添加安全方案
        if "components" not in openapi_schema:
            openapi_schema["components"] = {}
        if "securitySchemes" not in openapi_schema["components"]:
            openapi_schema["components"]["securitySchemes"] = {}
        
        openapi_schema["components"]["securitySchemes"]["BearerAuth"] = {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
        }
        
        app.openapi_schema = openapi_schema
        return app.openapi_schema
    
    app.openapi = custom_openapi
    
    return path_builder