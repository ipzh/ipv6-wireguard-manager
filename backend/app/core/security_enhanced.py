"""
增强的安全管理模块
提供密码哈希、JWT令牌管理、当前用户依赖、以及初始化基础角色/权限
"""
from datetime import datetime, timedelta
from typing import Any, Dict, Optional

from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from .unified_config import settings
from .database_manager import database_manager
from ..models.models_complete import User, Role, Permission

# 密码加密上下文 - 使用pbkdf2_sha256以确保更好的兼容性
_pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# HTTP Bearer 认证方案
_security_scheme = HTTPBearer()


class SecurityManager:
    def __init__(self):
        self.secret_key = settings.SECRET_KEY
        self.algorithm = settings.ALGORITHM
        # pydantic settings 确保为 int
        self.access_token_expire_minutes = int(getattr(settings, "ACCESS_TOKEN_EXPIRE_MINUTES", 60 * 24))
        # 刷新令牌默认30天
        self.refresh_token_expire_minutes = 60 * 24 * 30

    # 密码相关
    def get_password_hash(self, password: str) -> str:
        # 确保不过长
        if len(password.encode("utf-8")) > 72:
            password = password[:72]
        return _pwd_context.hash(password)

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        return _pwd_context.verify(plain_password, hashed_password)

    # 令牌相关
    def _create_token(self, data: Dict[str, Any], expires_delta: timedelta) -> str:
        to_encode = data.copy()
        expire = datetime.utcnow() + expires_delta
        to_encode.update({"exp": expire})
        return jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)

    def create_access_token(self, data: Dict[str, Any]) -> str:
        return self._create_token(data, timedelta(minutes=self.access_token_expire_minutes))

    def create_refresh_token(self, user_id: str) -> str:
        return self._create_token({"sub": user_id, "type": "refresh"}, timedelta(minutes=self.refresh_token_expire_minutes))

    def verify_token(self, token: str, token_type: str = "access") -> Optional[Any]:
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            # 可选校验类型
            if token_type == "refresh" and payload.get("type") != "refresh":
                return None
            # 返回一个简单对象，便于调用方使用 .sub 等属性
            class TokenData:
                def __init__(self, payload: Dict[str, Any]):
                    self.sub = payload.get("sub")
                    self.exp = payload.get("exp")
                    self.payload = payload
            return TokenData(payload)
        except JWTError:
            return None


security_manager = SecurityManager()


# 依赖：获取当前用户ID
async def get_current_user_id(credentials: HTTPAuthorizationCredentials = Depends(_security_scheme)) -> str:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    token = credentials.credentials
    token_data = security_manager.verify_token(token)
    if not token_data or not token_data.sub:
        raise credentials_exception
    return token_data.sub


# 依赖：获取当前用户对象
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(_security_scheme)) -> User:
    user_id = await get_current_user_id(credentials)
    # 通过数据库查询用户
    async with database_manager.get_async_session() as db:  # type: AsyncSession
        result = await db.execute(select(User).where(User.id == int(user_id)))
        user = result.scalar_one_or_none()
        if not user or not user.is_active:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Inactive or missing user")
        return user


# 初始化基础权限与角色（简化版本）
async def init_permissions_and_roles(db: Optional[AsyncSession] = None) -> None:
    """
    初始化基础权限与角色，幂等操作。支持传入外部会话，未传入则内部创建会话。
    """
    if db is None:
        async with database_manager.get_async_session() as session:  # type: ignore
            await _ensure_roles_permissions(session)
            await session.commit()
    else:
        await _ensure_roles_permissions(db)
        await db.commit()


async def _ensure_roles_permissions(session: AsyncSession) -> None:
    """确保基础权限和角色存在"""
    base_permissions = [
        ("users:view", "users", "view"),
        ("users:manage", "users", "manage"),
        ("wireguard:view", "wireguard", "view"),
        ("wireguard:manage", "wireguard", "manage"),
    ]

    existing = {p.name for p in (await session.execute(select(Permission))).scalars().all()}
    for name, resource, action in base_permissions:
        if name not in existing:
            session.add(Permission(name=name, resource=resource, action=action, description=name))
    await session.flush()

    # 确保存在基础角色
    role_result = await session.execute(select(Role).where(Role.name.in_(["admin", "user"])) )
    roles = {r.name: r for r in role_result.scalars().all()}
    if "admin" not in roles:
        admin_role = Role(name="admin", display_name="Administrator", is_system=True)
        session.add(admin_role)
    if "user" not in roles:
        user_role = Role(name="user", display_name="User", is_system=True)
        session.add(user_role)
    await session.flush()
