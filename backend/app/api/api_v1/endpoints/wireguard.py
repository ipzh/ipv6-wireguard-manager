"""
WireGuard管理API端点 - 简化版本
"""
import time
from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException, status

router = APIRouter()

@router.get("/config", response_model=None)
async def get_wireguard_config():
    """获取WireGuard配置"""
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
async def update_wireguard_config(config_data: Dict[str, Any]):
    """更新WireGuard配置"""
    return {
        "message": "配置更新成功",
        "config": config_data,
        "timestamp": time.time()
    }

@router.get("/peers", response_model=None)
async def get_peers():
    """获取对等节点列表"""
    return [
        {
            "id": 1,
            "name": "client1",
            "public_key": "***hidden***",
            "allowed_ips": "10.0.0.2/32",
            "endpoint": "192.168.1.100:51820",
            "is_active": True
        },
        {
            "id": 2,
            "name": "client2", 
            "public_key": "***hidden***",
            "allowed_ips": "10.0.0.3/32",
            "endpoint": "192.168.1.101:51820",
            "is_active": True
        }
    ]

@router.post("/peers", response_model=None)
async def create_peer(peer_data: Dict[str, Any]):
    """创建对等节点"""
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
async def get_peer(peer_id: int):
    """获取对等节点详情"""
    if peer_id == 1:
        return {
            "id": 1,
            "name": "client1",
            "public_key": "***hidden***",
            "allowed_ips": "10.0.0.2/32",
            "endpoint": "192.168.1.100:51820",
            "is_active": True
        }
    else:
        raise HTTPException(status_code=404, detail="对等节点不存在")

@router.put("/peers/{peer_id}", response_model=None)
async def update_peer(peer_id: int, peer_data: Dict[str, Any]):
    """更新对等节点"""
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
async def delete_peer(peer_id: int):
    """删除对等节点"""
    return {"message": f"对等节点 {peer_id} 删除成功"}

@router.post("/peers/{peer_id}/restart", response_model=None)
async def restart_peer(peer_id: int):
    """重启对等节点"""
    return {"message": f"对等节点 {peer_id} 重启成功"}

@router.get("/status", response_model=None)
async def get_wireguard_status():
    """获取WireGuard状态"""
    return {
        "interface": "wg0",
        "status": "running",
        "peers": 2,
        "bytes_received": 1024000,
        "bytes_sent": 2048000,
        "last_handshake": time.time() - 300
    }

@router.get("/servers", response_model=None)
async def get_servers():
    """获取服务器列表"""
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
async def get_clients():
    """获取客户端列表"""
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