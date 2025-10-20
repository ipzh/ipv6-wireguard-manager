"""
WireGuard管理API端点 - 使用统一API路径构建器
"""
import time
from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException, status, Depends
from app.core.api_path_builder import get_default_path_builder
from app.core.config_enhanced import settings

router = APIRouter()

# 获取API路径构建器实例
def get_path_builder():
    return get_default_path_builder()

@router.get("/config", response_model=None)
async def get_wireguard_config(path_builder=Depends(get_path_builder)):
    """获取WireGuard配置"""
    # 使用路径构建器验证路径
    path_builder.validate_path("wireguard.config")
    
    return {
        "interface": "wg0",
        "listen_port": 51820,
        "private_key": "***hidden***",
        "public_key": "***hidden***",
        "ipv4_address": "10.0.0.1/24",
        "ipv6_address": "fd00::1/64",
        "dns_servers": "8.8.8.8, 1.1.1.1",
        "mtu": 1420,
        "is_active": True
    }

@router.post("/config", response_model=None)
async def update_wireguard_config(
    config_data: Dict[str, Any], 
    path_builder=Depends(get_path_builder)
):
    """更新WireGuard配置"""
    # 使用路径构建器验证路径
    path_builder.validate_path("wireguard.config", method="POST")
    
    return {
        "message": "配置更新成功",
        "config": config_data,
        "timestamp": time.time()
    }

@router.get("/peers", response_model=None)
async def get_peers(path_builder=Depends(get_path_builder)):
    """获取对等节点列表"""
    # 使用路径构建器验证路径
    path_builder.validate_path("wireguard.peers")
    
    return [
        {
            "id": 1,
            "name": "client1",
            "public_key": "***hidden***",
            "allowed_ips": "10.0.0.2/32",
            "endpoint": "192.168.1.100:${WG_PORT}",
            "is_active": True
        },
        {
            "id": 2,
            "name": "client2", 
            "public_key": "***hidden***",
            "allowed_ips": "10.0.0.3/32",
            "endpoint": "192.168.1.101:${WG_PORT}",
            "is_active": True
        }
    ]

@router.post("/peers", response_model=None)
async def create_peer(
    peer_data: Dict[str, Any], 
    path_builder=Depends(get_path_builder)
):
    """创建对等节点"""
    # 使用路径构建器验证路径
    path_builder.validate_path("wireguard.peers", method="POST")
    
    return {
        "id": 3,
        "name": peer_data.get("name", "newpeer"),
        "public_key": "***generated***",
        "allowed_ips": peer_data.get("allowed_ips", "10.0.0.4/32"),
        "endpoint": peer_data.get("endpoint", ""),
        "is_active": True,
        "message": "对等节点创建成功"
    }

@router.get("/peers/{peer_id}", response_model=None)
async def get_peer(
    peer_id: int, 
    path_builder=Depends(get_path_builder)
):
    """获取对等节点详情"""
    # 使用路径构建器验证路径和参数
    path_builder.validate_path("wireguard.peers.detail", params={"peer_id": peer_id})
    
    if peer_id == 1:
        return {
            "id": 1,
            "name": "client1",
            "public_key": "***hidden***",
            "allowed_ips": "10.0.0.2/32",
            "endpoint": "192.168.1.100:${WG_PORT}",
            "is_active": True
        }
    else:
        raise HTTPException(status_code=404, detail="对等节点不存在")

@router.put("/peers/{peer_id}", response_model=None)
async def update_peer(
    peer_id: int, 
    peer_data: Dict[str, Any],
    path_builder=Depends(get_path_builder)
):
    """更新对等节点"""
    # 使用路径构建器验证路径和参数
    path_builder.validate_path("wireguard.peers.detail", params={"peer_id": peer_id}, method="PUT")
    
    return {
        "id": peer_id,
        "name": peer_data.get("name", "updatedpeer"),
        "public_key": "***hidden***",
        "allowed_ips": peer_data.get("allowed_ips", "10.0.0.2/32"),
        "endpoint": peer_data.get("endpoint", ""),
        "is_active": peer_data.get("is_active", True),
        "message": "对等节点更新成功"
    }

@router.delete("/peers/{peer_id}", response_model=None)
async def delete_peer(
    peer_id: int,
    path_builder=Depends(get_path_builder)
):
    """删除对等节点"""
    # 使用路径构建器验证路径和参数
    path_builder.validate_path("wireguard.peers.detail", params={"peer_id": peer_id}, method="DELETE")
    
    return {"message": f"对等节点 {peer_id} 删除成功"}

@router.post("/peers/{peer_id}/restart", response_model=None)
async def restart_peer(
    peer_id: int,
    path_builder=Depends(get_path_builder)
):
    """重启对等节点"""
    # 使用路径构建器验证路径和参数
    path_builder.validate_path("wireguard.peers.restart", params={"peer_id": peer_id}, method="POST")
    
    return {"message": f"对等节点 {peer_id} 重启成功"}

@router.get("/status", response_model=None)
async def get_wireguard_status(path_builder=Depends(get_path_builder)):
    """获取WireGuard状态"""
    # 使用路径构建器验证路径
    path_builder.validate_path("wireguard.status")
    
    return {
        "interface": "wg0",
        "status": "running",
        "peers": 2,
        "bytes_received": 1024000,
        "bytes_sent": 2048000,
        "last_handshake": time.time() - 300
    }

@router.get("/servers", response_model=None)
async def get_servers(path_builder=Depends(get_path_builder)):
    """获取服务器列表"""
    # 使用路径构建器验证路径
    path_builder.validate_path("wireguard.servers")
    
    return [
        {
            "id": 1,
            "name": "Main Server",
            "interface": "wg0",
            "listen_port": 51820,
            "ipv4_address": "10.0.0.1/24",
            "ipv6_address": "fd00::1/64",
            "is_active": True
        }
    ]

@router.get("/clients", response_model=None)
async def get_clients(path_builder=Depends(get_path_builder)):
    """获取客户端列表"""
    # 使用路径构建器验证路径
    path_builder.validate_path("wireguard.clients")
    
    return [
        {
            "id": 1,
            "name": "client1",
            "ipv4_address": "10.0.0.2/32",
            "ipv6_address": "fd00::2/128",
            "is_active": True,
            "last_seen": time.time() - 300
        },
        {
            "id": 2,
            "name": "client2",
            "ipv4_address": "10.0.0.3/32", 
            "ipv6_address": "fd00::3/128",
            "is_active": True,
            "last_seen": time.time() - 600
        }
    ]