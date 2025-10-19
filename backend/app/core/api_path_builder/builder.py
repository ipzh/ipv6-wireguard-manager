"""
API路径构建器
核心模块，提供统一的API路径构建、验证和管理功能
"""

from typing import Dict, Any, Optional, List, Union, Tuple
from .config import PathConfig, PathDefinition, PathMetadata
from .validator import PathValidator, ValidationResult
from .version_manager import VersionManager, APIVersion


class APIPathBuilder:
    """统一的API路径构建器"""
    
    def __init__(self, config: PathConfig = None, version_manager: VersionManager = None):
        """
        初始化API路径构建器
        
        Args:
            config: 路径配置
            version_manager: 版本管理器
        """
        self.config = config or PathConfig()
        self.version_manager = version_manager or VersionManager()
        self.validator = PathValidator(self.config, self.version_manager)
        
        # 注册所有路径到版本管理器
        self._register_paths_to_version_manager()
    
    def _register_paths_to_version_manager(self):
        """将所有路径注册到版本管理器"""
        all_paths = self.config.get_all_paths()
        for category, actions in all_paths.items():
            for action, path_def in actions.items():
                try:
                    version = APIVersion(path_def.metadata.version)
                    formatted_path = path_def.format()
                    self.version_manager.register_endpoint(version, formatted_path)
                except ValueError:
                    # 忽略无效版本
                    pass
    
    def build_path(self, category: str, action: str = None, **kwargs) -> str:
        """
        构建API路径
        
        Args:
            category: 路径类别
            action: 路径动作（可选，如果为None则使用默认动作）
            **kwargs: 路径参数
            
        Returns:
            str: 构建的API路径
            
        Raises:
            ValueError: 如果路径不存在或参数无效
        """
        # 如果没有指定action，使用默认动作
        if action is None:
            actions = self.config.get_actions_for_category(category)
            if not actions:
                raise ValueError(f"类别 '{category}' 没有任何动作")
            action = actions[0]  # 使用第一个动作作为默认
        
        # 获取路径定义
        path_def = self.config.get_path(category, action)
        if not path_def:
            raise ValueError(f"路径不存在: {category}.{action}")
        
        # 验证路径参数
        validation_result = self.validator.validate_path_parameters(path_def.path, kwargs)
        if not validation_result.is_valid:
            error_msg = "; ".join(validation_result.errors)
            raise ValueError(f"路径参数验证失败: {error_msg}")
        
        # 格式化路径
        formatted_path = path_def.format(**kwargs)
        
        # 标准化路径
        normalized_path = self.validator.normalize_path(formatted_path)
        
        return normalized_path
    
    def get_path_definition(self, category: str, action: str) -> Optional[PathDefinition]:
        """
        获取路径定义
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            Optional[PathDefinition]: 路径定义，如果不存在则返回None
        """
        return self.config.get_path(category, action)
    
    def validate_path(self, category: str, action: str, **kwargs) -> ValidationResult:
        """
        验证路径
        
        Args:
            category: 路径类别
            action: 路径动作
            **kwargs: 路径参数
            
        Returns:
            ValidationResult: 验证结果
        """
        return self.validator.validate_formatted_path(category, action, **kwargs)
    
    def normalize_path(self, path: str) -> str:
        """
        标准化路径
        
        Args:
            path: 要标准化的路径
            
        Returns:
            str: 标准化后的路径
        """
        return self.validator.normalize_path(path)
    
    def get_categories(self) -> List[str]:
        """获取所有路径类别"""
        return self.config.get_categories()
    
    def get_actions_for_category(self, category: str) -> List[str]:
        """
        获取指定类别的所有动作
        
        Args:
            category: 路径类别
            
        Returns:
            List[str]: 动作列表
        """
        return self.config.get_actions_for_category(category)
    
    def get_path_metadata(self, category: str, action: str) -> Optional[PathMetadata]:
        """
        获取路径元数据
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            Optional[PathMetadata]: 路径元数据，如果不存在则返回None
        """
        path_def = self.config.get_path(category, action)
        return path_def.metadata if path_def else None
    
    def is_auth_required(self, category: str, action: str) -> bool:
        """
        检查路径是否需要认证
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            bool: 是否需要认证
        """
        metadata = self.get_path_metadata(category, action)
        return metadata.auth_required if metadata else True
    
    def get_allowed_methods(self, category: str, action: str) -> List[str]:
        """
        获取路径允许的HTTP方法
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            List[str]: 允许的HTTP方法列表
        """
        metadata = self.get_path_metadata(category, action)
        return metadata.methods if metadata else ["GET"]
    
    def is_deprecated(self, category: str, action: str) -> bool:
        """
        检查路径是否已弃用
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            bool: 是否已弃用
        """
        metadata = self.get_path_metadata(category, action)
        return metadata.deprecated if metadata else False
    
    def get_deprecation_message(self, category: str, action: str) -> str:
        """
        获取路径的弃用消息
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            str: 弃用消息
        """
        metadata = self.get_path_metadata(category, action)
        return metadata.deprecation_message if metadata else ""
    
    def get_path_version(self, category: str, action: str) -> str:
        """
        获取路径的版本
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            str: 路径版本
        """
        metadata = self.get_path_metadata(category, action)
        return metadata.version if metadata else "v1"
    
    def get_path_parameters(self, category: str, action: str) -> Dict[str, Any]:
        """
        获取路径参数定义
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            Dict[str, Any]: 参数定义字典
        """
        metadata = self.get_path_metadata(category, action)
        return metadata.parameters if metadata else {}
    
    def get_response_schema(self, category: str, action: str) -> Optional[str]:
        """
        获取路径的响应模式
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            Optional[str]: 响应模式
        """
        metadata = self.get_path_metadata(category, action)
        return metadata.response_schema if metadata else None
    
    def get_request_schema(self, category: str, action: str) -> Optional[str]:
        """
        获取路径的请求模式
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            Optional[str]: 请求模式
        """
        metadata = self.get_path_metadata(category, action)
        return metadata.request_schema if metadata else None
    
    def add_path(self, category: str, action: str, path: str, 
                 metadata: PathMetadata = None) -> None:
        """
        添加路径定义
        
        Args:
            category: 路径类别
            action: 路径动作
            path: 路径模板
            metadata: 路径元数据
        """
        self.config.add_path(category, action, path, metadata)
        
        # 注册到版本管理器
        if metadata:
            try:
                version = APIVersion(metadata.version)
                self.version_manager.register_endpoint(version, path)
            except ValueError:
                # 忽略无效版本
                pass
    
    def update_path(self, category: str, action: str, path: str = None,
                   metadata: PathMetadata = None) -> bool:
        """
        更新路径定义
        
        Args:
            category: 路径类别
            action: 路径动作
            path: 新的路径模板（可选）
            metadata: 新的路径元数据（可选）
            
        Returns:
            bool: 更新是否成功
        """
        success = self.config.update_path(category, action, path, metadata)
        
        if success:
            # 重新注册到版本管理器
            path_def = self.config.get_path(category, action)
            if path_def and path_def.metadata:
                try:
                    version = APIVersion(path_def.metadata.version)
                    formatted_path = path_def.format()
                    self.version_manager.register_endpoint(version, formatted_path)
                except ValueError:
                    # 忽略无效版本
                    pass
        
        return success
    
    def remove_path(self, category: str, action: str) -> bool:
        """
        移除路径定义
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            bool: 移除是否成功
        """
        # 从版本管理器中移除
        path_def = self.config.get_path(category, action)
        if path_def and path_def.metadata:
            try:
                version = APIVersion(path_def.metadata.version)
                formatted_path = path_def.format()
                endpoints = self.version_manager.get_endpoints_for_version(version)
                if formatted_path in endpoints:
                    endpoints.remove(formatted_path)
            except ValueError:
                # 忽略无效版本
                pass
        
        return self.config.remove_path(category, action)
    
    def set_current_version(self, version: Union[APIVersion, str]) -> None:
        """
        设置当前API版本
        
        Args:
            version: API版本
            
        Raises:
            ValueError: 如果版本不被支持
        """
        if isinstance(version, str):
            try:
                version = APIVersion(version)
            except ValueError:
                raise ValueError(f"无效的API版本: {version}")
        
        self.version_manager.set_current_version(version)
    
    def get_current_version(self) -> APIVersion:
        """获取当前API版本"""
        return self.version_manager.get_current_version()
    
    def get_supported_versions(self) -> List[APIVersion]:
        """获取所有支持的API版本"""
        return self.version_manager.get_supported_versions()
    
    def get_deprecated_versions(self) -> List[APIVersion]:
        """获取所有已弃用的API版本"""
        return self.version_manager.get_deprecated_versions()
    
    def validate_all_paths(self) -> Dict[str, Dict[str, ValidationResult]]:
        """验证所有路径定义"""
        return self.validator.validate_all_paths()
    
    def get_validation_summary(self) -> Dict[str, Any]:
        """获取验证摘要"""
        return self.validator.get_validation_summary()
    
    def export_config(self) -> Dict[str, Any]:
        """导出路径配置"""
        return self.config.export_to_dict()
    
    def import_config(self, config_data: Dict[str, Any]) -> None:
        """导入路径配置"""
        self.config.import_from_dict(config_data)
        # 重新注册所有路径到版本管理器
        self._register_paths_to_version_manager()
    
    def find_paths_by_method(self, method: str) -> List[Tuple[str, str]]:
        """
        根据HTTP方法查找路径
        
        Args:
            method: HTTP方法
            
        Returns:
            List[Tuple[str, str]]: 匹配的路径列表，每个元素为(类别, 动作)元组
        """
        result = []
        for category in self.config.get_categories():
            for action in self.config.get_actions_for_category(category):
                allowed_methods = self.get_allowed_methods(category, action)
                if method in allowed_methods:
                    result.append((category, action))
        return result
    
    def find_paths_by_version(self, version: Union[APIVersion, str]) -> List[Tuple[str, str]]:
        """
        根据版本查找路径
        
        Args:
            version: API版本
            
        Returns:
            List[Tuple[str, str]]: 匹配的路径列表，每个元素为(类别, 动作)元组
        """
        if isinstance(version, str):
            try:
                version = APIVersion(version)
            except ValueError:
                return []
        
        result = []
        for category in self.config.get_categories():
            for action in self.config.get_actions_for_category(category):
                path_version = self.get_path_version(category, action)
                try:
                    path_version_enum = APIVersion(path_version)
                    if path_version_enum == version:
                        result.append((category, action))
                except ValueError:
                    # 忽略无效版本
                    pass
        return result
    
    def find_paths_by_auth_requirement(self, auth_required: bool) -> List[Tuple[str, str]]:
        """
        根据认证要求查找路径
        
        Args:
            auth_required: 是否需要认证
            
        Returns:
            List[Tuple[str, str]]: 匹配的路径列表，每个元素为(类别, 动作)元组
        """
        result = []
        for category in self.config.get_categories():
            for action in self.config.get_actions_for_category(category):
                if self.is_auth_required(category, action) == auth_required:
                    result.append((category, action))
        return result