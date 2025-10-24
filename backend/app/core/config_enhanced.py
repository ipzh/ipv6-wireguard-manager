"""
增强配置模块
提供统一的配置管理接口
"""
from .unified_config import UnifiedSettings

# 创建全局设置实例
settings = UnifiedSettings()

# 兼容性导出
__all__ = ['settings']
