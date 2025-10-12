"""
状态检查API端点
"""
from fastapi import APIRouter
import time

router = APIRouter()

@router.get("/")
async def get_status():
    """获取系统状态"""
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "services": {
            "database": "connected",
            "redis": "connected",
            "api": "running"
        }
    }

@router.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "ok", "message": "Service is healthy"}