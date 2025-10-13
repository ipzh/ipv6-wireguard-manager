"""
IPv6前缀池管理API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

from ....core.database import get_async_db
from ....schemas.common import MessageResponse

router = APIRouter()


@router.get("/", response_model=dict)
async def get_ipv6_pools(db: AsyncSession = Depends(get_async_db)):
    """获取IPv6前缀池列表"""
    return {"pools": [], "message": "IPv6前缀池管理功能待实现"}


@router.post("/", response_model=MessageResponse)
async def create_ipv6_pool(db: AsyncSession = Depends(get_async_db)):
    """创建IPv6前缀池"""
    return MessageResponse(message="创建IPv6前缀池功能待实现")