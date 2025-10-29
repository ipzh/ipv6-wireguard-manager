"""
API路由初始化模块
简化版：移除复杂的路径构建器集成，直接使用FastAPI路由
"""
from fastapi import APIRouter
import logging

logger = logging.getLogger(__name__)

# 创建API路由器
api_router = APIRouter()

# 导入各模块路由
try:
    from .api_v1.api import api_router as v1_router
    # 包含v1版本路由（统一挂载到 /api/v1）
    api_router.include_router(v1_router, prefix="/api/v1")
    logger.info("✅ API v1 路由加载成功")
except ImportError as e:
    logger.error(f"❌ API v1 路由加载失败: {e}")

# 预留未来版本
# from app.api.v2 import api_router as v2_router
# api_router.include_router(v2_router, prefix="/v2")

# 简单的API信息端点
@api_router.get("/", tags=["API信息"])
async def api_root():
    """获取API基本信息"""
    return {
        "name": "IPv6 WireGuard Manager API",
        "version": "v1",
        "documentation": "/docs",
        "health": "/health"
    }

# 导出API路由器
__all__ = ["api_router"]
