"""
API路由初始化模块
集成路径验证和版本控制
"""

from fastapi import APIRouter
from app.core.api_paths import path_manager, VersionedAPIRoute, api_path_middleware
from app.core.api_enhancement import doc_generator
import logging

logger = logging.getLogger(__name__)

# 创建主API路由器
api_router = APIRouter(
    route_class=VersionedAPIRoute,
    prefix="/api"
)

# 导入各模块路由
from app.api.v1 import api_router as v1_router

# 包含各版本路由
api_router.include_router(v1_router, prefix="/v1")

# 预留未来版本
# from app.api.v2 import api_router as v2_router
# api_router.include_router(v2_router, prefix="/v2")

# 注册API文档端点
@api_router.get("/docs", tags=["文档"])
async def get_api_docs():
    """获取API文档"""
    return {
        "openapi": doc_generator.generate_openapi_json(),
        "swagger": "/api/docs/swagger",
        "redoc": "/api/docs/redoc"
    }

@api_router.get("/docs/openapi.json", tags=["文档"])
async def get_openapi():
    """获取OpenAPI规范"""
    return doc_generator.generate_openapi_json()

@api_router.get("/docs/swagger", tags=["文档"])
async def get_swagger_ui():
    """获取Swagger UI"""
    return doc_generator.generate_swagger_html()

@api_router.get("/versions", tags=["版本"])
async def get_api_versions():
    """获取支持的API版本信息"""
    return {
        "current": path_manager.current_version.value,
        "supported": [v.value for v in path_manager.supported_versions],
        "deprecated": [v.value for v in path_manager.deprecated_versions]
    }