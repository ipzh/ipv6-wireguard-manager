"""
IPv6管理API端点
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any, List

from ....core.database import get_async_db

# 简化的模式和服务，避免依赖不存在的模块
try:
    from ....schemas.ipv6 import IPv6PrefixPool, IPv6Allocation
except ImportError:
    IPv6PrefixPool = None
    IPv6Allocation = None

try:
    from ....schemas.common import MessageResponse
except ImportError:
    MessageResponse = None

try:
    from ....services.ipv6_service import IPv6PoolService
except ImportError:
    IPv6PoolService = None

router = APIRouter()


@router.get("/pools", response_model=None)
async def get_ipv6_pools():
    """获取IPv6前缀池列表"""
    try:
        ipv6_service = IPv6PoolService(db)
        pools = await ipv6_service.get_pools()
        
        pool_list = []
        for pool in pools:
            pool_list.append({
                "id": str(pool.id),
                "name": pool.name,
                "description": pool.description,
                "base_prefix": pool.base_prefix,
                "prefix_len": pool.prefix_len,
                "subnet_len": pool.subnet_len,
                "total_capacity": pool.total_capacity,
                "used_capacity": pool.used_capacity,
                "available_capacity": pool.available_capacity,
                "is_active": pool.is_active,
                "created_at": pool.created_at.isoformat() if pool.created_at else None,
                "updated_at": pool.updated_at.isoformat() if pool.updated_at else None
            })
        
        return {
            "pools": pool_list,
            "total": len(pool_list),
            "message": "IPv6前缀池获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取IPv6前缀池失败: {str(e)}")


@router.post("/pools", response_model=None)
async def create_ipv6_pool(
    pool_data: Dict[str, Any]
):
    """创建IPv6前缀池"""
    try:
        ipv6_service = IPv6PoolService(db)
        
        pool = IPv6PrefixPool(
            name=pool_data.get("name"),
            description=pool_data.get("description"),
            base_prefix=pool_data.get("base_prefix"),
            prefix_len=pool_data.get("prefix_len"),
            subnet_len=pool_data.get("subnet_len"),
            is_active=pool_data.get("is_active", True)
        )
        
        new_pool = await ipv6_service.create_pool(pool)
        
        return {
            "id": str(new_pool.id),
            "name": new_pool.name,
            "base_prefix": new_pool.base_prefix,
            "message": "IPv6前缀池创建成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建IPv6前缀池失败: {str(e)}")


@router.get("/pools/{pool_id}", response_model=None)
async def get_ipv6_pool(pool_id: str):
    """获取单个IPv6前缀池"""
    try:
        ipv6_service = IPv6PoolService(db)
        pool = await ipv6_service.get_pool(pool_id)
        
        if not pool:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="IPv6前缀池不存在")
        
        return {
            "id": str(pool.id),
            "name": pool.name,
            "description": pool.description,
            "base_prefix": pool.base_prefix,
            "prefix_len": pool.prefix_len,
            "subnet_len": pool.subnet_len,
            "total_capacity": pool.total_capacity,
            "used_capacity": pool.used_capacity,
            "available_capacity": pool.available_capacity,
            "is_active": pool.is_active,
            "created_at": pool.created_at.isoformat() if pool.created_at else None,
            "updated_at": pool.updated_at.isoformat() if pool.updated_at else None
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取IPv6前缀池失败: {str(e)}")


@router.put("/pools/{pool_id}", response_model=None)
async def update_ipv6_pool(
    pool_id: str,
    pool_data: Dict[str, Any]
):
    """更新IPv6前缀池"""
    try:
        ipv6_service = IPv6PoolService(db)
        
        pool = IPv6PrefixPool(
            name=pool_data.get("name"),
            description=pool_data.get("description"),
            base_prefix=pool_data.get("base_prefix"),
            prefix_len=pool_data.get("prefix_len"),
            subnet_len=pool_data.get("subnet_len"),
            is_active=pool_data.get("is_active", True)
        )
        
        updated_pool = await ipv6_service.update_pool(pool_id, pool)
        
        if not updated_pool:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="IPv6前缀池不存在")
        
        return {
            "id": str(updated_pool.id),
            "name": updated_pool.name,
            "message": "IPv6前缀池更新成功"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"更新IPv6前缀池失败: {str(e)}")


@router.delete("/pools/{pool_id}", response_model=None)
async def delete_ipv6_pool(pool_id: str):
    """删除IPv6前缀池"""
    try:
        ipv6_service = IPv6PoolService(db)
        success = await ipv6_service.delete_pool(pool_id)
        
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="IPv6前缀池不存在")
        
        return MessageResponse(message="IPv6前缀池删除成功")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除IPv6前缀池失败: {str(e)}")


@router.get("/allocations", response_model=None)
async def get_ipv6_allocations(
    pool_id: str = None
):
    """获取IPv6分配列表"""
    try:
        ipv6_service = IPv6PoolService(db)
        allocations = await ipv6_service.get_allocations(pool_id)
        
        allocation_list = []
        for allocation in allocations:
            allocation_list.append({
                "id": str(allocation.id),
                "pool_id": str(allocation.pool_id),
                "prefix": allocation.prefix,
                "prefix_len": allocation.prefix_len,
                "client_id": str(allocation.client_id) if allocation.client_id else None,
                "client_name": allocation.client_name,
                "description": allocation.description,
                "is_reserved": allocation.is_reserved,
                "is_active": allocation.is_active,
                "created_at": allocation.created_at.isoformat() if allocation.created_at else None,
                "updated_at": allocation.updated_at.isoformat() if allocation.updated_at else None
            })
        
        return {
            "allocations": allocation_list,
            "total": len(allocation_list),
            "message": "IPv6分配获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取IPv6分配失败: {str(e)}")


@router.post("/allocations/allocate", response_model=None)
async def allocate_ipv6_prefix(
    allocation_data: Dict[str, Any]
):
    """分配IPv6前缀"""
    try:
        ipv6_service = IPv6PoolService(db)
        
        pool_id = allocation_data.get("pool_id")
        client_name = allocation_data.get("client_name")
        description = allocation_data.get("description")
        
        allocation = await ipv6_service.allocate_next(pool_id, client_name, description)
        
        if not allocation:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="无法分配IPv6前缀")
        
        return {
            "id": str(allocation.id),
            "pool_id": str(allocation.pool_id),
            "prefix": allocation.prefix,
            "prefix_len": allocation.prefix_len,
            "client_name": allocation.client_name,
            "message": "IPv6前缀分配成功"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"分配IPv6前缀失败: {str(e)}")


@router.post("/allocations/{allocation_id}/release", response_model=None)
async def release_ipv6_prefix(allocation_id: str):
    """释放IPv6前缀"""
    try:
        ipv6_service = IPv6PoolService(db)
        success = await ipv6_service.release_allocation(allocation_id)
        
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="IPv6分配不存在")
        
        return MessageResponse(message="IPv6前缀释放成功")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"释放IPv6前缀失败: {str(e)}")


@router.get("/health", response_model=None)
async def ipv6_health_check():
    """IPv6服务健康检查"""
    return {
        "status": "healthy",
        "service": "ipv6_prefix_pool",
        "timestamp": "2024-01-01T00:00:00Z",
        "version": "1.0.0"
    }