"""
API版本管理器
负责管理API版本，包括当前版本、支持版本和已弃用版本
"""

from enum import Enum
from typing import Set, Dict, List, Optional


class APIVersion(Enum):
    """支持的API版本枚举"""
    V1 = "v1"
    V2 = "v2"
    V3 = "v3"


class VersionManager:
    """API版本管理器"""
    
    def __init__(self, current_version: APIVersion = APIVersion.V1):
        """
        初始化版本管理器
        
        Args:
            current_version: 当前使用的API版本
        """
        self.current_version = current_version
        self.supported_versions: Set[APIVersion] = {APIVersion.V1}
        self.deprecated_versions: Set[APIVersion] = set()
        self.version_endpoints: Dict[APIVersion, Set[str]] = {}
        self._initialize_default_versions()
    
    def _initialize_default_versions(self):
        """初始化默认版本配置"""
        self.supported_versions = {APIVersion.V1}
        self.deprecated_versions = set()
        
        # 初始化各版本支持的端点
        for version in APIVersion:
            self.version_endpoints[version] = set()
    
    def set_current_version(self, version: APIVersion) -> None:
        """
        设置当前API版本
        
        Args:
            version: 要设置的API版本
            
        Raises:
            ValueError: 如果版本不被支持
        """
        if version not in self.supported_versions:
            raise ValueError(f"版本 {version.value} 不被支持")
        self.current_version = version
    
    def get_current_version(self) -> APIVersion:
        """获取当前API版本"""
        return self.current_version
    
    def add_supported_version(self, version: APIVersion) -> None:
        """
        添加支持的API版本
        
        Args:
            version: 要添加的API版本
        """
        self.supported_versions.add(version)
        if version in self.deprecated_versions:
            self.deprecated_versions.remove(version)
    
    def add_deprecated_version(self, version: APIVersion) -> None:
        """
        添加已弃用的API版本
        
        Args:
            version: 要标记为已弃用的API版本
        """
        if version in self.supported_versions:
            self.supported_versions.remove(version)
        self.deprecated_versions.add(version)
    
    def remove_version(self, version: APIVersion) -> None:
        """
        完全移除API版本
        
        Args:
            version: 要移除的API版本
        """
        if version in self.supported_versions:
            self.supported_versions.remove(version)
        if version in self.deprecated_versions:
            self.deprecated_versions.remove(version)
        if version in self.version_endpoints:
            del self.version_endpoints[version]
    
    def is_version_supported(self, version: APIVersion) -> bool:
        """
        检查版本是否被支持
        
        Args:
            version: 要检查的API版本
            
        Returns:
            bool: 版本是否被支持
        """
        return version in self.supported_versions
    
    def is_version_deprecated(self, version: APIVersion) -> bool:
        """
        检查版本是否已弃用
        
        Args:
            version: 要检查的API版本
            
        Returns:
            bool: 版本是否已弃用
        """
        return version in self.deprecated_versions
    
    def get_supported_versions(self) -> List[APIVersion]:
        """获取所有支持的API版本"""
        return sorted(list(self.supported_versions), key=lambda x: x.value)
    
    def get_deprecated_versions(self) -> List[APIVersion]:
        """获取所有已弃用的API版本"""
        return sorted(list(self.deprecated_versions), key=lambda x: x.value)
    
    def register_endpoint(self, version: APIVersion, endpoint: str) -> None:
        """
        为特定版本注册端点
        
        Args:
            version: API版本
            endpoint: 端点路径
        """
        if version not in self.version_endpoints:
            self.version_endpoints[version] = set()
        self.version_endpoints[version].add(endpoint)
    
    def get_endpoints_for_version(self, version: APIVersion) -> Set[str]:
        """
        获取特定版本的所有端点
        
        Args:
            version: API版本
            
        Returns:
            Set[str]: 端点路径集合
        """
        return self.version_endpoints.get(version, set())
    
    def get_all_endpoints(self) -> Dict[APIVersion, Set[str]]:
        """获取所有版本的端点"""
        return self.version_endpoints.copy()
    
    def validate_endpoint_for_version(self, version: APIVersion, endpoint: str) -> bool:
        """
        验证端点是否属于特定版本
        
        Args:
            version: API版本
            endpoint: 端点路径
            
        Returns:
            bool: 端点是否属于该版本
        """
        return endpoint in self.get_endpoints_for_version(version)
    
    def migrate_endpoint(self, from_version: APIVersion, to_version: APIVersion, endpoint: str) -> None:
        """
        将端点从一个版本迁移到另一个版本
        
        Args:
            from_version: 源版本
            to_version: 目标版本
            endpoint: 要迁移的端点
        """
        if endpoint in self.version_endpoints.get(from_version, set()):
            self.version_endpoints[from_version].remove(endpoint)
            self.register_endpoint(to_version, endpoint)