"""
BGP管理API端点：会话与宣告
"""
from typing import Any, List
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....core.security import get_current_user_id
from ....schemas.bgp import (
    BGPSession, BGPSessionCreate, BGPSessionUpdate,
    BGPAnnouncement, BGPAnnouncementCreate, BGPAnnouncementUpdate,
    BGPAnnouncementList
)
from ....services.bgp_service import BGPService
from ....services.exabgp_service import ExaBGPService

router = APIRouter()


# 会话端点
@router.get("/sessions", response_model=List[BGPSession])
async def list_sessions(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    service = BGPService(db)
    return await service.list_sessions()


@router.post("/sessions", response_model=BGPSession, status_code=status.HTTP_201_CREATED)
async def create_session(
    data: BGPSessionCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    service = BGPService(db)
    session = await service.create_session(data)
    await db.commit()
    return session


@router.patch("/sessions/{session_id}", response_model=BGPSession)
async def update_session(
    session_id: UUID,
    data: BGPSessionUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    service = BGPService(db)
    session = await service.update_session(session_id, data)
    await db.commit()
    if not session:
        raise HTTPException(status_code=404, detail="会话不存在")
    return session


@router.delete("/sessions/{session_id}")
async def delete_session(
    session_id: UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    service = BGPService(db)
    await service.delete_session(session_id)
    await db.commit()
    return {"message": "deleted"}


# 宣告端点
@router.get("/announcements", response_model=BGPAnnouncementList)
async def list_announcements(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    service = BGPService(db)
    anns = await service.list_announcements()
    # 前端NetworkPage期望 { announcements: [...] }
    return BGPAnnouncementList(announcements=anns)


@router.post("/announcements", response_model=BGPAnnouncement, status_code=status.HTTP_201_CREATED)
async def create_announcement(
    data: BGPAnnouncementCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    service = BGPService(db)
    ann = await service.create_announcement(data)
    await db.commit()
    return ann


@router.patch("/announcements/{ann_id}", response_model=BGPAnnouncement)
async def update_announcement(
    ann_id: UUID,
    data: BGPAnnouncementUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    service = BGPService(db)
    ann = await service.update_announcement(ann_id, data)
    await db.commit()
    if not ann:
        raise HTTPException(status_code=404, detail="宣告不存在")
    return ann


@router.delete("/announcements/{ann_id}")
async def delete_announcement(
    ann_id: UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    service = BGPService(db)
    await service.delete_announcement(ann_id)
    await db.commit()
    return {"message": "deleted"}


# ExaBGP集成：应用配置
@router.post("/apply")
async def apply_bgp_config(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    exa = ExaBGPService(db)
    ok = await exa.apply_config()
    return {"success": ok}


# ExaBGP集成：状态查询
@router.get("/status")
async def get_bgp_status(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    exa = ExaBGPService(db)
    return await exa.get_status()