"""
API文档自动生成器
与FastAPI和路径管理器集成
"""

import json
from typing import Dict, List, Any, Optional
from fastapi import FastAPI
from fastapi.routing import APIRoute
from app.core.api_paths import path_manager
from app.core.api_enhancement import APIEndpoint, APIDocumentationGenerator
import logging

logger = logging.getLogger(__name__)

class FastAPIDocGenerator(APIDocumentationGenerator):
    """FastAPI集成的API文档生成器"""
    
    def __init__(self, app: FastAPI):
        super().__init__()
        self.app = app
        self._register_existing_routes()
    
    def _register_existing_routes(self):
        """注册现有路由到文档生成器"""
        for route in self.app.routes:
            if isinstance(route, APIRoute):
                # 从路由中提取信息
                path = route.path
                methods = list(route.methods)
                
                # 验证路径
                validation_result = path_manager.validate_path(path)
                if not validation_result['valid']:
                    logger.warning(f"跳过无效路径的文档生成: {path}")
                    continue
                
                # 为每个方法创建端点
                for method in methods:
                    if method in ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']:
                        self._create_endpoint_from_route(route, method)
    
    def _create_endpoint_from_route(self, route: APIRoute, method: str):
        """从路由创建API端点"""
        # 获取路由信息
        path = route.path
        endpoint_func = route.endpoint
        summary = route.summary or route.endpoint.__name__
        description = route.description or ""
        tags = list(route.tags) or ["未分类"]
        
        # 从函数签名中提取参数
        parameters = self._extract_parameters(endpoint_func)
        
        # 创建响应定义
        responses = self._create_responses(route)
        
        # 创建端点
        endpoint = APIEndpoint(
            path=path,
            method=HTTPMethod(method),
            handler=endpoint_func,
            description=description,
            tags=tags,
            parameters=parameters,
            responses=responses,
            deprecated=getattr(endpoint_func, '_deprecated', False)
        )
        
        # 注册端点
        self.register_endpoint(endpoint)
    
    def _extract_parameters(self, func) -> List[Dict[str, Any]]:
        """从函数签名中提取参数"""
        # 这里需要实现从函数签名中提取参数的逻辑
        # 简化实现，实际应该使用inspect模块
        return []
    
    def _create_responses(self, route: APIRoute) -> Dict[int, Dict[str, Any]]:
        """创建响应定义"""
        # 简化实现，实际应该从函数返回类型注解中提取
        return {
            200: {
                "description": "成功",
                "content": {
                    "application/json": {
                        "schema": {}
                    }
                }
            }
        }
    
    def setup_docs_routes(self, app: FastAPI):
        """设置文档路由"""
        @app.get("/api/docs", tags=["文档"])
        async def get_api_docs():
            """获取API文档"""
            return {
                "openapi": f"/api/docs/openapi.json",
                "swagger": "/api/docs/swagger",
                "redoc": "/api/docs/redoc",
                "version": path_manager.current_version.value
            }
        
        @app.get("/api/docs/openapi.json", tags=["文档"])
        async def get_openapi():
            """获取OpenAPI规范"""
            return json.loads(self.generate_openapi_json())
        
        @app.get("/api/docs/swagger", tags=["文档"])
        async def get_swagger_ui():
            """获取Swagger UI"""
            return self.generate_swagger_html()
        
        @app.get("/api/versions", tags=["版本"])
        async def get_api_versions():
            """获取支持的API版本信息"""
            return {
                "current": path_manager.current_version.value,
                "supported": [v.value for v in path_manager.supported_versions],
                "deprecated": [v.value for v in path_manager.deprecated_versions]
            }

def setup_api_docs(app: FastAPI):
    """设置API文档"""
    doc_generator = FastAPIDocGenerator(app)
    doc_generator.setup_docs_routes(app)
    return doc_generator
