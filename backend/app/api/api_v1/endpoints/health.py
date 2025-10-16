"""
健康检查端点
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis
import logging
from typing import Dict, Any

from ....core.database import get_async_db

# 导入缓存和性能监控（如果可用）
try:
    from ....core.cache import cache_manager
except ImportError:
    cache_manager = None

try:
    from ....core.query_optimizer import performance_monitor
except ImportError:
    performance_monitor = None

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/health", response_model=None)
async def health_check() -> Dict[str, Any]:
    """基础健康检查"""
    return {
        "status": "healthy",
        "service": "IPv6 WireGuard Manager",
        "version": "3.0.0"
    }

@router.get("/health/detailed", response_model=None)
async def detailed_health_check(db: AsyncSession = Depends(get_async_db)) -> Dict[str, Any]:
    """详细健康检查"""
    health_status = {
        "status": "healthy",
        "components": {},
        "performance": {}
    }
    
    # 数据库健康检查
    try:
        await db.execute(text("SELECT 1"))
        health_status["components"]["database"] = {
            "status": "healthy",
            "message": "Database connection successful"
        }
    except Exception as e:
        health_status["status"] = "unhealthy"
        health_status["components"]["database"] = {
            "status": "unhealthy",
            "message": f"Database connection failed: {str(e)}"
        }
    
    # Redis健康检查
    if cache_manager:
        try:
            await cache_manager.connect()
            await cache_manager.set("health_check", "test", 10)
            test_value = await cache_manager.get("health_check")
            if test_value == "test":
                health_status["components"]["redis"] = {
                    "status": "healthy",
                    "message": "Redis connection successful"
                }
            else:
                health_status["status"] = "unhealthy"
                health_status["components"]["redis"] = {
                    "status": "unhealthy",
                    "message": "Redis test failed"
                }
        except Exception as e:
            health_status["status"] = "unhealthy"
            health_status["components"]["redis"] = {
                "status": "unhealthy",
                "message": f"Redis connection failed: {str(e)}"
            }
    else:
        health_status["components"]["redis"] = {
            "status": "disabled",
            "message": "Redis cache is not configured"
        }
    
    # 性能指标
    if performance_monitor:
        health_status["performance"] = performance_monitor.get_performance_report()
    else:
        health_status["performance"] = {
            "status": "disabled",
            "message": "Performance monitoring is not configured"
        }
    
    return health_status

@router.get("/health/readiness", response_model=None)
async def readiness_check() -> Dict[str, Any]:
    """就绪检查"""
    return {
        "status": "ready",
        "message": "Service is ready to accept requests"
    }

@router.get("/health/liveness", response_model=None)
async def liveness_check() -> Dict[str, Any]:
    """存活检查"""
    return {
        "status": "alive",
        "message": "Service is alive"
    }

@router.get("/metrics", response_model=None)
async def metrics_endpoint() -> Dict[str, Any]:
    """性能指标端点"""
    if performance_monitor:
        return performance_monitor.get_performance_report()
    else:
        return {
            "status": "disabled",
            "message": "Performance monitoring is not configured"
        }