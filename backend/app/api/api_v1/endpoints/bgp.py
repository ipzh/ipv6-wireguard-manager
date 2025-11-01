"""
BGP管理API端点
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import Dict, Any, List

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
    if BGPSession is None or BGPSessionSchema is None:
        return {
            "sessions": [],
            "total": 0,
            "message": "BGP会话功能未启用"
        }
    
    try:
        result = await db.execute(select(BGPSession))
        sessions = result.scalars().all()
        
        session_schemas = []
        for session in sessions:
            session_schemas.append(BGPSessionSchema(
                id=session.id,
                name=session.name,
                neighbor=session.remote_ip,
                remote_as=session.remote_as,
                local_as=session.local_as,
                password=session.password,
                enabled=session.is_enabled,
                created_at=session.created_at,
                updated_at=session.updated_at
            ))
        
        return {
            "sessions": session_schemas,
            "total": len(session_schemas),
            "message": "BGP会话获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取BGP会话失败: {str(e)}")


@router.get("/sessions/{session_id}", response_model=None)
async def get_bgp_session(session_id: int, db: AsyncSession = Depends(get_db)):
    """获取单个BGP会话"""
    if BGPSession is None or BGPSessionSchema is None:
        raise HTTPException(status_code=503, detail="BGP会话功能未启用")
    
    try:
        result = await db.execute(select(BGPSession).where(BGPSession.id == session_id))
        session = result.scalars().first()
        
        if not session:
            raise HTTPException(status_code=404, detail="BGP会话不存在")
        
        return BGPSessionSchema(
            id=session.id,
            name=session.name,
            neighbor=session.remote_ip,
            remote_as=session.remote_as,
            local_as=session.local_as,
            password=session.password,
            enabled=session.is_enabled,
            created_at=session.created_at,
            updated_at=session.updated_at
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取BGP会话失败: {str(e)}")


@router.post("/sessions", response_model=None)
async def create_bgp_session(session_data: BGPSessionSchema, db: AsyncSession = Depends(get_db)):
    """创建BGP会话"""
    if BGPSession is None or BGPSessionSchema is None:
        raise HTTPException(status_code=503, detail="BGP会话功能未启用")
    
    try:
        session = BGPSession(
            name=session_data.name,
            remote_ip=session_data.neighbor,
            remote_as=session_data.remote_as,
            local_as=session_data.local_as,
            password=session_data.password,
            is_enabled=session_data.enabled
        )
        
        # 添加会话到数据库
        db.add(session)
        await db.flush()  # 获取ID但不提交
        await db.refresh(session)
        
        # 提交事务
        await db.commit()
        
        # 应用配置（如果服务可用）
        if ExaBGPService:
            try:
                exabgp_service = ExaBGPService(db)
                await exabgp_service.apply_config()
            except Exception as e:
                # 配置应用失败不影响会话创建
                pass
        
        return BGPSessionSchema(
            id=session.id,
            name=session.name,
            neighbor=session.remote_ip,
            remote_as=session.remote_as,
            local_as=session.local_as,
            password=session.password,
            enabled=session.is_enabled,
            created_at=session.created_at,
            updated_at=session.updated_at
        )
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"创建BGP会话失败: {str(e)}")


@router.put("/sessions/{session_id}", response_model=None)
async def update_bgp_session(session_id: int, session_data: BGPSessionSchema, db: AsyncSession = Depends(get_db)):
    """更新BGP会话"""
    if BGPSession is None or BGPSessionSchema is None or ExaBGPService is None:
        raise HTTPException(status_code=503, detail="BGP会话功能未启用")
    
    try:
        result = await db.execute(select(BGPSession).where(BGPSession.id == session_id))
        session = result.scalars().first()
        
        if not session:
            raise HTTPException(status_code=404, detail="BGP会话不存在")
        
        # 更新字段
        session.name = session_data.name
        session.remote_ip = session_data.neighbor
        session.remote_as = session_data.remote_as
        session.local_as = session_data.local_as
        session.password = session_data.password
        session.is_enabled = session_data.enabled
        
        await db.commit()
        await db.refresh(session)
        
        # 应用配置
        exabgp_service = ExaBGPService(db)
        await exabgp_service.apply_config()
        
        return BGPSessionSchema(
            id=session.id,
            name=session.name,
            neighbor=session.remote_ip,
            remote_as=session.remote_as,
            local_as=session.local_as,
            password=session.password,
            enabled=session.is_enabled,
            created_at=session.created_at,
            updated_at=session.updated_at
        )
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"更新BGP会话失败: {str(e)}")


@router.delete("/sessions/{session_id}")
async def delete_bgp_session(session_id: int, db: AsyncSession = Depends(get_db)):
    """删除BGP会话"""
    if BGPSession is None or ExaBGPService is None:
        raise HTTPException(status_code=503, detail="BGP会话功能未启用")
    
    try:
        result = await db.execute(select(BGPSession).where(BGPSession.id == session_id))
        session = result.scalars().first()
        
        if not session:
            raise HTTPException(status_code=404, detail="BGP会话不存在")
        
        await db.delete(session)
        await db.commit()
        
        # 应用配置
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
    if BGPAnnouncement is None or BGPAnnouncementSchema is None:
        return {
            "routes": [],
            "total": 0,
            "message": "BGP路由功能未启用"
        }
    
    try:
        result = await db.execute(select(BGPAnnouncement))
        announcements = result.scalars().all()
        
        announcement_schemas = []
        for announcement in announcements:
            announcement_schemas.append(BGPAnnouncementSchema(
                id=announcement.id,
                prefix=announcement.prefix,
                next_hop=announcement.next_hop,
                session_id=announcement.session_id,
                enabled=announcement.is_active,
                created_at=announcement.created_at,
                updated_at=announcement.updated_at
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
    if ExaBGPService is None or BGPSession is None or BGPAnnouncement is None:
        return {
            "service_status": "disabled",
            "sessions_count": 0,
            "routes_count": 0,
            "enabled_sessions": 0,
            "enabled_routes": 0,
            "message": "BGP功能未启用"
        }
    
    try:
        exabgp_service = ExaBGPService(db)
        status = await exabgp_service.get_status()
        
        # 获取会话和路由统计
        sessions_result = await db.execute(select(BGPSession))
        sessions = sessions_result.scalars().all()
        
        routes_result = await db.execute(select(BGPAnnouncement))
        routes = routes_result.scalars().all()
        
        return {
            "service_status": status,
            "sessions_count": len(sessions),
            "routes_count": len(routes),
            "enabled_sessions": len([s for s in sessions if s.is_enabled]),
            "enabled_routes": len([r for r in routes if r.is_active]),
            "message": "BGP状态获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取BGP状态失败: {str(e)}")