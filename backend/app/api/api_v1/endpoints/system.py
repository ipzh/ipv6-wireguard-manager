"""
系统管理API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

from ....core.database import get_async_db
from ....schemas.common import MessageResponse

router = APIRouter()


@router.get("/info", response_model=dict)
async def get_system_info(db: AsyncSession = Depends(get_async_db)):
    """获取系统信息"""
    return {"info": {}, "message": "系统信息功能待实现"}


@router.post("/restart", response_model=MessageResponse)
async def restart_system(db: AsyncSession = Depends(get_async_db)):
    """重启系统"""
    return MessageResponse(message="系统重启功能待实现")