"""
WebSocket API端点 - 优化版本
"""
import asyncio
import json
import psutil
import time
from datetime import datetime
from typing import Dict, Any, List
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....services.wireguard_service import WireGuardService
from ....services.monitoring_service import MonitoringService
from ....services.alert_service import AlertService

router = APIRouter()

# WebSocket连接管理器
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.connection_data: Dict[WebSocket, Dict[str, Any]] = {}

    async def connect(self, websocket: WebSocket, user_id: str = None):
        await websocket.accept()
        self.active_connections.append(websocket)
        self.connection_data[websocket] = {
            "user_id": user_id,
            "connected_at": datetime.now(),
            "subscriptions": set()
        }

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if websocket in self.connection_data:
            del self.connection_data[websocket]

    async def send_personal_message(self, message: str, websocket: WebSocket):
        try:
            await websocket.send_text(message)
        except Exception as e:
            print(f"发送消息失败: {e}")
            self.disconnect(websocket)

    async def broadcast(self, message: str, subscription_type: str = None):
        disconnected = []
        for connection in self.active_connections:
            try:
                # 检查订阅
                if subscription_type and connection in self.connection_data:
                    subscriptions = self.connection_data[connection].get("subscriptions", set())
                    if subscription_type not in subscriptions:
                        continue
                
                await connection.send_text(message)
            except Exception as e:
                print(f"广播消息失败: {e}")
                disconnected.append(connection)
        
        # 清理断开的连接
        for connection in disconnected:
            self.disconnect(connection)

    def subscribe(self, websocket: WebSocket, subscription_type: str):
        if websocket in self.connection_data:
            self.connection_data[websocket]["subscriptions"].add(subscription_type)

    def unsubscribe(self, websocket: WebSocket, subscription_type: str):
        if websocket in self.connection_data:
            self.connection_data[websocket]["subscriptions"].discard(subscription_type)

manager = ConnectionManager()

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket连接端点"""
    await manager.connect(websocket)
    try:
        while True:
            # 接收客户端消息
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # 处理订阅请求
            if message.get("type") == "subscribe":
                subscription_type = message.get("subscription")
                if subscription_type:
                    manager.subscribe(websocket, subscription_type)
                    await manager.send_personal_message(
                        json.dumps({
                            "type": "subscription_confirmed",
                            "subscription": subscription_type
                        }), 
                        websocket
                    )
            
            # 处理取消订阅请求
            elif message.get("type") == "unsubscribe":
                subscription_type = message.get("subscription")
                if subscription_type:
                    manager.unsubscribe(websocket, subscription_type)
                    await manager.send_personal_message(
                        json.dumps({
                            "type": "unsubscription_confirmed",
                            "subscription": subscription_type
                        }), 
                        websocket
                    )
            
            # 处理ping请求
            elif message.get("type") == "ping":
                await manager.send_personal_message(
                    json.dumps({
                        "type": "pong",
                        "timestamp": time.time()
                    }), 
                    websocket
                )
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        print(f"WebSocket错误: {e}")
        manager.disconnect(websocket)

# 系统指标数据流
async def system_metrics_stream():
    """系统指标数据流"""
    while True:
        try:
            # 获取系统指标
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            network = psutil.net_io_counters()
            
            # 获取负载平均值
            load_avg = psutil.getloadavg() if hasattr(psutil, 'getloadavg') else (0, 0, 0)
            
            metrics = {
                "type": "system_metrics",
                "timestamp": time.time(),
                "data": {
                    "cpu": {
                        "percent": cpu_percent,
                        "count": psutil.cpu_count()
                    },
                    "memory": {
                        "total": memory.total,
                        "available": memory.available,
                        "percent": memory.percent,
                        "used": memory.used
                    },
                    "disk": {
                        "total": disk.total,
                        "used": disk.used,
                        "free": disk.free,
                        "percent": (disk.used / disk.total) * 100
                    },
                    "network": {
                        "bytes_sent": network.bytes_sent,
                        "bytes_recv": network.bytes_recv,
                        "packets_sent": network.packets_sent,
                        "packets_recv": network.packets_recv
                    },
                    "load_average": {
                        "1min": load_avg[0],
                        "5min": load_avg[1],
                        "15min": load_avg[2]
                    }
                }
            }
            
            await manager.broadcast(json.dumps(metrics), "system_metrics")
            await asyncio.sleep(5)  # 每5秒发送一次
            
        except Exception as e:
            print(f"系统指标流错误: {e}")
            await asyncio.sleep(5)

# WireGuard状态数据流
async def wireguard_status_stream():
    """WireGuard状态数据流"""
    while True:
        try:
            # 这里需要实际的WireGuard服务实例
            # 为了演示，我们使用模拟数据
            wireguard_service = WireGuardService(None)  # 实际使用时需要传入db
            
            # 获取实时指标
            metrics = await wireguard_service.get_real_time_metrics()
            
            status_data = {
                "type": "wireguard_status",
                "timestamp": time.time(),
                "data": metrics
            }
            
            await manager.broadcast(json.dumps(status_data), "wireguard_status")
            await asyncio.sleep(10)  # 每10秒发送一次
            
        except Exception as e:
            print(f"WireGuard状态流错误: {e}")
            await asyncio.sleep(10)

# 网络状态数据流
async def network_status_stream():
    """网络状态数据流"""
    while True:
        try:
            # 获取网络接口信息
            interfaces = psutil.net_if_addrs()
            stats = psutil.net_if_stats()
            io_counters = psutil.net_io_counters(pernic=True)
            
            network_data = {
                "type": "network_status",
                "timestamp": time.time(),
                "data": {
                    "interfaces": {},
                    "total_io": dict(psutil.net_io_counters()._asdict())
                }
            }
            
            # 处理每个网络接口
            for interface_name, addresses in interfaces.items():
                if interface_name in stats and interface_name in io_counters:
                    interface_stats = stats[interface_name]
                    interface_io = io_counters[interface_name]
                    
                    network_data["data"]["interfaces"][interface_name] = {
                        "addresses": [
                            {
                                "family": str(addr.family),
                                "address": addr.address,
                                "netmask": addr.netmask,
                                "broadcast": addr.broadcast
                            }
                            for addr in addresses
                        ],
                        "stats": {
                            "isup": interface_stats.isup,
                            "duplex": interface_stats.duplex,
                            "speed": interface_stats.speed,
                            "mtu": interface_stats.mtu
                        },
                        "io": dict(interface_io._asdict())
                    }
            
            await manager.broadcast(json.dumps(network_data), "network_status")
            await asyncio.sleep(15)  # 每15秒发送一次
            
        except Exception as e:
            print(f"网络状态流错误: {e}")
            await asyncio.sleep(15)

# 告警数据流
async def alerts_stream():
    """告警数据流"""
    while True:
        try:
            # 这里应该实现实际的告警检查逻辑
            # 为了演示，我们使用模拟数据
            alerts = []
            
            # 检查系统资源告警
            cpu_percent = psutil.cpu_percent(interval=1)
            memory_percent = psutil.virtual_memory().percent
            
            if cpu_percent > 80:
                alerts.append({
                    "id": f"cpu_high_{int(time.time())}",
                    "type": "warning",
                    "severity": "high",
                    "message": f"CPU使用率过高: {cpu_percent:.1f}%",
                    "timestamp": time.time(),
                    "source": "system"
                })
            
            if memory_percent > 85:
                alerts.append({
                    "id": f"memory_high_{int(time.time())}",
                    "type": "warning",
                    "severity": "high",
                    "message": f"内存使用率过高: {memory_percent:.1f}%",
                    "timestamp": time.time(),
                    "source": "system"
                })
            
            if alerts:
                alerts_data = {
                    "type": "alerts",
                    "timestamp": time.time(),
                    "data": alerts
                }
                
                await manager.broadcast(json.dumps(alerts_data), "alerts")
            
            await asyncio.sleep(30)  # 每30秒检查一次
            
        except Exception as e:
            print(f"告警流错误: {e}")
            await asyncio.sleep(30)

# 启动所有数据流
async def start_data_streams():
    """启动所有数据流"""
    tasks = [
        asyncio.create_task(system_metrics_stream()),
        asyncio.create_task(wireguard_status_stream()),
        asyncio.create_task(network_status_stream()),
        asyncio.create_task(alerts_stream()),
        asyncio.create_task(bgp_status_stream()),
        asyncio.create_task(ipv6_status_stream())
    ]
    
    await asyncio.gather(*tasks)

# BGP状态数据流
async def bgp_status_stream():
    """BGP会话状态数据流"""
    while True:
        try:
            # 模拟BGP会话状态数据
            bgp_sessions = [
                {
                    "id": "bgp-session-1",
                    "name": "ISP-1",
                    "neighbor": "2001:db8::1",
                    "remote_as": 65001,
                    "status": "established",
                    "uptime": 3600,
                    "prefixes_received": 100,
                    "prefixes_sent": 50,
                    "last_update": time.time() - 60
                },
                {
                    "id": "bgp-session-2", 
                    "name": "ISP-2",
                    "neighbor": "2001:db8::2",
                    "remote_as": 65002,
                    "status": "idle",
                    "uptime": 0,
                    "prefixes_received": 0,
                    "prefixes_sent": 0,
                    "last_update": time.time() - 300
                }
            ]
            
            bgp_data = {
                "type": "bgp_status",
                "timestamp": time.time(),
                "data": {
                    "sessions": bgp_sessions,
                    "total_sessions": len(bgp_sessions),
                    "established_sessions": len([s for s in bgp_sessions if s["status"] == "established"]),
                    "total_prefixes_received": sum(s["prefixes_received"] for s in bgp_sessions),
                    "total_prefixes_sent": sum(s["prefixes_sent"] for s in bgp_sessions)
                }
            }
            
            await manager.broadcast(json.dumps(bgp_data), "bgp_status")
            await asyncio.sleep(15)  # 每15秒发送一次
            
        except Exception as e:
            print(f"BGP状态流错误: {e}")
            await asyncio.sleep(15)

# IPv6状态数据流
async def ipv6_status_stream():
    """IPv6前缀分配状态数据流"""
    while True:
        try:
            # 模拟IPv6前缀分配数据
            ipv6_allocations = [
                {
                    "id": "alloc-1",
                    "prefix": "2001:db8:1000::/48",
                    "client_id": "client-001",
                    "pool_id": "pool-1",
                    "status": "active",
                    "allocated_at": time.time() - 86400,
                    "expires_at": time.time() + 2592000
                },
                {
                    "id": "alloc-2",
                    "prefix": "2001:db8:2000::/48", 
                    "client_id": "client-002",
                    "pool_id": "pool-1",
                    "status": "active",
                    "allocated_at": time.time() - 172800,
                    "expires_at": time.time() + 2678400
                }
            ]
            
            ipv6_data = {
                "type": "ipv6_status",
                "timestamp": time.time(),
                "data": {
                    "allocations": ipv6_allocations,
                    "total_allocations": len(ipv6_allocations),
                    "active_allocations": len([a for a in ipv6_allocations if a["status"] == "active"]),
                    "total_prefixes": 2,
                    "utilization_percent": 40.0
                }
            }
            
            await manager.broadcast(json.dumps(ipv6_data), "ipv6_status")
            await asyncio.sleep(30)  # 每30秒发送一次
            
        except Exception as e:
            print(f"IPv6状态流错误: {e}")
            await asyncio.sleep(30)

# 获取WebSocket连接信息
@router.get("/connections", response_model=None)
async def get_connections():
    """获取WebSocket连接信息"""
    return {
        "active_connections": len(manager.active_connections),
        "connections": [
            {
                "user_id": data.get("user_id"),
                "connected_at": data.get("connected_at").isoformat() if data.get("connected_at") else None,
                "subscriptions": list(data.get("subscriptions", set()))
            }
            for data in manager.connection_data.values()
        ]
    }

# 手动发送消息
@router.post("/broadcast", response_model=None)
async def broadcast_message(message: dict, subscription_type: str = None):
    """手动广播消息"""
    await manager.broadcast(json.dumps(message), subscription_type)
    return {"message": "消息已广播", "subscription_type": subscription_type}
