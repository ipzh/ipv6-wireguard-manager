"""
状态检查API端点 - 修复版本
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....services.status_service import StatusService

router = APIRouter()


@router.get("/")
async def get_system_status(db: AsyncSession = Depends(get_async_db)):
    """获取系统状态"""
    status_service = StatusService(db)
    status_info = await status_service.get_system_status()
    return status_info


@router.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy", "message": "系统运行正常"}


@router.get("/services")
async def get_services_status(db: AsyncSession = Depends(get_async_db)):
    """获取服务状态"""
    status_service = StatusService(db)
    services_status = await status_service.get_services_status()
    return services_status