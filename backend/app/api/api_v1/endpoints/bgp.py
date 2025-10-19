"""
BGP管理API端点
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import Dict, Any, List
import uuid

from ...core.database import get_db

router = APIRouter()

# 简化的模式和服务，避免依赖不存在的模块
try:
    from ...models.models_complete import BGPSession, BGPAnnouncement
except ImportError:
    BGPSession = None
    BGPAnnouncement = None

try:
    from ...schemas.bgp import BGPSession as BGPSessionSchema, BGPAnnouncement as BGPAnnouncementSchema
except ImportError:
    BGPSessionSchema = None
    BGPAnnouncementSchema = None

try:
    from ...services.exabgp_service import ExaBGPService
except ImportError:
    ExaBGPService = None


@router.get("/sessions", response_model=None)
async def get_bgp_sessions(db: AsyncSession = Depends(get_db)):
    """获取BGP会话列表"""
    try:
        result = await db.execute(select(BGPSession))
        sessions = result.scalars().all()
        
        session_schemas = []
        for session in sessions:
            session_schemas.append(BGPSessionSchema(
                id=session.id,
                name=session.name,
                neighbor=getattr(session, "neighbor", None),
                remote_as=getattr(session, "remote_as", None),
                local_as=getattr(session, "local_as", None),
                password=getattr(session, "password", None),
                enabled=getattr(session, "enabled", True),
                created_at=getattr(session, "created_at", None),
                updated_at=getattr(session, "updated_at", None)
            ))
        
        return {
            "sessions": session_schemas,
            "total": len(session_schemas),
            "message": "BGP会话获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取BGP会话失败: {str(e)}")


@router.get("/sessions/{session_id}", response_model=None)
async def get_bgp_session(session_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """获取单个BGP会话"""
    try:
        result = await db.execute(select(BGPSession).where(BGPSession.id == session_id))
        session = result.scalars().first()
        
        if not session:
            raise HTTPException(status_code=404, detail="BGP会话不存在")
        
        return BGPSessionSchema(
            id=session.id,
            name=session.name,
            neighbor=getattr(session, "neighbor", None),
            remote_as=getattr(session, "remote_as", None),
            local_as=getattr(session, "local_as", None),
            password=getattr(session, "password", None),
            enabled=getattr(session, "enabled", True),
            created_at=getattr(session, "created_at", None),
            updated_at=getattr(session, "updated_at", None)
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取BGP会话失败: {str(e)}")


@router.post("/sessions", response_model=None)
async def create_bgp_session(session_data: BGPSessionSchema, db: AsyncSession = Depends(get_db)):
    """创建BGP会话"""
    try:
        session = BGPSession(
            name=session_data.name,
            neighbor=getattr(session_data, "neighbor", None),
            remote_as=getattr(session_data, "remote_as", None),
            local_as=getattr(session_data, "local_as", None),
            password=getattr(session_data, "password", None),
            enabled=getattr(session_data, "enabled", True)
        )
        
        # 示例代码保留最小化的持久化流程
        db.add(session)
        await db.commit()
        await db.refresh(session)
        
        # 应用配置
        if ExaBGPService:
            exabgp_service = ExaBGPService(db)
            await exabgp_service.apply_config()
        
        return BGPSessionSchema(
            id=session.id,
            name=session.name,
            neighbor=getattr(session, "neighbor", None),
            remote_as=getattr(session, "remote_as", None),
            local_as=getattr(session, "local_as", None),
            password=getattr(session, "password", None),
            enabled=getattr(session, "enabled", True),
            created_at=getattr(session, "created_at", None),
            updated_at=getattr(session, "updated_at", None)
        )
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"创建BGP会话失败: {str(e)}")


@router.put("/sessions/{session_id}", response_model=None)
async def update_bgp_session(session_id: uuid.UUID, session_data: BGPSessionSchema, db: AsyncSession = Depends(get_db)):
    """更新BGP会话"""
    try:
        result = await db.execute(select(BGPSession).where(BGPSession.id == session_id))
        session = result.scalars().first()
        
        if not session:
            raise HTTPException(status_code=404, detail="BGP会话不存在")
        
        # 更新字段（尽可能容错）
        for field in ["name", "neighbor", "remote_as", "local_as", "password", "enabled"]:
            if hasattr(session_data, field) and getattr(session_data, field) is not None:
                setattr(session, field, getattr(session_data, field))
        
        await db.commit()
        await db.refresh(session)
        
        # 应用配置
        if ExaBGPService:
            exabgp_service = ExaBGPService(db)
            await exabgp_service.apply_config()
        
        return BGPSessionSchema(
            id=session.id,
            name=session.name,
            neighbor=getattr(session, "neighbor", None),
            remote_as=getattr(session, "remote_as", None),
            local_as=getattr(session, "local_as", None),
            password=getattr(session, "password", None),
            enabled=getattr(session, "enabled", True),
            created_at=getattr(session, "created_at", None),
            updated_at=getattr(session, "updated_at", None)
        )
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"更新BGP会话失败: {str(e)}")


@router.delete("/sessions/{session_id}")
async def delete_bgp_session(session_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """删除BGP会话"""
    try:
        result = await db.execute(select(BGPSession).where(BGPSession.id == session_id))
        session = result.scalars().first()
        
        if not session:
            raise HTTPException(status_code=404, detail="BGP会话不存在")
        
        await db.delete(session)
        await db.commit()
        
        # 应用配置
        if ExaBGPService:
            exabgp_service = ExaBGPService(db)
            await exabgp_service.apply_config()
        
        return {"message": "BGP会话删除成功"}
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"删除BGP会话失败: {str(e)}")


@router.get("/routes", response_model=None)
async def get_bgp_routes(db: AsyncSession = Depends(get_db)):
    """获取BGP路由宣告"""
    try:
        result = await db.execute(select(BGPAnnouncement))
        announcements = result.scalars().all()
        
        announcement_schemas = []
        for announcement in announcements:
            announcement_schemas.append(BGPAnnouncementSchema(
                id=announcement.id,
                prefix=getattr(announcement, "prefix", None),
                next_hop=getattr(announcement, "next_hop", None),
                session_id=getattr(announcement, "session_id", None),
                enabled=getattr(announcement, "enabled", True),
                created_at=getattr(announcement, "created_at", None),
                updated_at=getattr(announcement, "updated_at", None)
            ))
        
        return {
            "routes": announcement_schemas,
            "total": len(announcement_schemas),
            "message": "BGP路由获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取BGP路由失败: {str(e)}")


@router.get("/status", response_model=None)
async def get_bgp_status(db: AsyncSession = Depends(get_db)):
    """获取BGP服务状态"""
    try:
        if ExaBGPService:
            exabgp_service = ExaBGPService(db)
            status_resp = await exabgp_service.get_status()
        else:
            status_resp = {"status": "unknown"}
        
        # 获取会话和路由统计
        sessions_result = await db.execute(select(BGPSession))
        sessions = sessions_result.scalars().all()
        
        routes_result = await db.execute(select(BGPAnnouncement))
        routes = routes_result.scalars().all()
        
        return {
            "service_status": status_resp,
            "sessions_count": len(sessions),
            "routes_count": len(routes),
            "enabled_sessions": len([s for s in sessions if getattr(s, "enabled", True)]),
            "enabled_routes": len([r for r in routes if getattr(r, "enabled", True)]),
            "message": "BGP状态获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取BGP状态失败: {str(e)}")
