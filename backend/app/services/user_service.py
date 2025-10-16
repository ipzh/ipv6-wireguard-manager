"""
用户服务
"""
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
import secrets
import hashlib

from ..core.security import verify_password, get_password_hash
from ..models.user import User, Role

# 尝试导入User模式，如果失败则使用字典代替
try:
    from ...schemas.user import UserCreate, UserUpdate
    USER_SCHEMA_AVAILABLE = True
except ImportError:
    USER_SCHEMA_AVAILABLE = False
    UserCreate = None
    UserUpdate = None

class UserService:
    """用户服务类"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """根据ID获取用户"""
        result = await self.db.execute(
            select(User)
            .options(selectinload(User.roles))
            .where(User.id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def get_user_by_username(self, username: str) -> Optional[User]:
        """根据用户名获取用户"""
        result = await self.db.execute(
            select(User)
            .options(selectinload(User.roles))
            .where(User.username == username)
        )
        return result.scalar_one_or_none()
    
    async def get_user_by_email(self, email: str) -> Optional[User]:
        """根据邮箱获取用户"""
        result = await self.db.execute(
            select(User)
            .options(selectinload(User.roles))
            .where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    async def authenticate_user(self, username: str, password: str) -> Optional[User]:
        """验证用户凭据"""
        user = await self.get_user_by_username(username)
        if not user:
            return None
        
        if not verify_password(password, user.password_hash):
            return None
        
        return user
    
    async def create_user(self, user_data):
        """创建用户"""
        # 如果UserCreate不可用，假设user_data是字典
        if not USER_SCHEMA_AVAILABLE:
            username = user_data.get("username")
            email = user_data.get("email")
            password = user_data.get("password")
            is_active = user_data.get("is_active", True)
            is_superuser = user_data.get("is_superuser", False)
        else:
            username = user_data.username
            email = user_data.email
            password = user_data.password
            is_active = user_data.is_active
            is_superuser = user_data.is_superuser
        
        # 检查用户名是否已存在
        existing_user = await self.get_user_by_username(username)
        if existing_user:
            raise ValueError("用户名已存在")
        
        # 检查邮箱是否已存在
        existing_email = await self.get_user_by_email(email)
        if existing_email:
            raise ValueError("邮箱已存在")
        
        # 生成盐值
        salt = secrets.token_hex(16)
        
        # 创建用户
        user = User(
            username=username,
            email=email,
            password_hash=get_password_hash(password),
            salt=salt,
            is_active=is_active,
            is_superuser=is_superuser
        )
        
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        
        return user
    
    async def update_user(self, user_id: str, user_data) -> Optional[User]:
        """更新用户"""
        user = await self.get_user_by_id(user_id)
        if not user:
            return None
        
        # 如果UserUpdate不可用，假设user_data是字典
        if not USER_SCHEMA_AVAILABLE:
            update_data = user_data
        else:
            update_data = user_data.dict(exclude_unset=True)
        
        if "password" in update_data:
            update_data["password_hash"] = get_password_hash(update_data.pop("password"))
        
        for field, value in update_data.items():
            setattr(user, field, value)
        
        await self.db.commit()
        await self.db.refresh(user)
        
        return user
    
    async def delete_user(self, user_id: str) -> bool:
        """删除用户"""
        user = await self.get_user_by_id(user_id)
        if not user:
            return False
        
        await self.db.delete(user)
        await self.db.commit()
        
        return True
    
    async def get_users(self, skip: int = 0, limit: int = 100) -> List[User]:
        """获取用户列表"""
        result = await self.db.execute(
            select(User)
            .options(selectinload(User.roles))
            .offset(skip)
            .limit(limit)
        )
        return result.scalars().all()
    
    async def get_roles(self) -> List[Role]:
        """获取角色列表"""
        result = await self.db.execute(select(Role))
        return result.scalars().all()
    
    async def create_superuser(self, username: str, email: str, password: str) -> User:
        """创建超级用户"""
        if not USER_SCHEMA_AVAILABLE:
            # 如果UserCreate不可用，使用字典
            user_data = {
                "username": username,
                "email": email,
                "password": password,
                "is_active": True,
                "is_superuser": True
            }
        else:
            user_data = UserCreate(
                username=username,
                email=email,
                password=password,
                is_active=True,
                is_superuser=True
            )
        
        return await self.create_user(user_data)
