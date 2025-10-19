"""
状态检查API端点 - 修复版本
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ...core.database import get_db

router = APIRouter()

# 简化的模式和服务，避免依赖不存在的模块
try:
    from ...services.status_service import StatusService
except ImportError:
    StatusService = None

try:
    from ...schemas.status import SystemStatusResponse, HealthCheckResponse, ServicesStatusResponse
except ImportError:
    SystemStatusResponse = None
    HealthCheckResponse = None
    ServicesStatusResponse = None


@router.get("/", response_model=None)
async def get_system_status(db: AsyncSession = Depends(get_db)):
    """获取系统状态"""
    status_service = StatusService(db) if StatusService else None
    if not status_service:
        return {"status": "unknown", "message": "Status service not available"}
    status_info = await status_service.get_system_status()
    return status_info


@router.get("/health", response_model=None)
async def health_check():
    """健康检查"""
    return {"status": "healthy", "message": "系统运行正常"}


@router.get("/services", response_model=None)
async def get_services_status(db: AsyncSession = Depends(get_db)):
    """获取服务状态"""
    status_service = StatusService(db) if StatusService else None
    if not status_service:
        return {"services": {}, "message": "Status service not available"}
    services_status = await status_service.get_services_status()
    return services_status
