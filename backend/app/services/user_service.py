"""
用户服务层 - 实现完整的用户管理业务逻辑
"""
from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, update, delete
from sqlalchemy.orm import selectinload
from datetime import datetime, timedelta
import uuid

from ..core.logging import get_logger
from ..models.models_complete import User, Role, Permission, AuditLog, user_roles, role_permissions
from ..schemas.user import UserCreate, UserUpdate, UserResponse
from ..core.security_enhanced import security_manager, init_permissions_and_roles
from ..utils.audit import audit_log

logger = get_logger(__name__)


class UserService:
    """用户服务类"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_user(self, user_data: UserCreate) -> User:
        """创建用户"""
        try:
            # 检查用户名和邮箱是否已存在
            existing_user = await self.get_user_by_username_or_email(
                user_data.username, user_data.email
            )
            if existing_user:
                if existing_user.username == user_data.username:
                    raise ValueError("用户名已存在")
                else:
                    raise ValueError("邮箱已存在")
            
            # 创建密码哈希
            hashed_password = security_manager.get_password_hash(user_data.password)
            
            # 创建用户对象
            user = User(
                username=user_data.username,
                email=user_data.email,
                hashed_password=hashed_password,
                full_name=user_data.full_name,
                phone=user_data.phone,
                is_active=user_data.is_active if hasattr(user_data, 'is_active') else True,
                is_superuser=user_data.is_superuser if hasattr(user_data, 'is_superuser') else False,
                password_changed_at=datetime.utcnow()
            )
            
            self.db.add(user)
            await self.db.flush()  # 获取用户ID
            
            # 分配默认角色
            if not user.is_superuser:
                await self.assign_default_role(user.id)
            
            await self.db.commit()
            
            # 记录审计日志
            await audit_log(
                self.db,
                action="user.create",
                resource_type="user",
                resource_id=str(user.id),
                description=f"创建用户: {user.username}",
                success=True
            )
            
            logger.info("User created", user_id=str(user.id), username=user.username)
            
            return user
            
        except Exception as e:
            await self.db.rollback()
            logger.error("Failed to create user", username=user_data.username, error=str(e))
            raise
    
    async def get_user_by_id(self, user_id: int) -> Optional[User]:
        """根据ID获取用户"""
        try:
            result = await self.db.execute(
                select(User)
                .options(selectinload(User.roles))
                .where(User.id == user_id)
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error("Failed to get user by ID", user_id=user_id, error=str(e))
            return None
    
    async def get_user_by_username(self, username: str) -> Optional[User]:
        """根据用户名获取用户"""
        try:
            result = await self.db.execute(
                select(User)
                .options(selectinload(User.roles))
                .where(User.username == username)
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Failed to get user by username: {username}, error: {str(e)}")
            return None
    
    async def get_user_by_email(self, email: str) -> Optional[User]:
        """根据邮箱获取用户"""
        try:
            result = await self.db.execute(
                select(User)
                .options(selectinload(User.roles))
                .where(User.email == email)
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Failed to get user by email: {email}, error: {str(e)}")
            return None
    
    async def get_user_by_username_or_email(self, username: str, email: str) -> Optional[User]:
        """根据用户名或邮箱获取用户"""
        try:
            result = await self.db.execute(
                select(User)
                .options(selectinload(User.roles))
                .where(or_(User.username == username, User.email == email))
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Failed to get user by username or email: {username}/{email}, error: {str(e)}")
            return None
    
    async def update_user(self, user_id: int, user_data: UserUpdate) -> User:
        """更新用户信息"""
        try:
            user = await self.get_user_by_id(user_id)
            if not user:
                raise ValueError("用户不存在")
            
            # 更新字段
            update_data = user_data.dict(exclude_unset=True)
            
            # 检查用户名和邮箱唯一性
            if 'username' in update_data and update_data['username'] != user.username:
                existing_user = await self.get_user_by_username(update_data['username'])
                if existing_user:
                    raise ValueError("用户名已存在")
            
            if 'email' in update_data and update_data['email'] != user.email:
                existing_user = await self.get_user_by_email(update_data['email'])
                if existing_user:
                    raise ValueError("邮箱已存在")
            
            # 更新用户信息
            for field, value in update_data.items():
                if hasattr(user, field):
                    setattr(user, field, value)
            
            user.updated_at = datetime.utcnow()
            
            await self.db.commit()
            
            # 记录审计日志
            await audit_log(
                self.db,
                action="user.update",
                resource_type="user",
                resource_id=str(user.id),
                description=f"更新用户信息: {user.username}",
                success=True
            )
            
            logger.info(f"User updated: {user.username} (ID: {user.id})")
            
            return user
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Failed to update user: {user_id}, error: {str(e)}")
            raise
    
    async def update_password(self, user_id: int, new_password_hash: str) -> bool:
        """更新用户密码"""
        try:
            user = await self.get_user_by_id(user_id)
            if not user:
                raise ValueError("用户不存在")
            
            # 更新密码
            user.hashed_password = new_password_hash
            user.password_changed_at = datetime.utcnow()
            user.updated_at = datetime.utcnow()
            
            await self.db.commit()
            
            # 记录审计日志
            await audit_log(
                self.db,
                action="user.password_change",
                resource_type="user",
                resource_id=str(user.id),
                description=f"用户修改密码: {user.username}",
                success=True
            )
            
            logger.info(f"Password updated: {user.username} (ID: {user.id})")
            
            return True
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Failed to update password: {user_id}, error: {str(e)}")
            raise
    
    async def delete_user(self, user_id: int) -> bool:
        """删除用户"""
        try:
            user = await self.get_user_by_id(user_id)
            if not user:
                raise ValueError("用户不存在")
            
            # 软删除：设置为非活跃状态
            user.is_active = False
            user.updated_at = datetime.utcnow()
            
            await self.db.commit()
            
            # 记录审计日志
            await audit_log(
                self.db,
                action="user.delete",
                resource_type="user",
                resource_id=str(user.id),
                description=f"删除用户: {user.username}",
                success=True
            )
            
            logger.info(f"User deleted: {user.username} (ID: {user.id})")
            
            return True
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Failed to delete user: {user_id}, error: {str(e)}")
            raise
    
    async def list_users(
        self, 
        skip: int = 0, 
        limit: int = 100,
        search: Optional[str] = None,
        is_active: Optional[bool] = None
    ) -> List[User]:
        """获取用户列表"""
        try:
            query = select(User).options(selectinload(User.roles))
            
            # 添加搜索条件
            if search:
                query = query.where(
                    or_(
                        User.username.ilike(f"%{search}%"),
                        User.email.ilike(f"%{search}%"),
                        User.full_name.ilike(f"%{search}%")
                    )
                )
            
            # 添加活跃状态过滤
            if is_active is not None:
                query = query.where(User.is_active == is_active)
            
            # 排序和分页
            query = query.order_by(User.created_at.desc()).offset(skip).limit(limit)
            
            result = await self.db.execute(query)
            return result.scalars().all()
            
        except Exception as e:
            logger.error(f"Failed to list users, error: {str(e)}")
            return []
    
    async def count_users(self, search: Optional[str] = None, is_active: Optional[bool] = None) -> int:
        """统计用户数量"""
        try:
            query = select(func.count(User.id))
            
            if search:
                query = query.where(
                    or_(
                        User.username.ilike(f"%{search}%"),
                        User.email.ilike(f"%{search}%"),
                        User.full_name.ilike(f"%{search}%")
                    )
                )
            
            if is_active is not None:
                query = query.where(User.is_active == is_active)
            
            result = await self.db.execute(query)
            return result.scalar()
            
        except Exception as e:
            logger.error("Failed to count users", error=str(e))
            return 0
    
    async def assign_role(self, user_id: int, role_id: int) -> bool:
        """分配角色给用户"""
        try:
            # 检查用户和角色是否存在
            user = await self.get_user_by_id(user_id)
            if not user:
                raise ValueError("用户不存在")
            
            role = await self.get_role_by_id(role_id)
            if not role:
                raise ValueError("角色不存在")
            
            # 检查是否已经分配了该角色
            existing_role = await self.db.execute(
                select(UserRole).where(
                    and_(UserRole.user_id == user_id, UserRole.role_id == role_id)
                )
            )
            
            if existing_role.scalar_one_or_none():
                return True  # 已经分配了该角色
            
            # 分配角色
            user_role = UserRole(user_id=user_id, role_id=role_id)
            self.db.add(user_role)
            await self.db.commit()
            
            # 记录审计日志
            await audit_log(
                self.db,
                action="user.role_assign",
                resource_type="user",
                resource_id=str(user_id),
                description=f"分配角色 {role.name} 给用户 {user.username}",
                success=True
            )
            
            logger.info("Role assigned", user_id=user_id, role_id=role_id)
            
            return True
            
        except Exception as e:
            await self.db.rollback()
            logger.error("Failed to assign role", user_id=user_id, role_id=role_id, error=str(e))
            raise
    
    async def remove_role(self, user_id: int, role_id: int) -> bool:
        """移除用户角色"""
        try:
            # 检查用户和角色是否存在
            user = await self.get_user_by_id(user_id)
            if not user:
                raise ValueError("用户不存在")
            
            role = await self.get_role_by_id(role_id)
            if not role:
                raise ValueError("角色不存在")
            
            # 移除角色
            result = await self.db.execute(
                delete(UserRole).where(
                    and_(UserRole.user_id == user_id, UserRole.role_id == role_id)
                )
            )
            
            if result.rowcount == 0:
                return False  # 用户没有该角色
            
            await self.db.commit()
            
            # 记录审计日志
            await audit_log(
                self.db,
                action="user.role_remove",
                resource_type="user",
                resource_id=str(user_id),
                description=f"移除用户 {user.username} 的角色 {role.name}",
                success=True
            )
            
            logger.info("Role removed", user_id=user_id, role_id=role_id)
            
            return True
            
        except Exception as e:
            await self.db.rollback()
            logger.error("Failed to remove role", user_id=user_id, role_id=role_id, error=str(e))
            raise
    
    async def get_user_roles(self, user_id: int) -> List[Role]:
        """获取用户角色列表"""
        try:
            result = await self.db.execute(
                select(Role)
                .join(UserRole, Role.id == UserRole.role_id)
                .where(UserRole.user_id == user_id)
            )
            return result.scalars().all()
        except Exception as e:
            logger.error("Failed to get user roles", user_id=user_id, error=str(e))
            return []
    
    async def get_user_permissions(self, user_id: int) -> List[Permission]:
        """获取用户权限列表"""
        try:
            # 检查是否为超级用户
            user = await self.get_user_by_id(user_id)
            if user and user.is_superuser:
                # 超级用户拥有所有权限
                result = await self.db.execute(select(Permission))
                return result.scalars().all()
            
            # 获取用户通过角色拥有的权限
            result = await self.db.execute(
                select(Permission)
                .join(RolePermission, Permission.id == RolePermission.permission_id)
                .join(Role, RolePermission.role_id == Role.id)
                .join(UserRole, Role.id == UserRole.role_id)
                .where(UserRole.user_id == user_id)
            )
            return result.scalars().all()
            
        except Exception as e:
            logger.error("Failed to get user permissions", user_id=user_id, error=str(e))
            return []
    
    async def assign_default_role(self, user_id: int) -> bool:
        """分配默认角色给用户"""
        try:
            # 获取默认用户角色
            result = await self.db.execute(
                select(Role).where(Role.name == "user")
            )
            default_role = result.scalar_one_or_none()
            
            if not default_role:
                # 如果默认角色不存在，创建它
                await init_permissions_and_roles(self.db)
                result = await self.db.execute(
                    select(Role).where(Role.name == "user")
                )
                default_role = result.scalar_one_or_none()
            
            if default_role:
                return await self.assign_role(user_id, default_role.id)
            
            return False
            
        except Exception as e:
            logger.error("Failed to assign default role", user_id=user_id, error=str(e))
            return False
    
    async def get_role_by_id(self, role_id: int) -> Optional[Role]:
        """根据ID获取角色"""
        try:
            result = await self.db.execute(
                select(Role)
                .options(selectinload(Role.permissions))
                .where(Role.id == role_id)
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error("Failed to get role by ID", role_id=role_id, error=str(e))
            return None
    
    async def list_roles(self) -> List[Role]:
        """获取角色列表"""
        try:
            result = await self.db.execute(
                select(Role)
                .options(selectinload(Role.permissions))
                .order_by(Role.name)
            )
            return result.scalars().all()
        except Exception as e:
            logger.error("Failed to list roles", error=str(e))
            return []
    
    async def list_permissions(self) -> List[Permission]:
        """获取权限列表"""
        try:
            result = await self.db.execute(
                select(Permission).order_by(Permission.resource, Permission.action)
            )
            return result.scalars().all()
        except Exception as e:
            logger.error("Failed to list permissions", error=str(e))
            return []
    
    async def lock_user(self, user_id: int, duration_minutes: int = 30) -> bool:
        """锁定用户"""
        try:
            user = await self.get_user_by_id(user_id)
            if not user:
                raise ValueError("用户不存在")
            
            user.locked_until = datetime.utcnow() + timedelta(minutes=duration_minutes)
            user.updated_at = datetime.utcnow()
            
            await self.db.commit()
            
            # 记录审计日志
            await audit_log(
                self.db,
                action="user.lock",
                resource_type="user",
                resource_id=str(user_id),
                description=f"锁定用户 {user.username} {duration_minutes} 分钟",
                success=True
            )
            
            logger.info("User locked", user_id=user_id, duration=duration_minutes)
            
            return True
            
        except Exception as e:
            await self.db.rollback()
            logger.error("Failed to lock user", user_id=user_id, error=str(e))
            raise
    
    async def unlock_user(self, user_id: int) -> bool:
        """解锁用户"""
        try:
            user = await self.get_user_by_id(user_id)
            if not user:
                raise ValueError("用户不存在")
            
            user.locked_until = None
            user.failed_login_attempts = 0
            user.updated_at = datetime.utcnow()
            
            await self.db.commit()
            
            # 记录审计日志
            await audit_log(
                self.db,
                action="user.unlock",
                resource_type="user",
                resource_id=str(user_id),
                description=f"解锁用户 {user.username}",
                success=True
            )
            
            logger.info("User unlocked", user_id=user_id)
            
            return True
            
        except Exception as e:
            await self.db.rollback()
            logger.error("Failed to unlock user", user_id=user_id, error=str(e))
            raise
    
    async def increment_failed_login(self, user_id: int) -> bool:
        """增加失败登录次数"""
        try:
            user = await self.get_user_by_id(user_id)
            if not user:
                return False
            
            user.failed_login_attempts += 1
            
            # 如果失败次数达到阈值，锁定用户
            if user.failed_login_attempts >= 5:  # 可配置
                user.locked_until = datetime.utcnow() + timedelta(minutes=30)
            
            user.updated_at = datetime.utcnow()
            
            await self.db.commit()
            
            logger.info("Failed login incremented", user_id=user_id, attempts=user.failed_login_attempts)
            
            return True
            
        except Exception as e:
            await self.db.rollback()
            logger.error("Failed to increment failed login", user_id=user_id, error=str(e))
            return False