"""
WebSocket实时通信API端点
"""
import json
import asyncio
from typing import Dict, List, Any
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from ....core.database import get_async_db
from ....services.monitoring_service import MonitoringService
from ....services.wireguard_service import WireGuardService
from ....services.network_service import NetworkService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

class ConnectionManager:
    """WebSocket连接管理器"""
    
    def __init__(self):
        # 存储活跃连接
        self.active_connections: List[WebSocket] = []
        # 存储用户连接映射
        self.user_connections: Dict[str, List[WebSocket]] = {}
        # 存储连接类型
        self.connection_types: Dict[WebSocket, str] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str = None, connection_type: str = "general"):
        """接受WebSocket连接"""
        await websocket.accept()
        self.active_connections.append(websocket)
        self.connection_types[websocket] = connection_type
        
        if user_id:
            if user_id not in self.user_connections:
                self.user_connections[user_id] = []
            self.user_connections[user_id].append(websocket)
        
        logger.info(f"WebSocket连接建立: {user_id}, 类型: {connection_type}")
    
    def disconnect(self, websocket: WebSocket, user_id: str = None):
        """断开WebSocket连接"""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        
        if websocket in self.connection_types:
            del self.connection_types[websocket]
        
        if user_id and user_id in self.user_connections:
            if websocket in self.user_connections[user_id]:
                self.user_connections[user_id].remove(websocket)
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]
        
        logger.info(f"WebSocket连接断开: {user_id}")
    
    async def send_personal_message(self, message: str, websocket: WebSocket):
        """发送个人消息"""
        try:
            await websocket.send_text(message)
        except Exception as e:
            logger.error(f"发送个人消息失败: {e}")
    
    async def send_to_user(self, message: str, user_id: str):
        """发送消息给指定用户"""
        if user_id in self.user_connections:
            for websocket in self.user_connections[user_id]:
                try:
                    await websocket.send_text(message)
                except Exception as e:
                    logger.error(f"发送用户消息失败: {e}")
                    self.disconnect(websocket, user_id)
    
    async def broadcast(self, message: str, connection_type: str = None):
        """广播消息"""
        disconnected = []
        for websocket in self.active_connections:
            try:
                if connection_type is None or self.connection_types.get(websocket) == connection_type:
                    await websocket.send_text(message)
            except Exception as e:
                logger.error(f"广播消息失败: {e}")
                disconnected.append(websocket)
        
        # 清理断开的连接
        for websocket in disconnected:
            self.disconnect(websocket)

# 全局连接管理器
manager = ConnectionManager()

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: str,
    connection_type: str = "general"
):
    """WebSocket连接端点"""
    await manager.connect(websocket, user_id, connection_type)
    
    try:
        while True:
            # 接收客户端消息
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # 处理不同类型的消息
            await handle_websocket_message(websocket, user_id, message)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
    except Exception as e:
        logger.error(f"WebSocket错误: {e}")
        manager.disconnect(websocket, user_id)

async def handle_websocket_message(websocket: WebSocket, user_id: str, message: Dict[str, Any]):
    """处理WebSocket消息"""
    message_type = message.get("type")
    
    if message_type == "ping":
        # 心跳检测
        await manager.send_personal_message(
            json.dumps({"type": "pong", "timestamp": message.get("timestamp")}),
            websocket
        )
    
    elif message_type == "subscribe":
        # 订阅特定类型的数据
        subscription_type = message.get("subscription_type")
        await handle_subscription(websocket, user_id, subscription_type)
    
    elif message_type == "unsubscribe":
        # 取消订阅
        subscription_type = message.get("subscription_type")
        await handle_unsubscription(websocket, user_id, subscription_type)
    
    else:
        # 未知消息类型
        await manager.send_personal_message(
            json.dumps({"type": "error", "message": "未知消息类型"}),
            websocket
        )

async def handle_subscription(websocket: WebSocket, user_id: str, subscription_type: str):
    """处理订阅请求"""
    if subscription_type == "system_metrics":
        # 订阅系统指标
        await start_system_metrics_stream(websocket, user_id)
    elif subscription_type == "wireguard_status":
        # 订阅WireGuard状态
        await start_wireguard_status_stream(websocket, user_id)
    elif subscription_type == "network_status":
        # 订阅网络状态
        await start_network_status_stream(websocket, user_id)
    elif subscription_type == "alerts":
        # 订阅告警
        await start_alerts_stream(websocket, user_id)
    else:
        await manager.send_personal_message(
            json.dumps({"type": "error", "message": f"不支持的订阅类型: {subscription_type}"}),
            websocket
        )

async def handle_unsubscription(websocket: WebSocket, user_id: str, subscription_type: str):
    """处理取消订阅请求"""
    # 这里可以实现取消订阅的逻辑
    await manager.send_personal_message(
        json.dumps({"type": "unsubscribed", "subscription_type": subscription_type}),
        websocket
    )

async def start_system_metrics_stream(websocket: WebSocket, user_id: str):
    """启动系统指标流"""
    try:
        while websocket in manager.active_connections:
            # 获取系统指标
            import psutil
            import time
            
            metrics = {
                "type": "system_metrics",
                "data": {
                    "cpu_usage": psutil.cpu_percent(interval=1),
                    "memory_usage": psutil.virtual_memory().percent,
                    "disk_usage": psutil.disk_usage('/').percent,
                    "network_rx": psutil.net_io_counters().bytes_recv,
                    "network_tx": psutil.net_io_counters().bytes_sent,
                    "timestamp": time.time()
                }
            }
            
            await manager.send_personal_message(json.dumps(metrics), websocket)
            await asyncio.sleep(5)  # 每5秒发送一次
            
    except Exception as e:
        logger.error(f"系统指标流错误: {e}")

async def start_wireguard_status_stream(websocket: WebSocket, user_id: str):
    """启动WireGuard状态流"""
    try:
        while websocket in manager.active_connections:
            # 获取WireGuard状态
            status_data = {
                "type": "wireguard_status",
                "data": {
                    "servers": [],
                    "clients": [],
                    "timestamp": time.time()
                }
            }
            
            # 这里应该从数据库获取实际的WireGuard状态
            # 简化实现
            await manager.send_personal_message(json.dumps(status_data), websocket)
            await asyncio.sleep(10)  # 每10秒发送一次
            
    except Exception as e:
        logger.error(f"WireGuard状态流错误: {e}")

async def start_network_status_stream(websocket: WebSocket, user_id: str):
    """启动网络状态流"""
    try:
        while websocket in manager.active_connections:
            # 获取网络状态
            import psutil
            
            network_data = {
                "type": "network_status",
                "data": {
                    "interfaces": [],
                    "connections": len(psutil.net_connections()),
                    "timestamp": time.time()
                }
            }
            
            # 获取网络接口信息
            net_if_addrs = psutil.net_if_addrs()
            for interface_name, addresses in net_if_addrs.items():
                interface_info = {
                    "name": interface_name,
                    "addresses": [addr.address for addr in addresses]
                }
                network_data["data"]["interfaces"].append(interface_info)
            
            await manager.send_personal_message(json.dumps(network_data), websocket)
            await asyncio.sleep(15)  # 每15秒发送一次
            
    except Exception as e:
        logger.error(f"网络状态流错误: {e}")

async def start_alerts_stream(websocket: WebSocket, user_id: str):
    """启动告警流"""
    try:
        while websocket in manager.active_connections:
            # 检查告警
            alerts_data = {
                "type": "alerts",
                "data": {
                    "alerts": [],
                    "timestamp": time.time()
                }
            }
            
            # 这里应该实现实际的告警检查逻辑
            # 简化实现
            await manager.send_personal_message(json.dumps(alerts_data), websocket)
            await asyncio.sleep(30)  # 每30秒检查一次
            
    except Exception as e:
        logger.error(f"告警流错误: {e}")

# 广播消息的API端点
@router.post("/broadcast")
async def broadcast_message(
    message: Dict[str, Any],
    connection_type: str = None,
    db: AsyncSession = Depends(get_async_db)
):
    """广播消息给所有连接的客户端"""
    try:
        await manager.broadcast(json.dumps(message), connection_type)
        return {"status": "success", "message": "消息广播成功"}
    except Exception as e:
        logger.error(f"广播消息失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="广播消息失败"
        )

@router.post("/send/{user_id}")
async def send_message_to_user(
    user_id: str,
    message: Dict[str, Any],
    db: AsyncSession = Depends(get_async_db)
):
    """发送消息给指定用户"""
    try:
        await manager.send_to_user(json.dumps(message), user_id)
        return {"status": "success", "message": f"消息发送给用户 {user_id} 成功"}
    except Exception as e:
        logger.error(f"发送用户消息失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="发送用户消息失败"
        )

@router.get("/connections")
async def get_connections_info():
    """获取连接信息"""
    return {
        "total_connections": len(manager.active_connections),
        "user_connections": {user_id: len(connections) for user_id, connections in manager.user_connections.items()},
        "connection_types": {str(ws): conn_type for ws, conn_type in manager.connection_types.items()}
    }
