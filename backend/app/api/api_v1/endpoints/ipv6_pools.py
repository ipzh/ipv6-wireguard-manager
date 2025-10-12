"""
IPv6前缀池管理API端点
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
import uuid

from ....core.database import get_db
from ....models.ipv6_pool import IPv6PrefixPool, IPv6Allocation, IPv6Whitelist, BGPAlert, PoolStatus
from ....services.bgp_service import bgp_service

router = APIRouter()


class IPv6PrefixPoolCreate(BaseModel):
    name: str
    prefix: str
    prefix_length: int
    total_capacity: int
    description: Optional[str] = None
    auto_announce: bool = False
    max_prefix_limit: Optional[int] = None
    whitelist_enabled: bool = False
    rpki_enabled: bool = False
    enabled: bool = True


class IPv6PrefixPoolUpdate(BaseModel):
    name: Optional[str] = None
    prefix: Optional[str] = None
    prefix_length: Optional[int] = None
    total_capacity: Optional[int] = None
    description: Optional[str] = None
    auto_announce: Optional[bool] = None
    max_prefix_limit: Optional[int] = None
    whitelist_enabled: Optional[bool] = None
    rpki_enabled: Optional[bool] = None
    enabled: Optional[bool] = None


class IPv6PrefixPoolResponse(BaseModel):
    id: str
    name: str
    prefix: str
    prefix_length: int
    total_capacity: int
    used_count: int
    status: str
    description: Optional[str]
    auto_announce: bool
    max_prefix_limit: Optional[int]
    whitelist_enabled: bool
    rpki_enabled: bool
    enabled: bool
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


class IPv6AllocationResponse(BaseModel):
    id: str
    pool_id: str
    client_id: Optional[str]
    allocated_prefix: str
    allocated_at: str
    released_at: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


class IPv6WhitelistCreate(BaseModel):
    prefix: str
    description: Optional[str] = None
    enabled: bool = True


class IPv6WhitelistResponse(BaseModel):
    id: str
    pool_id: str
    prefix: str
    description: Optional[str]
    enabled: bool
    created_at: str

    class Config:
        from_attributes = True


class BGPAlertResponse(BaseModel):
    id: str
    alert_type: str
    severity: str
    message: str
    prefix: Optional[str]
    session_id: Optional[str]
    pool_id: Optional[str]
    is_resolved: bool
    resolved_at: Optional[str]
    created_at: str

    class Config:
        from_attributes = True


@router.get("/", response_model=List[IPv6PrefixPoolResponse])
async def get_ipv6_pools(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """获取IPv6前缀池列表"""
    pools = db.query(IPv6PrefixPool).offset(skip).limit(limit).all()
    return pools


@router.get("/{pool_id}", response_model=IPv6PrefixPoolResponse)
async def get_ipv6_pool(
    pool_id: str,
    db: Session = Depends(get_db)
):
    """获取单个IPv6前缀池"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    return pool


@router.post("/", response_model=IPv6PrefixPoolResponse)
async def create_ipv6_pool(
    pool_data: IPv6PrefixPoolCreate,
    db: Session = Depends(get_db)
):
    """创建IPv6前缀池"""
    # 检查名称是否已存在
    existing = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.name == pool_data.name).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="IPv6前缀池名称已存在"
        )
    
    pool = IPv6PrefixPool(
        name=pool_data.name,
        prefix=pool_data.prefix,
        prefix_length=pool_data.prefix_length,
        total_capacity=pool_data.total_capacity,
        description=pool_data.description,
        auto_announce=pool_data.auto_announce,
        max_prefix_limit=pool_data.max_prefix_limit,
        whitelist_enabled=pool_data.whitelist_enabled,
        rpki_enabled=pool_data.rpki_enabled,
        enabled=pool_data.enabled
    )
    
    db.add(pool)
    db.commit()
    db.refresh(pool)
    
    return pool


@router.put("/{pool_id}", response_model=IPv6PrefixPoolResponse)
async def update_ipv6_pool(
    pool_id: str,
    pool_data: IPv6PrefixPoolUpdate,
    db: Session = Depends(get_db)
):
    """更新IPv6前缀池"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    # 更新字段
    update_data = pool_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(pool, field, value)
    
    db.commit()
    db.refresh(pool)
    
    return pool


@router.delete("/{pool_id}")
async def delete_ipv6_pool(
    pool_id: str,
    db: Session = Depends(get_db)
):
    """删除IPv6前缀池"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    # 检查是否有活跃的分配
    active_allocations = db.query(IPv6Allocation).filter(
        IPv6Allocation.pool_id == pool_id,
        IPv6Allocation.is_active == True
    ).count()
    
    if active_allocations > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"无法删除前缀池，仍有 {active_allocations} 个活跃分配"
        )
    
    db.delete(pool)
    db.commit()
    
    return {"message": "IPv6前缀池删除成功"}


@router.post("/{pool_id}/allocate")
async def allocate_ipv6_prefix(
    pool_id: str,
    client_id: str,
    auto_announce: bool = False,
    db: Session = Depends(get_db)
):
    """分配IPv6前缀"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    if not pool.enabled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="IPv6前缀池已禁用"
        )
    
    result = await bgp_service.allocate_ipv6_prefix(pool_id, client_id, auto_announce)
    
    if result["success"]:
        return {
            "message": result["message"],
            "allocated_prefix": result["allocated_prefix"],
            "allocation_id": result["allocation_id"]
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["message"]
        )


@router.post("/{pool_id}/release/{allocation_id}")
async def release_ipv6_prefix(
    pool_id: str,
    allocation_id: str,
    db: Session = Depends(get_db)
):
    """释放IPv6前缀"""
    result = await bgp_service.release_ipv6_prefix(allocation_id)
    
    if result["success"]:
        return {
            "message": result["message"],
            "released_prefix": result["released_prefix"]
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["message"]
        )


@router.get("/{pool_id}/allocations", response_model=List[IPv6AllocationResponse])
async def get_pool_allocations(
    pool_id: str,
    skip: int = 0,
    limit: int = 100,
    active_only: bool = False,
    db: Session = Depends(get_db)
):
    """获取前缀池的分配记录"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    query = db.query(IPv6Allocation).filter(IPv6Allocation.pool_id == pool_id)
    
    if active_only:
        query = query.filter(IPv6Allocation.is_active == True)
    
    allocations = query.order_by(IPv6Allocation.allocated_at.desc()).offset(skip).limit(limit).all()
    
    return allocations


@router.get("/{pool_id}/whitelist", response_model=List[IPv6WhitelistResponse])
async def get_pool_whitelist(
    pool_id: str,
    db: Session = Depends(get_db)
):
    """获取前缀池的白名单"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    whitelist = db.query(IPv6Whitelist).filter(
        IPv6Whitelist.pool_id == pool_id
    ).all()
    
    return whitelist


@router.post("/{pool_id}/whitelist", response_model=IPv6WhitelistResponse)
async def add_whitelist_entry(
    pool_id: str,
    whitelist_data: IPv6WhitelistCreate,
    db: Session = Depends(get_db)
):
    """添加白名单条目"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    whitelist_entry = IPv6Whitelist(
        pool_id=pool_id,
        prefix=whitelist_data.prefix,
        description=whitelist_data.description,
        enabled=whitelist_data.enabled
    )
    
    db.add(whitelist_entry)
    db.commit()
    db.refresh(whitelist_entry)
    
    return whitelist_entry


@router.delete("/{pool_id}/whitelist/{whitelist_id}")
async def remove_whitelist_entry(
    pool_id: str,
    whitelist_id: str,
    db: Session = Depends(get_db)
):
    """删除白名单条目"""
    whitelist_entry = db.query(IPv6Whitelist).filter(
        IPv6Whitelist.id == whitelist_id,
        IPv6Whitelist.pool_id == pool_id
    ).first()
    
    if not whitelist_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="白名单条目不存在"
        )
    
    db.delete(whitelist_entry)
    db.commit()
    
    return {"message": "白名单条目删除成功"}


@router.post("/{pool_id}/validate-rpki")
async def validate_rpki(
    pool_id: str,
    prefix: str,
    db: Session = Depends(get_db)
):
    """验证RPKI"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    if not pool.rpki_enabled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该前缀池未启用RPKI验证"
        )
    
    result = await bgp_service.check_rpki_validation(prefix)
    
    return result


@router.get("/{pool_id}/alerts", response_model=List[BGPAlertResponse])
async def get_pool_alerts(
    pool_id: str,
    skip: int = 0,
    limit: int = 50,
    resolved_only: bool = False,
    db: Session = Depends(get_db)
):
    """获取前缀池的告警"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    query = db.query(BGPAlert).filter(BGPAlert.pool_id == pool_id)
    
    if resolved_only:
        query = query.filter(BGPAlert.is_resolved == True)
    
    alerts = query.order_by(BGPAlert.created_at.desc()).offset(skip).limit(limit).all()
    
    return alerts


@router.post("/{pool_id}/alerts")
async def create_pool_alert(
    pool_id: str,
    alert_type: str,
    severity: str,
    message: str,
    prefix: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """创建前缀池告警"""
    pool = db.query(IPv6PrefixPool).filter(IPv6PrefixPool.id == pool_id).first()
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="IPv6前缀池不存在"
        )
    
    result = await bgp_service.create_alert(
        alert_type=alert_type,
        severity=severity,
        message=message,
        prefix=prefix,
        pool_id=pool_id
    )
    
    if result["success"]:
        return {
            "message": result["message"],
            "alert_id": result["alert_id"]
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=result["message"]
        )
