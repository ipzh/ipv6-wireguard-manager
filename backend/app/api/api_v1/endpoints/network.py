"""
网络管理API端点
"""
import uuid
from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_async_db
from ....core.security import get_current_user_id
from ....schemas.network import (
    NetworkInterface, NetworkInterfaceCreate, NetworkInterfaceUpdate,
    FirewallRule, FirewallRuleCreate, FirewallRuleUpdate,
    NetworkStatus, InterfaceStats
)
from ....schemas.common import Message
from ....services.network_service import NetworkService

router = APIRouter()

# 网络接口管理端点
@router.get("/interfaces", response_model=List[NetworkInterface])
async def get_interfaces(
    skip: int = Query(0, ge=0, description="跳过记录数"),
    limit: int = Query(100, ge=1, le=100, description="限制记录数"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取网络接口列表
    """
    network_service = NetworkService(db)
    interfaces = await network_service.get_interfaces()
    return interfaces[skip:skip+limit]

@router.post("/interfaces", response_model=NetworkInterface, status_code=status.HTTP_201_CREATED)
async def create_interface(
    interface_in: NetworkInterfaceCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    创建网络接口记录
    """
    network_service = NetworkService(db)
    interface = await network_service.create_interface(interface_in)
    return interface

@router.get("/interfaces/{interface_id}", response_model=NetworkInterface)
async def get_interface(
    interface_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取指定的网络接口
    """
    network_service = NetworkService(db)
    interface = await network_service.get_interface_by_id(interface_id)
    if not interface:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="网络接口不存在"
        )
    return interface

@router.put("/interfaces/{interface_id}", response_model=NetworkInterface)
async def update_interface(
    interface_id: uuid.UUID,
    interface_in: NetworkInterfaceUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    更新网络接口
    """
    network_service = NetworkService(db)
    interface = await network_service.get_interface_by_id(interface_id)
    if not interface:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="网络接口不存在"
        )
    interface = await network_service.update_interface(interface, interface_in)
    return interface

@router.delete("/interfaces/{interface_id}", response_model=Message)
async def delete_interface(
    interface_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    删除网络接口记录
    """
    network_service = NetworkService(db)
    interface = await network_service.get_interface_by_id(interface_id)
    if not interface:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="网络接口不存在"
        )
    await network_service.delete_interface(interface)
    return Message(message="网络接口删除成功")

@router.get("/interfaces/{interface_name}/stats", response_model=InterfaceStats)
async def get_interface_stats(
    interface_name: str,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取网络接口统计信息
    """
    network_service = NetworkService(db)
    stats = await network_service.get_interface_stats(interface_name)
    if not stats:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="接口统计信息不存在"
        )
    return stats

@router.get("/system/interfaces")
async def get_system_interfaces(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取系统网络接口信息
    """
    network_service = NetworkService(db)
    interfaces = await network_service.get_system_interfaces()
    return {"interfaces": interfaces}

# 防火墙规则管理端点
@router.get("/firewall/rules", response_model=List[FirewallRule])
async def get_firewall_rules(
    skip: int = Query(0, ge=0, description="跳过记录数"),
    limit: int = Query(100, ge=1, le=100, description="限制记录数"),
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取防火墙规则列表
    """
    network_service = NetworkService(db)
    rules = await network_service.get_firewall_rules()
    return rules[skip:skip+limit]

@router.post("/firewall/rules", response_model=FirewallRule, status_code=status.HTTP_201_CREATED)
async def create_firewall_rule(
    rule_in: FirewallRuleCreate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    创建新的防火墙规则
    """
    network_service = NetworkService(db)
    rule = await network_service.create_firewall_rule(rule_in)
    return rule

@router.get("/firewall/rules/{rule_id}", response_model=FirewallRule)
async def get_firewall_rule(
    rule_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取指定的防火墙规则
    """
    network_service = NetworkService(db)
    rule = await network_service.get_firewall_rule_by_id(rule_id)
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="防火墙规则不存在"
        )
    return rule

@router.put("/firewall/rules/{rule_id}", response_model=FirewallRule)
async def update_firewall_rule(
    rule_id: uuid.UUID,
    rule_in: FirewallRuleUpdate,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    更新防火墙规则
    """
    network_service = NetworkService(db)
    rule = await network_service.get_firewall_rule_by_id(rule_id)
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="防火墙规则不存在"
        )
    rule = await network_service.update_firewall_rule(rule, rule_in)
    return rule

@router.delete("/firewall/rules/{rule_id}", response_model=Message)
async def delete_firewall_rule(
    rule_id: uuid.UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    删除防火墙规则
    """
    network_service = NetworkService(db)
    rule = await network_service.get_firewall_rule_by_id(rule_id)
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="防火墙规则不存在"
        )
    await network_service.delete_firewall_rule(rule)
    return Message(message="防火墙规则删除成功")

@router.post("/firewall/reload", response_model=Message)
async def reload_firewall_rules(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    重新加载所有防火墙规则
    """
    network_service = NetworkService(db)
    success = await network_service.reload_firewall_rules()
    if success:
        return Message(message="防火墙规则重新加载成功")
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="防火墙规则重新加载失败"
        )

# 网络状态端点
@router.get("/status", response_model=NetworkStatus)
async def get_network_status(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取网络状态
    """
    network_service = NetworkService(db)
    status = await network_service.get_network_status()
    return status

@router.get("/routing")
async def get_routing_table(
    db: AsyncSession = Depends(get_async_db),
    current_user_id: str = Depends(get_current_user_id)
) -> Any:
    """
    获取路由表
    """
    network_service = NetworkService(db)
    routes = await network_service.get_routing_table()
    return {"routes": routes}