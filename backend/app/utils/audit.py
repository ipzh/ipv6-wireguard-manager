"""
审计日志工具
"""
from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import insert
from datetime import datetime

from ..core.logging import get_logger

logger = get_logger(__name__)


async def audit_log(
    db: AsyncSession,
    action: str,
    resource_type: str,
    resource_id: Optional[str] = None,
    description: Optional[str] = None,
    success: bool = True,
    error_message: Optional[str] = None,
    extra_data: Optional[Dict[str, Any]] = None
) -> None:
    """
    记录审计日志
    
    Args:
        db: 数据库会话
        action: 操作类型
        resource_type: 资源类型
        resource_id: 资源ID
        description: 操作描述
        success: 是否成功
        error_message: 错误信息
        extra_data: 额外数据
    """
    try:
        from ..models.models_complete import AuditLog
        
        # 获取用户信息
        user_id = None
        if hasattr(db, 'user_id'):
            user_id = db.user_id
        
        # 获取请求信息
        ip_address = None
        user_agent = None
        request_method = None
        request_path = None
        
        # 这里可以从请求上下文获取信息
        # 在实际应用中，这些信息应该从请求对象中获取
        
        # 创建审计日志记录
        audit_record = {
            'action': action,
            'resource_type': resource_type,
            'resource_id': resource_id,
            'description': description,
            'ip_address': ip_address,
            'user_agent': user_agent,
            'request_method': request_method,
            'request_path': request_path,
            'success': success,
            'error_message': error_message,
            'created_at': datetime.utcnow(),
            'user_id': user_id
        }
        
        # 插入审计日志
        stmt = insert(AuditLog).values(audit_record)
        await db.execute(stmt)
        await db.commit()
        
        # 记录到应用日志
        logger.info(
            "Audit log recorded",
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            success=success,
            user_id=user_id
        )
        
    except Exception as e:
        logger.error(
            "Failed to record audit log",
            action=action,
            resource_type=resource_type,
            error=str(e)
        )
        # 审计日志失败不应该影响主业务流程
        pass


async def log_user_action(
    db: AsyncSession,
    user_id: str,
    action: str,
    resource_type: str,
    resource_id: Optional[str] = None,
    description: Optional[str] = None,
    success: bool = True
) -> None:
    """
    记录用户操作日志
    
    Args:
        db: 数据库会话
        user_id: 用户ID
        action: 操作类型
        resource_type: 资源类型
        resource_id: 资源ID
        description: 操作描述
        success: 是否成功
    """
    await audit_log(
        db=db,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        description=description,
        success=success
    )


async def log_system_event(
    db: AsyncSession,
    action: str,
    description: Optional[str] = None,
    success: bool = True,
    extra_data: Optional[Dict[str, Any]] = None
) -> None:
    """
    记录系统事件日志
    
    Args:
        db: 数据库会话
        action: 操作类型
        description: 操作描述
        success: 是否成功
        extra_data: 额外数据
    """
    await audit_log(
        db=db,
        action=action,
        resource_type='system',
        description=description,
        success=success,
        extra_data=extra_data
    )


async def log_security_event(
    db: AsyncSession,
    action: str,
    description: Optional[str] = None,
    success: bool = True,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None
) -> None:
    """
    记录安全事件日志
    
    Args:
        db: 数据库会话
        action: 操作类型
        description: 操作描述
        success: 是否成功
        ip_address: IP地址
        user_agent: User-Agent
    """
    await audit_log(
        db=db,
        action=action,
        resource_type='security',
        description=description,
        success=success
    )
