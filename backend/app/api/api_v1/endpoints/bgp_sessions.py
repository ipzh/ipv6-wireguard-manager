"""
BGP会话管理API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db

router = APIRouter()


@router.get("/", response_model=None)
async def get_bgp_sessions(db: AsyncSession = Depends(get_async_db)):
    """获取BGP会话列表"""
    return {"sessions": [], "message": "BGP会话管理功能待实现"}


@router.post("/", response_model=None)
async def create_bgp_session(db: AsyncSession = Depends(get_async_db)):
    """创建BGP会话"""
    return {"message": "创建BGP会话功能待实现"}