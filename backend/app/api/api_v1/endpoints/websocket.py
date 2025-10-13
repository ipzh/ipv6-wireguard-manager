"""
WebSocket实时通信API端点
"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import json
import asyncio

router = APIRouter()


@router.websocket("/")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket连接端点"""
    await websocket.accept()
    try:
        while True:
            # 发送心跳
            await websocket.send_text(json.dumps({
                "type": "heartbeat",
                "timestamp": asyncio.get_event_loop().time()
            }))
            await asyncio.sleep(30)  # 每30秒发送一次心跳
    except WebSocketDisconnect:
        pass