"""
增强的安全系统 - 实现真正的JWT认证和权限管理
"""
import secrets
from datetime import datetime, timedelta
from typing import Any, Union, Optional, List, Dict
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from .config_enhanced import settings
from .logging import get_logger
from ..models.models_complete import User, Role, Permission, UserRole, RolePermission, user_roles, role_permissions

logger = get_logger(__name__)

# 密码加密上下文 - 使用Argon2和bcrypt双重保护
pwd_context = CryptContext(
    schemes=["argon2", "bcrypt"], 
    deprecated="auto",
    argon2__memory_cost=65536,
    argon2__time_cost=4,
    argon2__parallelism=4
)

# JWT令牌安全方案
security = HTTPBearer(auto_error=False)

# 权限定义
PERMISSIONS = {
    # 用户管理权限
    "users.view": "查看用户",
    "users.create": "创建用户", 
    "users.edit": "编辑用户",
    "users.delete": "删除用户",
    "users.manage": "管理用户",
    
    # WireGuard管理权限
    "wireguard.view": "查看WireGuard",
    "wireguard.create": "创建WireGuard",
    "wireguard.edit": "编辑WireGuard",
    "wireguard.delete": "删除WireGuard",
    "wireguard.manage": "管理WireGuard",
    
    # BGP管理权限
    "bgp.view": "查看BGP",
    "bgp.create": "创建BGP",
    "bgp.edit": "编辑BGP",
    "bgp.delete": "删除BGP",
    "bgp.manage": "管理BGP",
    
    # IPv6管理权限
    "ipv6.view": "查看IPv6",
    "ipv6.create": "创建IPv6",
    "ipv6.edit": "编辑IPv6",
    "ipv6.delete": "删除IPv6",
    "ipv6.manage": "管理IPv6",
    
    # 系统管理权限
    "system.view": "查看系统",
    "system.manage": "管理系统",
    "system.config": "系统配置",
    
    # 监控权限
    "monitoring.view": "查看监控",
    "monitoring.manage": "管理监控",
    
    # 日志权限
    "logs.view": "查看日志",
    "logs.manage": "管理日志",
    
    # 网络权限
    "network.view": "查看网络",
    "network.manage": "管理网络"
}

# 角色定义
ROLES = {
    "admin": {
        "name": "管理员",
        "description": "系统管理员，拥有所有权限",
        "permissions": list(PERMISSIONS.keys())
    },
    "operator": {
        "name": "操作员", 
        "description": "系统操作员，拥有大部分管理权限",
        "permissions": [
            "wireguard.manage", "wireguard.view",
            "bgp.manage", "bgp.view", 
            "ipv6.manage", "ipv6.view",
            "monitoring.view", "logs.view",
            "system.view", "users.view", "network.view"
        ]
    },
    "user": {
        "name": "普通用户",
        "description": "普通用户，只有查看权限",
        "permissions": [
            "wireguard.view", "monitoring.view"
        ]
    }
}


class SecurityManager:
    """安全管理器"""
    
    def __init__(self):
        self.secret_key = settings.SECRET_KEY
        self.algorithm = settings.ALGORITHM
        self.access_token_expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
    
    def create_access_token(
        self, 
        data: Union[str, Dict[str, Any]], 
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """创建访问令牌"""
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=self.access_token_expire_minutes)
        
        # 如果data是字符串，转换为字典
        if isinstance(data, str):
            to_encode = {"exp": expire, "sub": data, "type": "access"}
        else:
            to_encode = data.copy()
            to_encode.update({"exp": expire, "type": "access"})
        
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
        
        logger.info("Access token created", user_id=data.get("sub") if isinstance(data, dict) else data)
        return encoded_jwt
    
    def create_refresh_token(
        self, 
        user_id: str, 
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """创建刷新令牌"""
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            # 刷新令牌有效期更长
            expire = datetime.utcnow() + timedelta(days=30)
        
        to_encode = {
            "exp": expire, 
            "sub": user_id, 
            "type": "refresh"
        }
        
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
        
        logger.info("Refresh token created", user_id=user_id)
        return encoded_jwt
    
    def verify_token(self, token: str, token_type: str = "access") -> Optional[Dict[str, Any]]:
        """验证令牌并返回载荷"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            
            # 检查令牌类型
            if payload.get("type") != token_type:
                logger.warning("Invalid token type", expected=token_type, actual=payload.get("type"))
                return None
            
            # 检查过期时间
            exp = payload.get("exp")
            if exp and datetime.utcnow() > datetime.fromtimestamp(exp):
                logger.warning("Token expired", exp=exp)
                return None
            
            return payload
            
        except JWTError as e:
            logger.warning("JWT verification failed", error=str(e))
            return None
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """验证密码"""
        try:
            return pwd_context.verify(plain_password, hashed_password)
        except Exception as e:
            logger.error("Password verification failed", error=str(e))
            return False
    
    def get_password_hash(self, password: str) -> str:
        """获取密码哈希"""
        # 密码强度检查
        if len(password) < 8:
            raise ValueError("密码长度至少8位")
        
        if not any(c.isupper() for c in password):
            raise ValueError("密码必须包含至少一个大写字母")
        
        if not any(c.islower() for c in password):
            raise ValueError("密码必须包含至少一个小写字母")
        
        if not any(c.isdigit() for c in password):
            raise ValueError("密码必须包含至少一个数字")
        
        try:
            return pwd_context.hash(password)
        except Exception as e:
            logger.error("Password hashing failed", error=str(e))
            raise ValueError("密码加密失败")


# 全局安全管理器实例
security_manager = SecurityManager()


async def get_current_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> str:
    """获取当前用户ID"""
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="未提供认证令牌",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    payload = security_manager.verify_token(credentials.credentials)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的认证令牌",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id: str = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="令牌中缺少用户信息",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user_id


async def get_current_user(
    db: AsyncSession,
    current_user_id: str = Depends(get_current_user_id)
) -> User:
    """获取当前用户完整信息"""
    try:
        # 从数据库获取用户信息
        result = await db.execute(
            select(User).where(User.id == current_user_id, User.is_active == True)
        )
        user = result.scalar_one_or_none()
        
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户不存在或已被禁用",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return user
        
    except Exception as e:
        logger.error("Failed to get current user", user_id=current_user_id, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="获取用户信息失败",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """获取当前活跃用户"""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户账户已被禁用"
        )
    return current_user


async def get_user_permissions(
    db: AsyncSession,
    user_id: str
) -> List[str]:
    """获取用户权限列表"""
    try:
        # 查询用户的所有角色和权限
        result = await db.execute(
            select(Permission.name)
            .join(RolePermission, Permission.id == RolePermission.permission_id)
            .join(Role, RolePermission.role_id == Role.id)
            .join(UserRole, Role.id == UserRole.role_id)
            .where(UserRole.user_id == user_id)
        )
        
        permissions = [row[0] for row in result.fetchall()]
        
        # 如果是超级用户，返回所有权限
        user_result = await db.execute(
            select(User.is_superuser).where(User.id == user_id)
        )
        is_superuser = user_result.scalar_one_or_none()
        
        if is_superuser:
            permissions = list(PERMISSIONS.keys())
        
        return permissions
        
    except Exception as e:
        logger.error("Failed to get user permissions", user_id=user_id, error=str(e))
        return []


def require_permissions(required_permissions: List[str]):
    """权限检查装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # 从kwargs中获取数据库会话和当前用户
            db = kwargs.get('db')
            current_user = kwargs.get('current_user')
            
            if not db or not current_user:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="缺少必要的依赖项"
                )
            
            # 获取用户权限
            user_permissions = await get_user_permissions(db, str(current_user.id))
            
            # 检查权限
            if not check_permissions(user_permissions, required_permissions):
                logger.warning(
                    "Permission denied",
                    user_id=str(current_user.id),
                    required_permissions=required_permissions,
                    user_permissions=user_permissions
                )
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"权限不足，需要以下权限之一: {', '.join(required_permissions)}"
                )
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator


def check_permissions(user_permissions: List[str], required_permissions: List[str]) -> bool:
    """检查用户是否具有所需权限"""
    if not required_permissions:
        return True
    
    # 检查是否有任何所需权限
    return any(perm in user_permissions for perm in required_permissions)


async def authenticate_user(
    db: AsyncSession,
    username: str,
    password: str
) -> Optional[User]:
    """认证用户"""
    try:
        # 查询用户
        result = await db.execute(
            select(User).where(
                (User.username == username) | (User.email == username),
                User.is_active == True
            )
        )
        user = result.scalar_one_or_none()
        
        if not user:
            logger.warning("User not found", username=username)
            return None
        
        # 验证密码
        if not security_manager.verify_password(password, user.hashed_password):
            logger.warning("Invalid password", username=username)
            return None
        
        # 更新最后登录时间
        user.last_login = datetime.utcnow()
        await db.commit()
        
        logger.info("User authenticated successfully", user_id=str(user.id), username=username)
        return user
        
    except Exception as e:
        logger.error("Authentication failed", username=username, error=str(e))
        return None


def create_tokens(user_id: str) -> Dict[str, str]:
    """创建访问令牌和刷新令牌"""
    access_token = security_manager.create_access_token({"sub": user_id})
    refresh_token = security_manager.create_refresh_token(user_id)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


async def refresh_access_token(
    db: AsyncSession,
    refresh_token: str
) -> Optional[Dict[str, str]]:
    """刷新访问令牌"""
    payload = security_manager.verify_token(refresh_token, "refresh")
    if not payload:
        return None
    
    user_id = payload.get("sub")
    if not user_id:
        return None
    
    # 验证用户是否仍然存在且活跃
    result = await db.execute(
        select(User).where(User.id == user_id, User.is_active == True)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        return None
    
    # 创建新的令牌
    return create_tokens(user_id)


# 权限检查依赖
async def require_permission(
    permission: str,
    db: AsyncSession = Depends(lambda: None),  # 需要在实际使用时注入
    current_user: User = Depends(get_current_active_user)
) -> User:
    """权限检查依赖"""
    user_permissions = await get_user_permissions(db, str(current_user.id))
    
    if not check_permissions(user_permissions, [permission]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"权限不足，需要权限: {permission}"
        )
    
    return current_user


# 角色检查依赖
async def require_role(
    role_name: str,
    db: AsyncSession = Depends(lambda: None),  # 需要在实际使用时注入
    current_user: User = Depends(get_current_active_user)
) -> User:
    """角色检查依赖"""
    try:
        # 查询用户是否具有指定角色
        result = await db.execute(
            select(UserRole)
            .join(Role, UserRole.role_id == Role.id)
            .where(
                UserRole.user_id == current_user.id,
                Role.name == role_name
            )
        )
        
        user_role = result.scalar_one_or_none()
        
        if not user_role and not current_user.is_superuser:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"权限不足，需要角色: {role_name}"
            )
        
        return current_user
        
    except Exception as e:
        logger.error("Role check failed", user_id=str(current_user.id), role=role_name, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="角色检查失败"
        )


# 初始化权限和角色数据
async def init_permissions_and_roles(db: AsyncSession):
    """初始化权限和角色数据"""
    try:
        # 创建权限
        for perm_name, perm_desc in PERMISSIONS.items():
            result = await db.execute(
                select(Permission).where(Permission.name == perm_name)
            )
            if not result.scalar_one_or_none():
                permission = Permission(name=perm_name, description=perm_desc)
                db.add(permission)
        
        await db.commit()
        
        # 创建角色
        for role_name, role_data in ROLES.items():
            result = await db.execute(
                select(Role).where(Role.name == role_name)
            )
            role = result.scalar_one_or_none()
            
            if not role:
                role = Role(
                    name=role_name,
                    display_name=role_data["name"],
                    description=role_data["description"]
                )
                db.add(role)
                await db.flush()  # 获取角色ID
            
            # 分配权限给角色
            for perm_name in role_data["permissions"]:
                perm_result = await db.execute(
                    select(Permission).where(Permission.name == perm_name)
                )
                permission = perm_result.scalar_one_or_none()
                
                if permission:
                    # 检查角色权限关联是否已存在
                    role_perm_result = await db.execute(
                        select(RolePermission).where(
                            RolePermission.role_id == role.id,
                            RolePermission.permission_id == permission.id
                        )
                    )
                    
                    if not role_perm_result.scalar_one_or_none():
                        role_permission = RolePermission(
                            role_id=role.id,
                            permission_id=permission.id
                        )
                        db.add(role_permission)
        
        await db.commit()
        logger.info("Permissions and roles initialized successfully")
        
    except Exception as e:
        logger.error("Failed to initialize permissions and roles", error=str(e))
        await db.rollback()
        raise
