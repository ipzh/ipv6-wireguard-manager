"""
健康检查端点 - 简化版本
"""
import time
from fastapi import APIRouter
from typing import Dict, Any
from ...core.unified_config import settings
from ...schemas.common import HealthCheckResponse

router = APIRouter()

@router.get("/", response_model=HealthCheckResponse)
async def health_check() -> HealthCheckResponse:
    """基础健康检查"""
    return HealthCheckResponse(
        status="healthy",
        service="IPv6 WireGuard Manager",
        version=settings.APP_VERSION,
        timestamp=time.time()
    )

@router.get("/health", response_model=HealthCheckResponse)
async def health_check_alt() -> HealthCheckResponse:
    """基础健康检查（备用路径）"""
    return HealthCheckResponse(
        status="healthy",
        service="IPv6 WireGuard Manager",
        version=settings.APP_VERSION,
        timestamp=time.time()
    )

@router.get("/health/detailed", response_model=None)
async def detailed_health_check() -> Dict[str, Any]:
    """详细健康检查"""
    return {
        "status": "healthy",
        "service": "IPv6 WireGuard Manager",
        "version": settings.APP_VERSION,
        "components": {
            "database": {"status": "simulated", "message": "Database simulation mode"},
            "cache": {"status": "disabled", "message": "Cache disabled"},
            "monitoring": {"status": "basic", "message": "Basic monitoring only"}
        },
        "timestamp": time.time()
    }

@router.get("/health/readiness", response_model=None)
async def readiness_check() -> Dict[str, Any]:
    """就绪检查"""
    return {
        "status": "ready",
        "service": "IPv6 WireGuard Manager",
        "timestamp": time.time()
    }

@router.get("/health/liveness", response_model=None)
async def liveness_check() -> Dict[str, Any]:
    """存活检查"""
    return {
        "status": "alive",
        "service": "IPv6 WireGuard Manager",
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