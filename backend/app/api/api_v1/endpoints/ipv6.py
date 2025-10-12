"""
IPv6前缀池API端点
"""
from typing import Any, List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....core.security import get_current_user_id
from ....schemas.ipv6 import (
    PrefixPool, PrefixPoolCreate, PrefixPoolUpdate, PrefixPoolList,
    PoolPrefix, PoolPrefixList
)
from ....services.ipv6_service import IPv6PoolService

router = APIRouter()


# 池管理
@router.get("/prefix-pools", response_model=PrefixPoolList)
async def list_pools(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    svc = IPv6PoolService(db)
    pools = await svc.list_pools()
    return PrefixPoolList(pools=pools)


@router.post("/prefix-pools", response_model=PrefixPool, status_code=status.HTTP_201_CREATED)
async def create_pool(
    data: PrefixPoolCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    svc = IPv6PoolService(db)
    pool = await svc.create_pool(data)
    await db.commit()
    return pool


@router.patch("/prefix-pools/{pool_id}", response_model=PrefixPool)
async def update_pool(
    pool_id: UUID,
    data: PrefixPoolUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    svc = IPv6PoolService(db)
    pool = await svc.update_pool(pool_id, data)
    await db.commit()
    return pool


@router.delete("/prefix-pools/{pool_id}")
async def delete_pool(
    pool_id: UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    svc = IPv6PoolService(db)
    await svc.delete_pool(pool_id)
    await db.commit()
    return {"message": "deleted"}


# 分配管理
@router.get("/prefixes", response_model=PoolPrefixList)
async def list_prefixes(
    pool_id: UUID = Query(..., description="前缀池ID"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    svc = IPv6PoolService(db)
    prefixes = await svc.list_prefixes(pool_id)
    return PoolPrefixList(prefixes=prefixes)


@router.post("/prefixes/allocate", response_model=PoolPrefix, status_code=status.HTTP_201_CREATED)
async def allocate_prefix(
    pool_id: UUID = Query(..., description="前缀池ID"),
    assigned_to_type: Optional[str] = Query(None),
    assigned_to_id: Optional[str] = Query(None),
    note: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    svc = IPv6PoolService(db)
    record = await svc.allocate_next(pool_id, assigned_to_type, assigned_to_id, note)
    await db.commit()
    return record


@router.post("/prefixes/{prefix_id}/release")
async def release_prefix(
    prefix_id: UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    svc = IPv6PoolService(db)
    await svc.release(prefix_id)
    await db.commit()
    return {"success": True}


@router.post("/prefixes/reserve", response_model=PoolPrefix, status_code=status.HTTP_201_CREATED)
async def reserve_prefix(
    pool_id: UUID = Query(..., description="前缀池ID"),
    prefix: str = Query(..., description="要保留的前缀"),
    note: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    svc = IPv6PoolService(db)
    record = await svc.reserve(pool_id, prefix, note)
    await db.commit()
    return record