"""
用户和权限相关模型
"""
from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, Table
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from ..core.database import Base


# 用户角色关联表
user_roles = Table(
    'user_roles',
    Base.metadata,
    Column('user_id', UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True),
    Column('role_id', UUID(as_uuid=True), ForeignKey('roles.id', ondelete='CASCADE'), primary_key=True),
)


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    salt = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_superuser = Column(Boolean, default=False, nullable=False)
    last_login = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 关系
    roles = relationship("Role", secondary=user_roles, back_populates="users")
    audit_logs = relationship("AuditLog", back_populates="user")

    def __repr__(self):
        return f"<User(id={self.id}, username={self.username})>"


class Role(Base):
    """角色模型"""
    __tablename__ = "roles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    permissions = Column(JSONB, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    users = relationship("User", secondary=user_roles, back_populates="roles")

    def __repr__(self):
        return f"<Role(id={self.id}, name={self.name})>"


class UserRole(Base):
    """用户角色关联模型（备用）"""
    __tablename__ = "user_role_relations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    role_id = Column(UUID(as_uuid=True), ForeignKey('roles.id', ondelete='CASCADE'), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<UserRole(user_id={self.user_id}, role_id={self.role_id})>"
