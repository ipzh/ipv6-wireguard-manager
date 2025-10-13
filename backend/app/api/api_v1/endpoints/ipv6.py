"""
IPv6管理API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db

router = APIRouter()


@router.get("/pools", response_model=None)
async def get_ipv6_pools(db: AsyncSession = Depends(get_async_db)):
    """获取IPv6前缀池"""
    return {"pools": [], "message": "IPv6前缀池功能待实现"}


@router.get("/allocations", response_model=None)
async def get_ipv6_allocations(db: AsyncSession = Depends(get_async_db)):
    """获取IPv6分配"""
    return {"allocations": [], "message": "IPv6分配功能待实现"}