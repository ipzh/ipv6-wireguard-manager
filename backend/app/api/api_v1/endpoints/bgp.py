"""
BGP管理API端点
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

from ....core.database import get_async_db

router = APIRouter()


@router.get("/sessions", response_model=dict)
async def get_bgp_sessions(db: AsyncSession = Depends(get_async_db)):
    """获取BGP会话"""
    return {"sessions": [], "message": "BGP会话功能待实现"}


@router.get("/routes", response_model=dict)
async def get_bgp_routes(db: AsyncSession = Depends(get_async_db)):
    """获取BGP路由"""
    return {"routes": [], "message": "BGP路由功能待实现"}