"""
WireGuard管理API端点 - 修复版本
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

from ....core.database import get_async_db
from ....schemas.wireguard import WireGuardConfig, WireGuardPeer, WireGuardStatus
from ....schemas.common import MessageResponse
from ....services.wireguard_service import WireGuardService

router = APIRouter()


@router.get("/config", response_model=None)
async def get_wireguard_config(db: AsyncSession = Depends(get_async_db)):
    """获取WireGuard配置"""
    try:
        wireguard_service = WireGuardService(db)
        config = await wireguard_service.get_config()
        return config
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取WireGuard配置失败: {str(e)}")


@router.post("/config", response_model=None)
async def update_wireguard_config(
    config: WireGuardConfig, 
    db: AsyncSession = Depends(get_async_db)
):
    """更新WireGuard配置"""
    try:
        wireguard_service = WireGuardService(db)
        updated_config = await wireguard_service.update_config(config)
        return updated_config
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"更新WireGuard配置失败: {str(e)}")


@router.get("/peers", response_model=None)
async def get_peers(db: AsyncSession = Depends(get_async_db)):
    """获取所有对等节点"""
    try:
        wireguard_service = WireGuardService(db)
        peers = await wireguard_service.get_peers()
        return peers
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取对等节点失败: {str(e)}")


@router.post("/peers", response_model=None)
async def create_peer(peer: WireGuardPeer, db: AsyncSession = Depends(get_async_db)):
    """创建新的对等节点"""
    try:
        wireguard_service = WireGuardService(db)
        new_peer = await wireguard_service.create_peer(peer)
        return new_peer
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建对等节点失败: {str(e)}")


@router.get("/peers/{peer_id}", response_model=None)
async def get_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """获取单个对等节点"""
    try:
        wireguard_service = WireGuardService(db)
        peer = await wireguard_service.get_peer(peer_id)
        if not peer:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
        return peer
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取对等节点失败: {str(e)}")


@router.put("/peers/{peer_id}", response_model=None)
async def update_peer(
    peer_id: str, 
    peer: WireGuardPeer, 
    db: AsyncSession = Depends(get_async_db)
):
    """更新对等节点"""
    try:
        wireguard_service = WireGuardService(db)
        updated_peer = await wireguard_service.update_peer(peer_id, peer)
        if not updated_peer:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
        return updated_peer
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"更新对等节点失败: {str(e)}")


@router.delete("/peers/{peer_id}", response_model=None)
async def delete_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """删除对等节点"""
    try:
        wireguard_service = WireGuardService(db)
        success = await wireguard_service.delete_peer(peer_id)
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
        return MessageResponse(message="对等节点删除成功")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除对等节点失败: {str(e)}")


@router.post("/peers/{peer_id}/restart", response_model=None)
async def restart_peer(peer_id: str, db: AsyncSession = Depends(get_async_db)):
    """重启对等节点"""
    try:
        wireguard_service = WireGuardService(db)
        success = await wireguard_service.restart_peer(peer_id)
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="对等节点不存在")
        return MessageResponse(message="对等节点重启成功")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"重启对等节点失败: {str(e)}")


@router.get("/status", response_model=None)
async def get_wireguard_status(db: AsyncSession = Depends(get_async_db)):
    """获取WireGuard状态"""
    try:
        wireguard_service = WireGuardService(db)
        status = await wireguard_service.get_status()
        return status
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取WireGuard状态失败: {str(e)}")


@router.get("/servers", response_model=None)
async def get_servers(db: AsyncSession = Depends(get_async_db)):
    """获取WireGuard服务器列表"""
    try:
        wireguard_service = WireGuardService(db)
        servers = await wireguard_service.get_servers()
        
        server_list = []
        for server in servers:
            server_list.append({
                "id": str(server.id),
                "name": server.name,
                "interface": server.interface,
                "listen_port": server.listen_port,
                "ipv4_address": server.ipv4_address,
                "ipv6_address": server.ipv6_address,
                "dns_servers": server.dns_servers,
                "mtu": server.mtu,
                "public_key": server.public_key,
                "config_file_path": server.config_file_path
            })
        
        return {
            "servers": server_list,
            "total": len(server_list),
            "message": "WireGuard服务器获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取WireGuard服务器失败: {str(e)}")


@router.get("/clients", response_model=None)
async def get_clients(db: AsyncSession = Depends(get_async_db)):
    """获取WireGuard客户端列表"""
    try:
        wireguard_service = WireGuardService(db)
        clients = await wireguard_service.get_all_clients()
        
        client_list = []
        for client in clients:
            client_list.append({
                "id": str(client.id),
                "name": client.name,
                "description": client.description,
                "server_id": str(client.server_id),
                "ipv4_address": client.ipv4_address,
                "ipv6_address": client.ipv6_address,
                "allowed_ips": client.allowed_ips,
                "persistent_keepalive": client.persistent_keepalive,
                "public_key": client.public_key,
                "config_file_path": client.config_file_path,
                "qr_code": client.qr_code
            })
        
        return {
            "clients": client_list,
            "total": len(client_list),
            "message": "WireGuard客户端获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取WireGuard客户端失败: {str(e)}")