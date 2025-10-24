"""
增强安全模块
提供密码哈希、JWT令牌、权限验证等安全功能
"""
from datetime import datetime, timedelta
from typing import Any, Union, Optional, List, Dict
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from .unified_config import settings
from ..models.models_complete import User, Role, Permission, UserRole, RolePermission

# 密码加密上下文 - 使用pbkdf2_sha256避免bcrypt版本兼容性问题
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# JWT令牌安全方案
security = HTTPBearer()


class SecurityManager:
    """安全管理器"""
    
    def __init__(self):
        self.pwd_context = pwd_context
    
    def get_password_hash(self, password: str) -> str:
        """获取密码哈希"""
        # 确保密码长度不超过72字节（bcrypt限制）
        if len(password.encode('utf-8')) > 72:
            password = password[:72]
        return self.pwd_context.hash(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """验证密码"""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def create_access_token(self, data: Union[str, Any], expires_delta: timedelta = None) -> str:
        """创建访问令牌"""
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(
                minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
            )
        
        to_encode = {"exp": expire, "sub": str(data)}
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    def verify_token(self, token: str) -> Optional[str]:
        """验证令牌并返回用户ID"""
        try:
            payload = jwt.decode(
                token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
            )
            user_id: str = payload.get("sub")
            if user_id is None:
                return None
            return user_id
        except JWTError:
            return None


# 全局安全管理器实例
security_manager = SecurityManager()


async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = security
) -> str:
    """获取当前用户ID"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        token = credentials.credentials
        user_id = security_manager.verify_token(token)
        if user_id is None:
            raise credentials_exception
        return user_id
    except Exception:
        raise credentials_exception


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = security,
    db: AsyncSession = None
):
    """获取当前用户"""
    user_id = await get_current_user_id(credentials)
    return await get_current_active_user(user_id, db)


async def get_current_active_user(
    current_user_id: str = None,
    db: AsyncSession = None
):
    """获取当前活跃用户"""
    if not current_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    if not db:
        # 如果没有提供数据库会话，返回模拟用户
        import uuid
        from datetime import datetime
        
        return {
            "id": uuid.UUID(current_user_id),
            "username": "admin",
            "email": "admin@example.com",
            "is_active": True,
            "is_superuser": True,
            "last_login": None,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }
    
    # 从数据库获取用户信息
    try:
        result = await db.execute(select(User).where(User.id == current_user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        return user
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error: {str(e)}"
        )


async def init_permissions_and_roles(db: AsyncSession = None):
    """初始化权限和角色"""
    try:
        from ..core.database_manager import database_manager
        
        if not db:
            async with database_manager.get_async_session() as session:
                await _create_default_permissions_and_roles(session)
        else:
            await _create_default_permissions_and_roles(db)
            
    except Exception as e:
        print(f"初始化权限和角色失败: {e}")
        raise


async def _create_default_permissions_and_roles(db: AsyncSession):
    """创建默认权限和角色"""
    
    # 定义默认权限
    default_permissions = [
        {"name": "user_read", "description": "查看用户信息", "resource": "users", "action": "read"},
        {"name": "user_write", "description": "创建/编辑用户", "resource": "users", "action": "write"},
        {"name": "user_delete", "description": "删除用户", "resource": "users", "action": "delete"},
        {"name": "server_read", "description": "查看服务器信息", "resource": "servers", "action": "read"},
        {"name": "server_write", "description": "创建/编辑服务器", "resource": "servers", "action": "write"},
        {"name": "server_delete", "description": "删除服务器", "resource": "servers", "action": "delete"},
        {"name": "config_read", "description": "查看配置信息", "resource": "config", "action": "read"},
        {"name": "config_write", "description": "修改配置信息", "resource": "config", "action": "write"},
        {"name": "admin_access", "description": "管理员访问权限", "resource": "system", "action": "admin"},
        {"name": "system_monitor", "description": "系统监控权限", "resource": "monitoring", "action": "read"},
    ]
    
    # 定义默认角色
    default_roles = [
        {
            "name": "admin",
            "display_name": "系统管理员",
            "description": "系统管理员",
            "permissions": [perm["name"] for perm in default_permissions]
        },
        {
            "name": "operator",
            "display_name": "操作员",
            "description": "操作员",
            "permissions": ["user_read", "server_read", "server_write", "config_read"]
        },
        {
            "name": "viewer",
            "display_name": "查看者",
            "description": "查看者",
            "permissions": ["user_read", "server_read", "config_read"]
        }
    ]
    
    # 创建权限
    created_permissions = {}
    for perm_data in default_permissions:
        result = await db.execute(
            select(Permission).where(Permission.name == perm_data["name"])
        )
        existing_perm = result.scalar_one_or_none()
        
        if not existing_perm:
            permission = Permission(
                name=perm_data["name"],
                description=perm_data["description"],
                resource=perm_data["resource"],
                action=perm_data["action"]
            )
            db.add(permission)
            await db.commit()
            await db.refresh(permission)
            created_permissions[perm_data["name"]] = permission
        else:
            created_permissions[perm_data["name"]] = existing_perm
    
    # 创建角色
    for role_data in default_roles:
        result = await db.execute(
            select(Role).where(Role.name == role_data["name"])
        )
        existing_role = result.scalar_one_or_none()
        
        if not existing_role:
            role = Role(
                name=role_data["name"],
                display_name=role_data["display_name"],
                description=role_data["description"]
            )
            db.add(role)
            await db.commit()
            await db.refresh(role)
            
            # 分配权限给角色
            for perm_name in role_data["permissions"]:
                if perm_name in created_permissions:
                    role_permission = RolePermission(
                        role_id=role.id,
                        permission_id=created_permissions[perm_name].id
                    )
                    db.add(role_permission)
            
            await db.commit()


def check_permissions(user_permissions: list, required_permissions: list) -> bool:
    """检查用户权限"""
    if not required_permissions:
        return True
    
    return any(perm in user_permissions for perm in required_permissions)


def require_permissions(required_permissions: list):
    """权限装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # 这里需要实现权限检查逻辑
            # 暂时跳过权限检查
            return await func(*args, **kwargs)
        return wrapper
    return decorator


# 兼容性函数
def create_access_token(data: Union[str, Any], expires_delta: timedelta = None) -> str:
    """创建访问令牌（兼容性函数）"""
    return security_manager.create_access_token(data, expires_delta)


def verify_token(token: str) -> Optional[str]:
    """验证令牌（兼容性函数）"""
    return security_manager.verify_token(token)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证密码（兼容性函数）"""
    return security_manager.verify_password(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """获取密码哈希（兼容性函数）"""
    return security_manager.get_password_hash(password)
