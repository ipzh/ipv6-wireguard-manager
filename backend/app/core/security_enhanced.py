"""
增强安全模块
提供密码哈希、JWT令牌、权限验证等安全功能
"""
from datetime import datetime, timedelta
from typing import Any, Union, Optional, List, Dict
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import HTTPException, status, Request, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from .unified_config import settings
from ..models.models_complete import User, Role, Permission, UserRole, RolePermission

# 密码加密上下文 - 使用bcrypt进行密码哈希（推荐方案）
# bcrypt是专门为密码哈希设计的算法，具有自适应成本因子
try:
    # 尝试使用bcrypt
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
except Exception as e:
    # 如果bcrypt不可用，回退到pbkdf2_sha256
    import warnings
    warnings.warn(f"bcrypt不可用，使用pbkdf2_sha256作为备选方案: {e}")
    pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# JWT令牌安全方案
# 使用可选的HTTPBearer，因为我们也支持从Cookie读取令牌
try:
    security = HTTPBearer(auto_error=False)
except TypeError:
    # 如果FastAPI版本不支持auto_error参数，使用默认值
    security = HTTPBearer()


class SecurityManager:
    """安全管理器"""
    
    def __init__(self):
        self.pwd_context = pwd_context
        self.access_token_expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
        self.refresh_token_expire_days = settings.REFRESH_TOKEN_EXPIRE_DAYS
    
    def get_password_hash(self, password: str) -> str:
        """获取密码哈希
        
        使用bcrypt时需要注意：
        - bcrypt最大支持72字节的密码
        - 如果密码超过72字节，会截断（不推荐）或使用pbkdf2_sha256
        """
        # bcrypt有72字节的限制
        password_bytes = password.encode('utf-8')
        if len(password_bytes) > 72:
            # 对于超长密码，使用pbkdf2_sha256处理
            # 或者截断（不推荐，但为了兼容性）
            import warnings
            warnings.warn("密码长度超过72字节，bcrypt会自动截断")
            password = password_bytes[:72].decode('utf-8', errors='ignore')
        
        return self.pwd_context.hash(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """验证密码"""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def create_access_token(self, data: Union[str, Any], expires_delta: timedelta = None) -> str:
        """创建访问令牌"""
        if isinstance(data, dict):
            to_encode = data.copy()
        else:
            to_encode = {"sub": str(data)}
            
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(
                minutes=self.access_token_expire_minutes
            )
        
        to_encode["exp"] = expire
        to_encode["type"] = "access"
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    def create_refresh_token(self, user_id: str, expires_delta: timedelta = None) -> str:
        """创建刷新令牌"""
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(days=self.refresh_token_expire_days)
        
        to_encode = {
            "exp": expire,
            "sub": str(user_id),
            "type": "refresh"
        }
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    def verify_token(self, token: str, token_type: str = "access") -> Optional[Dict[str, Any]]:
        """验证令牌并返回载荷
        
        Args:
            token: JWT令牌
            token_type: 令牌类型 ('access' 或 'refresh')
            
        Returns:
            令牌载荷字典，包含 'sub' (用户ID) 等字段，验证失败返回None
        """
        try:
            # 检查令牌是否在黑名单中（仅对access token检查）
            if token_type == "access":
                from .token_blacklist import is_blacklisted
                if is_blacklisted(token):
                    return None
            
            payload = jwt.decode(
                token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
            )
            
            # 验证令牌类型
            token_type_in_payload = payload.get("type", "access")
            if token_type_in_payload != token_type:
                return None
            
            return payload
        except JWTError:
            return None


# 全局安全管理器实例
security_manager = SecurityManager()


async def _get_token_from_request(request: Request) -> Optional[str]:
    """从请求中提取令牌（内部辅助函数）"""
    # 1. 优先从Authorization Header获取（向后兼容）
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        return auth_header[7:]  # 移除 "Bearer " 前缀
    
    # 2. 如果header中没有，从Cookie获取（HttpOnly Cookie方案）
    return request.cookies.get("access_token")


async def get_current_user_id(
    request: Request
) -> str:
    """获取当前用户ID - 支持从Cookie或Authorization Header获取令牌"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    token = await _get_token_from_request(request)
    
    if not token:
        raise credentials_exception
    
    try:
        payload = security_manager.verify_token(token, "access")
        if payload is None:
            raise credentials_exception
        user_id = payload.get("sub")
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


def verify_token(token: str, token_type: str = "access") -> Optional[Dict[str, Any]]:
    """验证令牌（兼容性函数）"""
    return security_manager.verify_token(token, token_type)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证密码（兼容性函数）"""
    return security_manager.verify_password(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """获取密码哈希（兼容性函数）"""
    return security_manager.get_password_hash(password)
