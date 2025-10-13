"""
系统管理API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db

router = APIRouter()


@router.get("/info")
async def get_system_info(db: AsyncSession = Depends(get_async_db)):
    """获取系统信息"""
    return {"info": {}, "message": "系统信息功能待实现"}


@router.post("/restart")
async def restart_system(db: AsyncSession = Depends(get_async_db)):
    """重启系统"""
    return {"message": "系统重启功能待实现"}