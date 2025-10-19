"""
API路径构建器模块
提供统一的API路径构建、验证和管理功能
"""

from .builder import APIPathBuilder
from .config import PathConfig, PathDefinition, PathMetadata
from .validator import PathValidator, ValidationResult
from .version_manager import VersionManager, APIVersion
from .middleware import (
    APIPathMiddleware, 
    VersionedAPIRoute, 
    APIPathDocumentation,
    setup_fastapi_integration
)

# 版本信息
__version__ = "1.0.0"

# 导出的主要类和函数
__all__ = [
    # 核心类
    "APIPathBuilder",
    "PathConfig",
    "PathDefinition",
    "PathMetadata",
    "PathValidator",
    "ValidationResult",
    "VersionManager",
    "APIVersion",
    
    # FastAPI集成
    "APIPathMiddleware",
    "VersionedAPIRoute",
    "APIPathDocumentation",
    "setup_fastapi_integration",
]

# 便捷函数
def create_api_path_builder(current_version: str = "v1") -> APIPathBuilder:
    """
    创建API路径构建器实例的便捷函数
    
    Args:
        current_version: 当前API版本
        
    Returns:
        APIPathBuilder: API路径构建器实例
    """
    try:
        version = APIVersion(current_version)
        version_manager = VersionManager(version)
        return APIPathBuilder(version_manager=version_manager)
    except ValueError:
        # 如果版本无效，使用默认版本
        version_manager = VersionManager()
        return APIPathBuilder(version_manager=version_manager)

def get_default_path_builder() -> APIPathBuilder:
    """
    获取默认的API路径构建器实例
    
    Returns:
        APIPathBuilder: 默认的API路径构建器实例
    """
    return APIPathBuilder()