"""
WireGuard管理API端点
"""
import uuid
from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from ....core.database import get_async_db
from ....core.security import get_current_user_id
from ....schemas.wireguard import (
    WireGuardServer, WireGuardServerCreate, WireGuardServerUpdate,
    WireGuardClient, WireGuardClientCreate, WireGuardClientUpdate,
    WireGuardStatus, QRCodeResponse
)
from ....schemas.common import Message
from ....services.wireguard_service import WireGuardService
from ....models.wireguard import WireGuardClient as WireGuardClientModel

router = APIRouter()

# 服务器管理端点
@router.get("/servers", response_model=List[WireGuardServer])
async def get_servers(
    skip: int = Query(0, ge=0, description="跳过记录数"),
    limit: int = Query(100, ge=1, le=100, description="限制记录数"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取WireGuard服务器列表
    """
    wireguard_service = WireGuardService(db)
    servers = await wireguard_service.get_servers()
    return servers[skip:skip+limit]

@router.post("/servers", response_model=WireGuardServer, status_code=status.HTTP_201_CREATED)
async def create_server(
    server_data: WireGuardServerCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    创建WireGuard服务器
    """
    wireguard_service = WireGuardService(db)
    server = await wireguard_service.create_server(server_data)
    return server

@router.get("/servers/{server_id}", response_model=WireGuardServer)
async def get_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取WireGuard服务器详情
    """
    wireguard_service = WireGuardService(db)
    server = await wireguard_service.get_server_by_id(server_id)
    if not server:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="服务器不存在"
        )
    return server

@router.put("/servers/{server_id}", response_model=WireGuardServer)
async def update_server(
    server_id: uuid.UUID,
    server_data: WireGuardServerUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    更新WireGuard服务器
    """
    wireguard_service = WireGuardService(db)
    server = await wireguard_service.get_server_by_id(server_id)
    if not server:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="服务器不存在"
        )
    server = await wireguard_service.update_server(server, server_data)
    return server

@router.delete("/servers/{server_id}", response_model=Message)
async def delete_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    删除WireGuard服务器
    """
    wireguard_service = WireGuardService(db)
    server = await wireguard_service.get_server_by_id(server_id)
    if not server:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="服务器不存在"
        )
    await wireguard_service.delete_server(server)
    return Message(message="服务器删除成功")

@router.post("/servers/{server_id}/start", response_model=Message)
async def start_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    启动WireGuard服务器
    """
    wireguard_service = WireGuardService(db)
    server = await wireguard_service.get_server_by_id(server_id)
    if not server:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="服务器不存在"
        )
    success = await wireguard_service.start_server(server)
    if success:
        return Message(message="服务器启动成功")
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="服务器启动失败"
        )

@router.post("/servers/{server_id}/stop", response_model=Message)
async def stop_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    停止WireGuard服务器
    """
    wireguard_service = WireGuardService(db)
    server = await wireguard_service.get_server_by_id(server_id)
    if not server:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="服务器不存在"
        )
    success = await wireguard_service.stop_server(server)
    if success:
        return Message(message="服务器停止成功")
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="服务器停止失败"
        )

@router.post("/servers/{server_id}/restart", response_model=Message)
async def restart_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    重启WireGuard服务器
    """
    wireguard_service = WireGuardService(db)
    server = await wireguard_service.get_server_by_id(server_id)
    if not server:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="服务器不存在"
        )
    success = await wireguard_service.restart_server(server)
    if success:
        return Message(message="服务器重启成功")
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="服务器重启失败"
        )

@router.get("/servers/{server_id}/status", response_model=WireGuardStatus)
async def get_server_status(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取WireGuard服务器状态
    """
    wireguard_service = WireGuardService(db)
    server = await wireguard_service.get_server_by_id(server_id)
    if not server:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="服务器不存在"
        )
    status_info = await wireguard_service.get_server_status(server)
    return status_info

# 客户端管理端点
@router.get("/clients", response_model=List[WireGuardClient])
async def get_clients(
    server_id: uuid.UUID = Query(None, description="服务器ID"),
    skip: int = Query(0, ge=0, description="跳过记录数"),
    limit: int = Query(100, ge=1, le=100, description="限制记录数"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取WireGuard客户端列表
    """
    wireguard_service = WireGuardService(db)
    if server_id:
        clients = await wireguard_service.get_clients_by_server(server_id)
    else:
        # 获取所有客户端
        result = await db.execute(select(WireGuardClientModel))
        clients = result.scalars().all()
    return clients[skip:skip+limit]

@router.post("/clients", response_model=WireGuardClient, status_code=status.HTTP_201_CREATED)
async def create_client(
    client_data: WireGuardClientCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    创建WireGuard客户端
    """
    wireguard_service = WireGuardService(db)
    client = await wireguard_service.create_client(client_data)
    return client

@router.get("/clients/{client_id}", response_model=WireGuardClient)
async def get_client(
    client_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取WireGuard客户端详情
    """
    wireguard_service = WireGuardService(db)
    client = await wireguard_service.get_client_by_id(client_id)
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="客户端不存在"
        )
    return client

@router.put("/clients/{client_id}", response_model=WireGuardClient)
async def update_client(
    client_id: uuid.UUID,
    client_data: WireGuardClientUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    更新WireGuard客户端
    """
    wireguard_service = WireGuardService(db)
    client = await wireguard_service.get_client_by_id(client_id)
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="客户端不存在"
        )
    client = await wireguard_service.update_client(client, client_data)
    return client

@router.delete("/clients/{client_id}", response_model=Message)
async def delete_client(
    client_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    删除WireGuard客户端
    """
    wireguard_service = WireGuardService(db)
    client = await wireguard_service.get_client_by_id(client_id)
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="客户端不存在"
        )
    await wireguard_service.delete_client(client)
    return Message(message="客户端删除成功")

@router.get("/clients/{client_id}/qr", response_model=QRCodeResponse)
async def get_client_qr_code(
    client_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取客户端配置的QR码
    """
    wireguard_service = WireGuardService(db)
    client = await wireguard_service.get_client_by_id(client_id)
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="客户端不存在"
        )
    
    # 重新生成配置和QR码
    config = await wireguard_service.generate_client_config(client)
    
    return QRCodeResponse(
        qr_code=client.qr_code or "",
        config=config
    )