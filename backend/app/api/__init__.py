"""
API路由初始化模块
集成路径验证和版本控制
"""

from fastapi import APIRouter
from app.core.api_path_builder import create_api_path_builder, setup_fastapi_integration
import logging

logger = logging.getLogger(__name__)

# 创建统一API路径构建器
path_builder = create_api_path_builder()

# 设置FastAPI集成
api_router = setup_fastapi_integration(path_builder, prefix="/api")

# 导入各模块路由
from app.api.api_v1 import api_router as v1_router

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
        "openapi": path_builder.get_documentation().generate_openapi_json(),
        "swagger": "/api/docs/swagger",
        "redoc": "/api/docs/redoc"
    }

@api_router.get("/docs/openapi.json", tags=["文档"])
async def get_openapi():
    """获取OpenAPI规范"""
    return path_builder.get_documentation().generate_openapi_json()

@api_router.get("/docs/swagger", tags=["文档"])
async def get_swagger_ui():
    """获取Swagger UI"""
    return path_builder.get_documentation().generate_swagger_html()

@api_router.get("/versions", tags=["版本"])
async def get_api_versions():
    """获取支持的API版本信息"""
    version_manager = path_builder.get_version_manager()
    return {
        "current": version_manager.get_current_version(),
        "supported": version_manager.get_supported_versions(),
        "deprecated": version_manager.get_deprecated_versions()
    }