"""
网络管理API端点
"""
import psutil
import socket
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any, List

from ....core.database import get_async_db
from ....schemas.network import NetworkInterface, NetworkStatus
from ....schemas.common import MessageResponse

router = APIRouter()


@router.get("/interfaces", response_model=None)
async def get_network_interfaces(db: AsyncSession = Depends(get_async_db)):
    """获取网络接口信息"""
    try:
        interfaces = []
        
        # 获取系统网络接口信息
        net_io_counters = psutil.net_io_counters(pernic=True)
        net_if_addrs = psutil.net_if_addrs()
        net_if_stats = psutil.net_if_stats()
        
        for interface_name, addrs in net_if_addrs.items():
            interface_info = {
                "name": interface_name,
                "addresses": [],
                "stats": {},
                "io_counters": {}
            }
            
            # 获取接口地址信息
            for addr in addrs:
                interface_info["addresses"].append({
                    "family": addr.family.name,
                    "address": addr.address,
                    "netmask": addr.netmask if hasattr(addr, 'netmask') else None,
                    "broadcast": addr.broadcast if hasattr(addr, 'broadcast') else None
                })
            
            # 获取接口统计信息
            if interface_name in net_if_stats:
                stats = net_if_stats[interface_name]
                interface_info["stats"] = {
                    "is_up": stats.isup,
                    "duplex": stats.duplex.name,
                    "speed": stats.speed,
                    "mtu": stats.mtu
                }
            
            # 获取接口IO计数器
            if interface_name in net_io_counters:
                io = net_io_counters[interface_name]
                interface_info["io_counters"] = {
                    "bytes_sent": io.bytes_sent,
                    "bytes_recv": io.bytes_recv,
                    "packets_sent": io.packets_sent,
                    "packets_recv": io.packets_recv,
                    "errin": io.errin,
                    "errout": io.errout,
                    "dropin": io.dropin,
                    "dropout": io.dropout
                }
            
            interfaces.append(interface_info)
        
        return {
            "interfaces": interfaces,
            "total": len(interfaces),
            "message": "网络接口信息获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取网络接口信息失败: {str(e)}")


@router.get("/status", response_model=None)
async def get_network_status(db: AsyncSession = Depends(get_async_db)):
    """获取网络状态"""
    try:
        # 获取网络连接状态
        connections = psutil.net_connections(kind='inet')
        
        # 获取网络IO统计
        net_io = psutil.net_io_counters()
        
        # 检查网络连通性
        connectivity = {
            "internet": False,
            "dns": False,
            "gateway": False
        }
        
        # 简单检查互联网连通性
        try:
            socket.create_connection(("8.8.8.8", 53), timeout=3)
            connectivity["internet"] = True
        except:
            connectivity["internet"] = False
        
        # 检查DNS解析
        try:
            socket.gethostbyname("google.com")
            connectivity["dns"] = True
        except:
            connectivity["dns"] = False
        
        return {
            "status": "healthy",
            "connectivity": connectivity,
            "connections": len(connections),
            "bytes_sent": net_io.bytes_sent,
            "bytes_recv": net_io.bytes_recv,
            "packets_sent": net_io.packets_sent,
            "packets_recv": net_io.packets_recv,
            "message": "网络状态正常"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取网络状态失败: {str(e)}")


@router.get("/connections", response_model=None)
async def get_network_connections(db: AsyncSession = Depends(get_async_db)):
    """获取网络连接信息"""
    try:
        connections = psutil.net_connections(kind='inet')
        
        connection_list = []
        for conn in connections:
            connection_info = {
                "fd": conn.fd,
                "family": conn.family.name,
                "type": conn.type.name,
                "laddr": f"{conn.laddr.ip}:{conn.laddr.port}" if conn.laddr else None,
                "raddr": f"{conn.raddr.ip}:{conn.raddr.port}" if conn.raddr else None,
                "status": conn.status,
                "pid": conn.pid
            }
            connection_list.append(connection_info)
        
        return {
            "connections": connection_list,
            "total": len(connection_list),
            "message": "网络连接信息获取成功"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取网络连接信息失败: {str(e)}")


@router.get("/health", response_model=None)
async def network_health_check():
    """网络服务健康检查"""
    return {
        "status": "healthy",
        "service": "network_management",
        "timestamp": "2024-01-01T00:00:00Z",
        "version": "1.0.0"
    }