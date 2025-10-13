"""
系统监控API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db

router = APIRouter()


@router.get("/metrics")
async def get_system_metrics(db: AsyncSession = Depends(get_async_db)):
    """获取系统指标"""
    return {"metrics": {}, "message": "系统监控功能待实现"}


@router.get("/alerts")
async def get_alerts(db: AsyncSession = Depends(get_async_db)):
    """获取告警信息"""
    return {"alerts": [], "message": "告警功能待实现"}