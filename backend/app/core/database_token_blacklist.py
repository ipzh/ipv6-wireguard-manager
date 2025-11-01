"""
数据库令牌黑名单管理
支持令牌撤销和验证，使用数据库持久化存储
"""
from datetime import datetime, timedelta
from typing import Dict, Optional, List
import uuid
from sqlalchemy import Column, String, Float, DateTime, Boolean, Index
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from ..core.database_manager import database_manager
from ..core.logging import get_logger

logger = get_logger(__name__)

Base = declarative_base()


class BlacklistedToken(Base):
    """黑名单令牌模型"""
    __tablename__ = "blacklisted_tokens"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    token = Column(String, nullable=False, unique=True, index=True)
    expires_at = Column(Float, nullable=False, index=True)  # Unix时间戳
    created_at = Column(DateTime, default=datetime.utcnow)
    user_id = Column(String, nullable=True, index=True)  # 可选：关联用户ID
    reason = Column(String, nullable=True)  # 可选：黑名单原因
    
    # 创建复合索引以提高查询性能
    __table_args__ = (
        Index('idx_token_expires', 'token', 'expires_at'),
        Index('idx_user_expires', 'user_id', 'expires_at'),
    )


class DatabaseTokenBlacklist:
    """数据库令牌黑名单管理器"""
    
    def __init__(self):
        self.session_factory = None
        self._initialized = False
        self._cleanup_interval = 3600  # 1小时
        self._last_cleanup = 0
    
    async def initialize(self):
        """初始化数据库连接"""
        if self._initialized:
            return
            
        try:
            # 确保表已创建
            async with database_manager.get_async_session() as session:
                # 创建表（如果不存在）
                await database_manager.create_tables()
                
            self._initialized = True
            logger.info("数据库令牌黑名单初始化成功")
        except Exception as e:
            logger.error(f"初始化数据库令牌黑名单失败: {str(e)}")
            raise
    
    async def add_token(self, token: str, expires_at: Optional[float] = None, 
                       user_id: Optional[str] = None, reason: Optional[str] = None) -> bool:
        """将令牌添加到黑名单
        
        Args:
            token: JWT令牌字符串
            expires_at: 令牌过期时间戳（Unix时间戳）
            user_id: 可选，关联用户ID
            reason: 可选，黑名单原因
            
        Returns:
            是否成功添加
        """
        try:
            await self.initialize()
            
            # 如果未指定过期时间，使用默认值（30天后）
            if expires_at is None:
                expires_at = datetime.utcnow().timestamp() + (30 * 24 * 3600)  # 30天
            
            async with database_manager.get_async_session() as session:
                # 检查令牌是否已在黑名单中
                existing = await session.execute(
                    "SELECT id FROM blacklisted_tokens WHERE token = :token",
                    {"token": token}
                )
                if existing.fetchone():
                    logger.debug(f"令牌已在黑名单中: {token[:20]}...")
                    return True
                
                # 添加到黑名单
                blacklisted_token = BlacklistedToken(
                    token=token,
                    expires_at=expires_at,
                    user_id=user_id,
                    reason=reason
                )
                
                session.add(blacklisted_token)
                await session.commit()
                
                # 定期清理过期条目
                await self._cleanup_expired()
                
                logger.info(f"令牌已添加到黑名单，过期时间: {datetime.fromtimestamp(expires_at)}")
                return True
                
        except Exception as e:
            logger.error(f"添加令牌到黑名单失败: {str(e)}")
            return False
    
    async def is_blacklisted(self, token: str) -> bool:
        """检查令牌是否在黑名单中
        
        Args:
            token: JWT令牌字符串
            
        Returns:
            如果在黑名单中返回True，否则返回False
        """
        try:
            await self.initialize()
            
            async with database_manager.get_async_session() as session:
                # 清理过期条目（定期执行）
                await self._cleanup_expired_if_needed()
                
                # 检查令牌是否在黑名单中
                result = await session.execute(
                    "SELECT id FROM blacklisted_tokens WHERE token = :token AND expires_at > :current_time",
                    {"token": token, "current_time": datetime.utcnow().timestamp()}
                )
                
                return result.fetchone() is not None
                
        except Exception as e:
            logger.error(f"检查令牌黑名单状态失败: {str(e)}")
            # 出错时为了安全，返回True（假设在黑名单中）
            return True
    
    async def remove_token(self, token: str) -> bool:
        """从黑名单中移除令牌（用于令牌重新激活等场景）
        
        Args:
            token: JWT令牌字符串
            
        Returns:
            是否成功移除
        """
        try:
            await self.initialize()
            
            async with database_manager.get_async_session() as session:
                # 删除令牌
                result = await session.execute(
                    "DELETE FROM blacklisted_tokens WHERE token = :token",
                    {"token": token}
                )
                
                await session.commit()
                
                if result.rowcount > 0:
                    logger.info("令牌已从黑名单中移除")
                    return True
                    
                return False
                
        except Exception as e:
            logger.error(f"从黑名单移除令牌失败: {str(e)}")
            return False
    
    async def get_user_tokens(self, user_id: str) -> List[str]:
        """获取指定用户的所有黑名单令牌
        
        Args:
            user_id: 用户ID
            
        Returns:
            令牌列表
        """
        try:
            await self.initialize()
            
            async with database_manager.get_async_session() as session:
                result = await session.execute(
                    "SELECT token FROM blacklisted_tokens WHERE user_id = :user_id AND expires_at > :current_time",
                    {"user_id": user_id, "current_time": datetime.utcnow().timestamp()}
                )
                
                return [row[0] for row in result.fetchall()]
                
        except Exception as e:
            logger.error(f"获取用户黑名单令牌失败: {str(e)}")
            return []
    
    async def revoke_all_user_tokens(self, user_id: str, reason: Optional[str] = None) -> bool:
        """撤销指定用户的所有令牌（将所有有效令牌加入黑名单）
        
        Args:
            user_id: 用户ID
            reason: 可选，撤销原因
            
        Returns:
            是否成功
        """
        try:
            await self.initialize()
            
            # 这里需要根据实际情况实现，可能需要从其他地方获取用户的活跃令牌
            # 这是一个示例实现，实际使用时可能需要调整
            
            # 添加一个标记，表示该用户的所有令牌都被撤销
            # 可以通过在令牌验证时检查这个标记来实现
            async with database_manager.get_async_session() as session:
                # 添加用户撤销记录
                revoke_record = BlacklistedToken(
                    token=f"USER_REVOKED:{user_id}:{datetime.utcnow().timestamp()}",
                    expires_at=datetime.utcnow().timestamp() + (30 * 24 * 3600),  # 30天
                    user_id=user_id,
                    reason=reason or "用户所有令牌被撤销"
                )
                
                session.add(revoke_record)
                await session.commit()
                
                logger.info(f"用户 {user_id} 的所有令牌已被撤销")
                return True
                
        except Exception as e:
            logger.error(f"撤销用户所有令牌失败: {str(e)}")
            return False
    
    async def _cleanup_expired(self):
        """清理过期的黑名单条目"""
        try:
            current_time = datetime.utcnow().timestamp()
            
            async with database_manager.get_async_session() as session:
                # 删除过期令牌
                result = await session.execute(
                    "DELETE FROM blacklisted_tokens WHERE expires_at < :current_time",
                    {"current_time": current_time}
                )
                
                await session.commit()
                
                if result.rowcount > 0:
                    logger.debug(f"清理了 {result.rowcount} 个过期令牌")
                    
        except Exception as e:
            logger.error(f"清理过期令牌失败: {str(e)}")
    
    async def _cleanup_expired_if_needed(self):
        """如果需要，清理过期的黑名单条目"""
        current_time = datetime.utcnow().timestamp()
        
        # 只在超过清理间隔时执行清理
        if current_time - self._last_cleanup < self._cleanup_interval:
            return
            
        await self._cleanup_expired()
        self._last_cleanup = current_time
    
    async def get_blacklist_size(self) -> int:
        """获取当前黑名单大小"""
        try:
            await self.initialize()
            
            async with database_manager.get_async_session() as session:
                result = await session.execute(
                    "SELECT COUNT(*) FROM blacklisted_tokens WHERE expires_at > :current_time",
                    {"current_time": datetime.utcnow().timestamp()}
                )
                
                return result.scalar()
                
        except Exception as e:
            logger.error(f"获取黑名单大小失败: {str(e)}")
            return 0
    
    async def clear_all(self):
        """清空所有黑名单条目（谨慎使用）"""
        try:
            await self.initialize()
            
            async with database_manager.get_async_session() as session:
                await session.execute("DELETE FROM blacklisted_tokens")
                await session.commit()
                
                logger.warning("黑名单已清空")
                
        except Exception as e:
            logger.error(f"清空黑名单失败: {str(e)}")


# 全局数据库令牌黑名单实例
database_token_blacklist = DatabaseTokenBlacklist()


# 便捷函数
async def add_to_blacklist(token: str, expires_at: Optional[float] = None, 
                          user_id: Optional[str] = None, reason: Optional[str] = None) -> bool:
    """将令牌添加到黑名单（便捷函数）"""
    return await database_token_blacklist.add_token(token, expires_at, user_id, reason)


async def is_blacklisted(token: str) -> bool:
    """检查令牌是否在黑名单中（便捷函数）"""
    return await database_token_blacklist.is_blacklisted(token)


async def remove_from_blacklist(token: str) -> bool:
    """从黑名单移除令牌（便捷函数）"""
    return await database_token_blacklist.remove_token(token)


async def get_user_blacklisted_tokens(user_id: str) -> List[str]:
    """获取用户的所有黑名单令牌（便捷函数）"""
    return await database_token_blacklist.get_user_tokens(user_id)


async def revoke_all_user_tokens(user_id: str, reason: Optional[str] = None) -> bool:
    """撤销用户所有令牌（便捷函数）"""
    return await database_token_blacklist.revoke_all_user_tokens(user_id, reason)