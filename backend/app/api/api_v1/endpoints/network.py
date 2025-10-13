"""
网络管理API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db

router = APIRouter()


@router.get("/interfaces")
async def get_network_interfaces(db: AsyncSession = Depends(get_async_db)):
    """获取网络接口信息"""
    return {"interfaces": [], "message": "网络接口功能待实现"}


@router.get("/status")
async def get_network_status(db: AsyncSession = Depends(get_async_db)):
    """获取网络状态"""
    return {"status": "healthy", "message": "网络状态正常"}