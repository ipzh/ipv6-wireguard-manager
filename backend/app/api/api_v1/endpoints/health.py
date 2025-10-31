"""
健康检查端点 - 简化版本
"""
import time
from fastapi import APIRouter
from typing import Dict, Any

try:
    from ...core.unified_config import settings
    APP_VERSION = settings.APP_VERSION
    APP_NAME = "IPv6 WireGuard Manager"
except ImportError:
    # 降级方案：如果导入失败，使用默认值
    APP_VERSION = "3.0.0"
    APP_NAME = "IPv6 WireGuard Manager"

router = APIRouter()

@router.get("/")
async def health_check() -> Dict[str, Any]:
    """基础健康检查 - 映射到 /api/v1/health"""
    return {
        "status": "healthy",
        "service": APP_NAME,
        "version": APP_VERSION,
        "timestamp": time.time()
    }

@router.get("/alt")
async def health_check_alt() -> Dict[str, Any]:
    """基础健康检查（备用路径）- 映射到 /api/v1/health/alt"""
    return {
        "status": "healthy",
        "service": APP_NAME,
        "version": APP_VERSION,
        "timestamp": time.time()
    }

@router.get("/detailed", response_model=None)
async def detailed_health_check() -> Dict[str, Any]:
    """详细健康检查 - 映射到 /api/v1/health/detailed"""
    return {
        "status": "healthy",
        "service": APP_NAME,
        "version": APP_VERSION,
        "components": {
            "database": {"status": "simulated", "message": "Database simulation mode"},
            "cache": {"status": "disabled", "message": "Cache disabled"},
            "monitoring": {"status": "basic", "message": "Basic monitoring only"}
        },
        "timestamp": time.time()
    }

@router.get("/readiness", response_model=None)
async def readiness_check() -> Dict[str, Any]:
    """就绪检查 - 映射到 /api/v1/health/readiness"""
    return {
        "status": "ready",
        "service": APP_NAME,
        "timestamp": time.time()
    }

@router.get("/liveness", response_model=None)
async def liveness_check() -> Dict[str, Any]:
    """存活检查 - 映射到 /api/v1/health/liveness"""
    return {
        "status": "alive",
        "service": APP_NAME,
        "timestamp": time.time()
    }

@router.get("/metrics", response_model=None)
async def get_metrics() -> Dict[str, Any]:
    """获取基础指标"""
    return {
        "uptime": time.time(),
        "requests": 0,
        "errors": 0,
        "timestamp": time.time()
    }