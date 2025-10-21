# 密码策略增强模块

import re
import hashlib
import secrets
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from pydantic import BaseModel, validator
from passlib.context import CryptContext
from passlib.hash import bcrypt, argon2

class PasswordPolicy(BaseModel):
    """密码策略配置"""
    min_length: int = 12
    max_length: int = 128
    require_uppercase: bool = True
    require_lowercase: bool = True
    require_numbers: bool = True
    require_special_chars: bool = True
    special_chars: str = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    max_consecutive_chars: int = 3
    password_history_count: int = 5
    password_expiry_days: int = 90
    account_lockout_attempts: int = 5
    account_lockout_duration_minutes: int = 30

class PasswordValidator:
    """密码验证器"""
    
    def __init__(self, policy: PasswordPolicy):
        self.policy = policy
        self.pwd_context = CryptContext(
            schemes=["argon2", "bcrypt"],
            default="argon2",
            argon2__rounds=3,
            argon2__memory_cost=65536,
            argon2__parallelism=4
        )
    
    def validate_password_strength(self, password: str) -> Dict[str, Any]:
        """验证密码强度"""
        errors = []
        warnings = []
        
        # 长度检查
        if len(password) < self.policy.min_length:
            errors.append(f"密码长度至少需要 {self.policy.min_length} 个字符")
        elif len(password) > self.policy.max_length:
            errors.append(f"密码长度不能超过 {self.policy.max_length} 个字符")
        
        # 字符类型检查
        if self.policy.require_uppercase and not re.search(r'[A-Z]', password):
            errors.append("密码必须包含大写字母")
        
        if self.policy.require_lowercase and not re.search(r'[a-z]', password):
            errors.append("密码必须包含小写字母")
        
        if self.policy.require_numbers and not re.search(r'\d', password):
            errors.append("密码必须包含数字")
        
        if self.policy.require_special_chars:
            special_pattern = f"[{re.escape(self.policy.special_chars)}]"
            if not re.search(special_pattern, password):
                errors.append(f"密码必须包含特殊字符: {self.policy.special_chars}")
        
        # 连续字符检查
        if self._has_consecutive_chars(password, self.policy.max_consecutive_chars):
            warnings.append(f"密码包含超过 {self.policy.max_consecutive_chars} 个连续字符")
        
        # 常见密码检查
        if self._is_common_password(password):
            errors.append("密码过于简单，请使用更复杂的密码")
        
        # 计算密码强度分数
        strength_score = self._calculate_strength_score(password)
        
        return {
            "is_valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
            "strength_score": strength_score,
            "strength_level": self._get_strength_level(strength_score)
        }
    
    def _has_consecutive_chars(self, password: str, max_consecutive: int) -> bool:
        """检查是否有过多连续字符"""
        for i in range(len(password) - max_consecutive + 1):
            substring = password[i:i + max_consecutive + 1]
            if len(set(substring)) == 1:
                return True
        return False
    
    def _is_common_password(self, password: str) -> bool:
        """检查是否为常见密码"""
        common_passwords = [
            "password", "123456", "123456789", "qwerty", "abc123",
            "password123", "admin", "root", "user", "test"
        ]
        return password.lower() in common_passwords
    
    def _calculate_strength_score(self, password: str) -> int:
        """计算密码强度分数 (0-100)"""
        score = 0
        
        # 长度分数 (0-30)
        length_score = min(30, len(password) * 2)
        score += length_score
        
        # 字符类型分数 (0-40)
        char_types = 0
        if re.search(r'[a-z]', password):
            char_types += 1
        if re.search(r'[A-Z]', password):
            char_types += 1
        if re.search(r'\d', password):
            char_types += 1
        if re.search(f"[{re.escape(self.policy.special_chars)}]", password):
            char_types += 1
        
        score += char_types * 10
        
        # 复杂度分数 (0-30)
        entropy = self._calculate_entropy(password)
        complexity_score = min(30, entropy * 2)
        score += complexity_score
        
        return min(100, score)
    
    def _calculate_entropy(self, password: str) -> float:
        """计算密码熵值"""
        char_set_size = 0
        if re.search(r'[a-z]', password):
            char_set_size += 26
        if re.search(r'[A-Z]', password):
            char_set_size += 26
        if re.search(r'\d', password):
            char_set_size += 10
        if re.search(f"[{re.escape(self.policy.special_chars)}]", password):
            char_set_size += len(self.policy.special_chars)
        
        if char_set_size == 0:
            return 0
        
        return len(password) * (char_set_size ** 0.5)
    
    def _get_strength_level(self, score: int) -> str:
        """获取密码强度等级"""
        if score >= 80:
            return "非常强"
        elif score >= 60:
            return "强"
        elif score >= 40:
            return "中等"
        elif score >= 20:
            return "弱"
        else:
            return "非常弱"
    
    def hash_password(self, password: str) -> str:
        """哈希密码"""
        return self.pwd_context.hash(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """验证密码"""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def generate_secure_password(self, length: int = 16) -> str:
        """生成安全密码"""
        if length < self.policy.min_length:
            length = self.policy.min_length
        
        # 确保包含所有必需字符类型
        password_chars = []
        
        # 添加至少一个大写字母
        password_chars.append(secrets.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
        
        # 添加至少一个小写字母
        password_chars.append(secrets.choice("abcdefghijklmnopqrstuvwxyz"))
        
        # 添加至少一个数字
        password_chars.append(secrets.choice("0123456789"))
        
        # 添加至少一个特殊字符
        password_chars.append(secrets.choice(self.policy.special_chars))
        
        # 填充剩余长度
        all_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" + self.policy.special_chars
        for _ in range(length - 4):
            password_chars.append(secrets.choice(all_chars))
        
        # 随机打乱
        secrets.SystemRandom().shuffle(password_chars)
        
        return ''.join(password_chars)

class PasswordHistory:
    """密码历史管理"""
    
    def __init__(self, db_session):
        self.db_session = db_session
    
    def add_password_to_history(self, user_id: int, password_hash: str):
        """添加密码到历史记录"""
        # 这里需要实现数据库操作
        pass
    
    def is_password_in_history(self, user_id: int, password_hash: str) -> bool:
        """检查密码是否在历史记录中"""
        # 这里需要实现数据库查询
        return False
    
    def cleanup_old_passwords(self, user_id: int, keep_count: int = 5):
        """清理旧的密码历史记录"""
        # 这里需要实现数据库清理
        pass

class AccountLockout:
    """账户锁定管理"""
    
    def __init__(self, db_session):
        self.db_session = db_session
    
    def record_failed_attempt(self, user_id: int, ip_address: str):
        """记录失败尝试"""
        # 这里需要实现数据库记录
        pass
    
    def is_account_locked(self, user_id: int) -> bool:
        """检查账户是否被锁定"""
        # 这里需要实现数据库查询
        return False
    
    def unlock_account(self, user_id: int):
        """解锁账户"""
        # 这里需要实现数据库更新
        pass
    
    def get_lockout_info(self, user_id: int) -> Dict[str, Any]:
        """获取锁定信息"""
        # 这里需要实现数据库查询
        return {
            "is_locked": False,
            "failed_attempts": 0,
            "lockout_until": None
        }
