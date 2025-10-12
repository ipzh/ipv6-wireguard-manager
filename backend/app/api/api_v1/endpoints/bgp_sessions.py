"""
BGP会话管理API端点
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
import uuid

from ....core.database import get_db
from ....models.bgp import BGPSession, BGPOperation, SessionStatus
from ....services.bgp_service import bgp_service

router = APIRouter()


class BGPSessionCreate(BaseModel):
    name: str
    neighbor: str
    remote_as: int
    hold_time: Optional[int] = None
    password: Optional[str] = None
    description: Optional[str] = None
    enabled: bool = True


class BGPSessionUpdate(BaseModel):
    name: Optional[str] = None
    neighbor: Optional[str] = None
    remote_as: Optional[int] = None
    hold_time: Optional[int] = None
    password: Optional[str] = None
    description: Optional[str] = None
    enabled: Optional[bool] = None


class BGPSessionResponse(BaseModel):
    id: str
    name: str
    neighbor: str
    remote_as: int
    hold_time: Optional[int]
    description: Optional[str]
    enabled: bool
    status: str
    uptime: int
    prefixes_received: int
    prefixes_sent: int
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


class BGPOperationResponse(BaseModel):
    id: str
    operation_type: str
    status: str
    message: Optional[str]
    error_details: Optional[str]
    started_at: str
    completed_at: Optional[str]

    class Config:
        from_attributes = True


@router.get("/", response_model=List[BGPSessionResponse])
async def get_bgp_sessions(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """获取BGP会话列表"""
    sessions = db.query(BGPSession).offset(skip).limit(limit).all()
    return sessions


@router.get("/{session_id}", response_model=BGPSessionResponse)
async def get_bgp_session(
    session_id: str,
    db: Session = Depends(get_db)
):
    """获取单个BGP会话"""
    session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="BGP会话不存在"
        )
    return session


@router.post("/", response_model=BGPSessionResponse)
async def create_bgp_session(
    session_data: BGPSessionCreate,
    db: Session = Depends(get_db)
):
    """创建BGP会话"""
    # 检查名称是否已存在
    existing = db.query(BGPSession).filter(BGPSession.name == session_data.name).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="BGP会话名称已存在"
        )
    
    session = BGPSession(
        name=session_data.name,
        neighbor=session_data.neighbor,
        remote_as=session_data.remote_as,
        hold_time=session_data.hold_time,
        password=session_data.password,
        description=session_data.description,
        enabled=session_data.enabled
    )
    
    db.add(session)
    db.commit()
    db.refresh(session)
    
    return session


@router.put("/{session_id}", response_model=BGPSessionResponse)
async def update_bgp_session(
    session_id: str,
    session_data: BGPSessionUpdate,
    db: Session = Depends(get_db)
):
    """更新BGP会话"""
    session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="BGP会话不存在"
        )
    
    # 更新字段
    update_data = session_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(session, field, value)
    
    db.commit()
    db.refresh(session)
    
    return session


@router.delete("/{session_id}")
async def delete_bgp_session(
    session_id: str,
    db: Session = Depends(get_db)
):
    """删除BGP会话"""
    session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="BGP会话不存在"
        )
    
    db.delete(session)
    db.commit()
    
    return {"message": "BGP会话删除成功"}


@router.post("/{session_id}/reload")
async def reload_bgp_session(
    session_id: str,
    db: Session = Depends(get_db)
):
    """重载BGP会话配置"""
    session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="BGP会话不存在"
        )
    
    result = await bgp_service.reload_exabgp(session_id)
    
    if result["success"]:
        return {
            "message": result["message"],
            "operation_id": result.get("operation_id")
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=result["message"]
        )


@router.post("/{session_id}/restart")
async def restart_bgp_session(
    session_id: str,
    db: Session = Depends(get_db)
):
    """重启BGP会话"""
    session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="BGP会话不存在"
        )
    
    result = await bgp_service.restart_exabgp(session_id)
    
    if result["success"]:
        return {
            "message": result["message"],
            "operation_id": result.get("operation_id")
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=result["message"]
        )


@router.get("/{session_id}/status")
async def get_bgp_session_status(
    session_id: str,
    db: Session = Depends(get_db)
):
    """获取BGP会话状态"""
    session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="BGP会话不存在"
        )
    
    status_data = await bgp_service.get_session_status(session_id)
    return status_data


@router.get("/{session_id}/operations", response_model=List[BGPOperationResponse])
async def get_bgp_session_operations(
    session_id: str,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    """获取BGP会话操作历史"""
    session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="BGP会话不存在"
        )
    
    operations = db.query(BGPOperation).filter(
        BGPOperation.session_id == session_id
    ).order_by(BGPOperation.started_at.desc()).offset(skip).limit(limit).all()
    
    return operations


@router.post("/batch/reload")
async def batch_reload_bgp_sessions(
    session_ids: List[str],
    db: Session = Depends(get_db)
):
    """批量重载BGP会话"""
    results = []
    
    for session_id in session_ids:
        session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
        if session:
            result = await bgp_service.reload_exabgp(session_id)
            results.append({
                "session_id": session_id,
                "session_name": session.name,
                "success": result["success"],
                "message": result["message"]
            })
        else:
            results.append({
                "session_id": session_id,
                "session_name": None,
                "success": False,
                "message": "BGP会话不存在"
            })
    
    return {
        "message": "批量重载完成",
        "results": results
    }


@router.post("/batch/restart")
async def batch_restart_bgp_sessions(
    session_ids: List[str],
    db: Session = Depends(get_db)
):
    """批量重启BGP会话"""
    results = []
    
    for session_id in session_ids:
        session = db.query(BGPSession).filter(BGPSession.id == session_id).first()
        if session:
            result = await bgp_service.restart_exabgp(session_id)
            results.append({
                "session_id": session_id,
                "session_name": session.name,
                "success": result["success"],
                "message": result["message"]
            })
        else:
            results.append({
                "session_id": session_id,
                "session_name": None,
                "success": False,
                "message": "BGP会话不存在"
            })
    
    return {
        "message": "批量重启完成",
        "results": results
    }
