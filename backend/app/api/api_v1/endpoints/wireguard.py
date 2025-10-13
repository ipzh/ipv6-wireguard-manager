"""
WireGuard管理API端点 - 修复版本
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....schemas.wireguard import WireGuardConfig, WireGuardPeer
from ....services.wireguard_service import WireGuardService

router = APIRouter()


@router.get("/config")
async def get_wireguard_config(db: AsyncSession = Depends(get_async_db)):
    """获取WireGuard配置"""
    wireguard_service = WireGuardService(db)
    config = await wireguard_service.get_config()
    return config


@router.post("/config")
async def update_wireguard_config(
    config: WireGuardConfig, 
    db: AsyncSession = Depends(get_async_db)
):
    """更新WireGuard配置"""
    wireguard_service = WireGuardService(db)
    updated_config = await wireguard_service.update_config(config)
    return updated_config


@router.get("/peers")
async def get_peers(db: AsyncSession = Depends(get_async_db)):
    """获取所有对等节点"""
    wireguard_service = WireGuardService(db)
    peers = await wireguard_service.get_peers()
    return peers


@router.post("/peers")
async def create_peer(peer: WireGuardPeer, db: AsyncSession = Depends(get_async_db)):
    """创建新的对等节点"""
    wireguard_service = WireGuardService(db)
    new_peer = await wireguard_service.create_peer(peer)
    return new_peer


@router.get("/peers/{peer_id}")
async def get_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """获取单个对等节点"""
    wireguard_service = WireGuardService(db)
    peer = await wireguard_service.get_peer(peer_id)
    if not peer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
    return peer


@router.put("/peers/{peer_id}")
async def update_peer(
    peer_id: str, 
    peer: WireGuardPeer, 
    db: AsyncSession = Depends(get_async_db)
):
    """更新对等节点"""
    wireguard_service = WireGuardService(db)
    updated_peer = await wireguard_service.update_peer(peer_id, peer)
    if not updated_peer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
    return updated_peer


@router.delete("/peers/{peer_id}")
async def delete_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """删除对等节点"""
    wireguard_service = WireGuardService(db)
    success = await wireguard_service.delete_peer(peer_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
    return {"message": "对等节点删除成功"}


@router.post("/peers/{peer_id}/restart")
async def restart_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """重启对等节点"""
    wireguard_service = WireGuardService(db)
    success = await wireguard_service.restart_peer(peer_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
    return {"message": "对等节点重启成功"}