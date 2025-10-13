"""
IPv6前缀池管理API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db

router = APIRouter()


@router.get("/")
async def get_ipv6_pools(db: AsyncSession = Depends(get_async_db)):
    """获取IPv6前缀池列表"""
    return {"pools": [], "message": "IPv6前缀池管理功能待实现"}


@router.post("/")
async def create_ipv6_pool(db: AsyncSession = Depends(get_async_db)):
    """创建IPv6前缀池"""
    return {"message": "创建IPv6前缀池功能待实现"}