"""
JWT令牌黑名单管理
支持令牌撤销和验证，可选择内存存储或数据库存储
"""
import time
import os
from typing import Dict, Optional, Set, List
from datetime import datetime, timedelta
from ..core.logging import get_logger

logger = get_logger(__name__)

# 简单的内存存储用于令牌黑名单（生产环境应该使用Redis）
_token_blacklist: Dict[str, float] = {}
_token_jti_map: Dict[str, str] = {}  # jti -> token 映射

# 清理间隔（秒）
_CLEANUP_INTERVAL = 3600  # 1小时
_last_cleanup = time.time()

# 从环境变量获取存储类型，默认为内存存储
USE_DATABASE_STORAGE = os.getenv("USE_DATABASE_BLACKLIST", "false").lower() == "true"


class TokenBlacklist:
    """令牌黑名单管理类，支持内存和数据库两种存储方式"""
    
    def __init__(self, use_database=False):
        """初始化黑名单管理器
        
        Args:
            use_database: 是否使用数据库存储，默认为False使用内存存储
        """
        self.use_database = use_database or USE_DATABASE_STORAGE
        self._db_blacklist = None
        
        # 如果使用数据库存储，初始化数据库黑名单
        if self.use_database:
            try:
                from .database_token_blacklist import DatabaseTokenBlacklist
                self._db_blacklist = DatabaseTokenBlacklist()
                logger.info("使用数据库存储令牌黑名单")
            except ImportError as e:
                logger.warning(f"无法导入数据库黑名单模块，回退到内存存储: {e}")
                self.use_database = False
        else:
            logger.info("使用内存存储令牌黑名单")
    
    def add_token(self, token: str, expires_at: Optional[float] = None, jti: Optional[str] = None) -> bool:
        """将令牌添加到黑名单
        
        Args:
            token: JWT令牌
            expires_at: 令牌过期时间（Unix时间戳），如果为None则从令牌中解析
            jti: JWT ID，如果为None则从令牌中解析
            
        Returns:
            bool: 是否成功添加
        """
        if self.use_database and self._db_blacklist:
            return self._db_blacklist.add_token(token, expires_at, jti)
        
        # 内存存储实现
        global _token_blacklist, _token_jti_map, _last_cleanup
        
        # 清理过期令牌
        self._cleanup_expired_tokens()
        
        # 如果没有提供过期时间，尝试从令牌中解析
        if expires_at is None:
            try:
                # 这里应该解析JWT获取过期时间，简化实现
                # 实际应该使用jwt.decode解析
                expires_at = time.time() + 3600  # 默认1小时后过期
            except Exception:
                expires_at = time.time() + 3600
        
        # 如果提供了jti，建立映射关系
        if jti:
            _token_jti_map[jti] = token
        
        _token_blacklist[token] = expires_at
        logger.info(f"令牌已添加到黑名单: {token[:10]}...")
        return True
    
    def is_blacklisted(self, token: str) -> bool:
        """检查令牌是否在黑名单中
        
        Args:
            token: JWT令牌
            
        Returns:
            bool: 是否在黑名单中
        """
        if self.use_database and self._db_blacklist:
            return self._db_blacklist.is_blacklisted(token)
        
        # 内存存储实现
        global _token_blacklist
        
        # 清理过期令牌
        self._cleanup_expired_tokens()
        
        # 检查令牌是否在黑名单中
        if token in _token_blacklist:
            return True
            
        # 如果不在黑名单中，检查jti映射
        # 这里简化实现，实际应该解析JWT获取jti
        # 然后检查jti对应的token是否在黑名单中
        
        return False
    
    def remove_token(self, token: str) -> bool:
        """从黑名单中移除令牌
        
        Args:
            token: JWT令牌
            
        Returns:
            bool: 是否成功移除
        """
        if self.use_database and self._db_blacklist:
            return self._db_blacklist.remove_token(token)
        
        # 内存存储实现
        global _token_blacklist, _token_jti_map
        
        # 从黑名单中移除令牌
        if token in _token_blacklist:
            del _token_blacklist[token]
            
            # 从jti映射中移除
            jti_to_remove = None
            for jti, mapped_token in _token_jti_map.items():
                if mapped_token == token:
                    jti_to_remove = jti
                    break
                    
            if jti_to_remove:
                del _token_jti_map[jti_to_remove]
                
            logger.info(f"令牌已从黑名单移除: {token[:10]}...")
            return True
            
        return False
    
    def revoke_by_jti(self, jti: str) -> bool:
        """通过JTI撤销令牌
        
        Args:
            jti: JWT ID
            
        Returns:
            bool: 是否成功撤销
        """
        if self.use_database and self._db_blacklist:
            return self._db_blacklist.revoke_by_jti(jti)
        
        # 内存存储实现
        global _token_blacklist, _token_jti_map
        
        # 查找jti对应的令牌
        if jti in _token_jti_map:
            token = _token_jti_map[jti]
            # 添加到黑名单，使用当前时间+1小时作为过期时间
            return self.add_token(token, time.time() + 3600, jti)
            
        return False
    
    def revoke_user_tokens(self, user_id: int) -> int:
        """撤销用户的所有令牌
        
        Args:
            user_id: 用户ID
            
        Returns:
            int: 撤销的令牌数量
        """
        if self.use_database and self._db_blacklist:
            return self._db_blacklist.revoke_user_tokens(user_id)
        
        # 内存存储实现
        # 这里简化实现，实际应该解析JWT获取用户ID
        # 然后撤销该用户的所有令牌
        logger.warning("内存存储不支持按用户ID撤销令牌，请使用数据库存储")
        return 0
    
    def _cleanup_expired_tokens(self):
        """清理过期的令牌"""
        if self.use_database and self._db_blacklist:
            return self._db_blacklist._cleanup_expired_tokens()
        
        # 内存存储实现
        global _token_blacklist, _last_cleanup
        
        current_time = time.time()
        
        # 检查是否需要清理
        if current_time - _last_cleanup < _CLEANUP_INTERVAL:
            return
            
        # 清理过期令牌
        expired_tokens = [
            token for token, expires_at in _token_blacklist.items()
            if expires_at <= current_time
        ]
        
        for token in expired_tokens:
            del _token_blacklist[token]
            
            # 从jti映射中移除
            jti_to_remove = None
            for jti, mapped_token in _token_jti_map.items():
                if mapped_token == token:
                    jti_to_remove = jti
                    break
                    
            if jti_to_remove:
                del _token_jti_map[jti_to_remove]
        
        _last_cleanup = current_time
        
        if expired_tokens:
            logger.info(f"清理了 {len(expired_tokens)} 个过期令牌")
    
    def get_blacklisted_count(self) -> int:
        """获取黑名单中的令牌数量
        
        Returns:
            int: 黑名单中的令牌数量
        """
        if self.use_database and self._db_blacklist:
            return self._db_blacklist.get_blacklisted_count()
        
        # 内存存储实现
        global _token_blacklist
        self._cleanup_expired_tokens()
        return len(_token_blacklist)
    
    def get_all_blacklisted(self) -> List[str]:
        """获取所有黑名单中的令牌（仅用于调试）
        
        Returns:
            List[str]: 黑名单中的令牌列表
        """
        if self.use_database and self._db_blacklist:
            return self._db_blacklist.get_all_blacklisted()
        
        # 内存存储实现
        global _token_blacklist
        self._cleanup_expired_tokens()
        return list(_token_blacklist.keys())


# 全局令牌黑名单实例
token_blacklist = TokenBlacklist()


def add_to_blacklist(token: str, expires_at: Optional[float] = None, jti: Optional[str] = None) -> bool:
    """将令牌添加到黑名单（便捷函数）"""
    return token_blacklist.add_token(token, expires_at, jti)


def is_blacklisted(token: str) -> bool:
    """检查令牌是否在黑名单中（便捷函数）"""
    return token_blacklist.is_blacklisted(token)


def remove_from_blacklist(token: str) -> bool:
    """从黑名单移除令牌（便捷函数）"""
    return token_blacklist.remove_token(token)


def revoke_by_jti(jti: str) -> bool:
    """通过JTI撤销令牌（便捷函数）"""
    return token_blacklist.revoke_by_jti(jti)


def revoke_user_tokens(user_id: int) -> int:
    """撤销用户的所有令牌（便捷函数）"""
    return token_blacklist.revoke_user_tokens(user_id)


def get_blacklisted_count() -> int:
    """获取黑名单中的令牌数量（便捷函数）"""
    return token_blacklist.get_blacklisted_count()

