"""
API路径验证器
负责验证API路径的有效性、格式和参数
"""

import re
from typing import Dict, List, Optional, Tuple, Any, Set
from dataclasses import dataclass
from .config import PathConfig, PathDefinition
from .version_manager import VersionManager, APIVersion


@dataclass
class ValidationResult:
    """验证结果"""
    is_valid: bool
    errors: List[str] = None
    warnings: List[str] = None
    
    def __post_init__(self):
        if self.errors is None:
            self.errors = []
        if self.warnings is None:
            self.warnings = []
    
    def add_error(self, error: str) -> None:
        """添加错误"""
        self.errors.append(error)
        self.is_valid = False
    
    def add_warning(self, warning: str) -> None:
        """添加警告"""
        self.warnings.append(warning)


class PathValidator:
    """路径验证器"""
    
    def __init__(self, config: PathConfig = None, version_manager: VersionManager = None):
        """
        初始化路径验证器
        
        Args:
            config: 路径配置
            version_manager: 版本管理器
        """
        self.config = config or PathConfig()
        self.version_manager = version_manager or VersionManager()
        
        # 路径参数的正则表达式模式
        self.param_pattern = re.compile(r'\{([^}]+)\}')
        
        # 有效的HTTP方法
        self.valid_methods = {"GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"}
        
        # 路径格式规则
        self.path_rules = [
            # 路径必须以/开头
            (re.compile(r'^/'), "路径必须以/开头"),
            # 路径不能以/结尾（除非是根路径/）
            (re.compile(r'^(?!/[^/]+/$)'), "路径不能以/结尾（除非是根路径/）"),
            # 路径不能包含连续的//
            (re.compile(r'^(?!.*//)'), "路径不能包含连续的//"),
            # 路径参数必须是有效的标识符
            (re.compile(r'^(?!.*\{[^a-zA-Z_][^}]*\})'), "路径参数必须以字母或下划线开头"),
            # 路径参数不能包含特殊字符
            (re.compile(r'^(?!.*\{[^}]*[^a-zA-Z0-9_][^}]*\})'), "路径参数只能包含字母、数字和下划线"),
        ]
    
    def validate_path_format(self, path: str) -> ValidationResult:
        """
        验证路径格式
        
        Args:
            path: 要验证的路径
            
        Returns:
            ValidationResult: 验证结果
        """
        result = ValidationResult(is_valid=True)
        
        # 检查路径是否为空
        if not path:
            result.add_error("路径不能为空")
            return result
        
        # 检查路径格式规则
        for pattern, message in self.path_rules:
            if not pattern.match(path):
                result.add_error(message)
        
        # 检查路径参数是否重复
        param_names = self.extract_path_parameters(path)
        if len(param_names) != len(set(param_names)):
            result.add_error("路径中存在重复的参数名")
        
        return result
    
    def validate_path_parameters(self, path: str, params: Dict[str, Any]) -> ValidationResult:
        """
        验证路径参数
        
        Args:
            path: 路径模板
            params: 参数值字典
            
        Returns:
            ValidationResult: 验证结果
        """
        result = ValidationResult(is_valid=True)
        
        # 提取路径中的参数
        required_params = set(self.extract_path_parameters(path))
        provided_params = set(params.keys())
        
        # 检查缺少的必需参数
        missing_params = required_params - provided_params
        for param in missing_params:
            result.add_error(f"缺少必需的参数: {param}")
        
        # 检查多余的参数
        extra_params = provided_params - required_params
        for param in extra_params:
            result.add_warning(f"提供了多余的参数: {param}")
        
        return result
    
    def validate_path_definition(self, category: str, action: str) -> ValidationResult:
        """
        验证路径定义
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            ValidationResult: 验证结果
        """
        result = ValidationResult(is_valid=True)
        
        # 检查路径定义是否存在
        path_def = self.config.get_path(category, action)
        if not path_def:
            result.add_error(f"路径定义不存在: {category}.{action}")
            return result
        
        # 验证路径格式
        format_result = self.validate_path_format(path_def.path)
        if not format_result.is_valid:
            result.is_valid = False
            result.errors.extend(format_result.errors)
        
        # 验证元数据
        metadata = path_def.metadata
        
        # 检查HTTP方法是否有效
        for method in metadata.methods:
            if method not in self.valid_methods:
                result.add_error(f"无效的HTTP方法: {method}")
        
        # 检查版本是否有效
        try:
            APIVersion(metadata.version)
        except ValueError:
            result.add_error(f"无效的API版本: {metadata.version}")
        
        # 检查参数定义是否与路径参数匹配
        path_params = set(self.extract_path_parameters(path_def.path))
        metadata_params = set(metadata.parameters.keys())
        
        # 检查元数据中是否定义了路径中不存在的参数
        extra_metadata_params = metadata_params - path_params
        for param in extra_metadata_params:
            result.add_warning(f"元数据中定义了路径中不存在的参数: {param}")
        
        # 检查路径参数是否在元数据中有定义
        missing_metadata_params = path_params - metadata_params
        for param in missing_metadata_params:
            result.add_warning(f"路径参数在元数据中未定义: {param}")
        
        return result
    
    def validate_formatted_path(self, category: str, action: str, **kwargs) -> ValidationResult:
        """
        验证格式化后的路径
        
        Args:
            category: 路径类别
            action: 路径动作
            **kwargs: 路径参数
            
        Returns:
            ValidationResult: 验证结果
        """
        result = ValidationResult(is_valid=True)
        
        # 验证路径定义
        definition_result = self.validate_path_definition(category, action)
        if not definition_result.is_valid:
            result.is_valid = False
            result.errors.extend(definition_result.errors)
        
        # 获取路径定义
        path_def = self.config.get_path(category, action)
        if not path_def:
            return result
        
        # 验证路径参数
        param_result = self.validate_path_parameters(path_def.path, kwargs)
        if not param_result.is_valid:
            result.is_valid = False
            result.errors.extend(param_result.errors)
        
        # 格式化路径
        formatted_path = path_def.format(**kwargs)
        
        # 验证格式化后的路径
        format_result = self.validate_path_format(formatted_path)
        if not format_result.is_valid:
            result.is_valid = False
            result.errors.extend(format_result.errors)
        
        return result
    
    def validate_path_for_version(self, category: str, action: str, 
                                 version: APIVersion = None) -> ValidationResult:
        """
        验证路径是否适用于指定版本
        
        Args:
            category: 路径类别
            action: 路径动作
            version: API版本
            
        Returns:
            ValidationResult: 验证结果
        """
        result = ValidationResult(is_valid=True)
        
        # 使用当前版本（如果未指定）
        if version is None:
            version = self.version_manager.get_current_version()
        
        # 检查版本是否被支持
        if not self.version_manager.is_version_supported(version):
            result.add_error(f"版本 {version.value} 不被支持")
            return result
        
        # 获取路径定义
        path_def = self.config.get_path(category, action)
        if not path_def:
            result.add_error(f"路径定义不存在: {category}.{action}")
            return result
        
        # 检查路径是否适用于指定版本
        try:
            path_version = APIVersion(path_def.metadata.version)
            if not self.version_manager.is_version_supported(path_version):
                result.add_error(f"路径版本 {path_version.value} 不被支持")
            elif version.value < path_version.value:
                result.add_error(f"路径版本 {path_version.value} 高于请求版本 {version.value}")
        except ValueError:
            result.add_error(f"无效的路径版本: {path_def.metadata.version}")
        
        return result
    
    def extract_path_parameters(self, path: str) -> List[str]:
        """
        提取路径中的参数
        
        Args:
            path: 路径模板
            
        Returns:
            List[str]: 参数名列表
        """
        return self.param_pattern.findall(path)
    
    def normalize_path(self, path: str) -> str:
        """
        标准化路径
        
        Args:
            path: 要标准化的路径
            
        Returns:
            str: 标准化后的路径
        """
        # 移除开头的空格
        path = path.strip()
        
        # 确保以/开头
        if not path.startswith('/'):
            path = '/' + path
        
        # 移除末尾的/（除非是根路径）
        if len(path) > 1 and path.endswith('/'):
            path = path[:-1]
        
        # 将连续的/替换为单个/
        path = re.sub(r'/+', '/', path)
        
        return path
    
    def validate_all_paths(self) -> Dict[str, Dict[str, ValidationResult]]:
        """
        验证所有路径定义
        
        Returns:
            Dict[str, Dict[str, ValidationResult]]: 验证结果字典
        """
        results = {}
        
        for category in self.config.get_categories():
            results[category] = {}
            for action in self.config.get_actions_for_category(category):
                results[category][action] = self.validate_path_definition(category, action)
        
        return results
    
    def get_validation_summary(self) -> Dict[str, Any]:
        """
        获取验证摘要
        
        Returns:
            Dict[str, Any]: 验证摘要
        """
        all_results = self.validate_all_paths()
        
        total_paths = 0
        valid_paths = 0
        total_errors = 0
        total_warnings = 0
        
        for category, actions in all_results.items():
            for action, result in actions.items():
                total_paths += 1
                if result.is_valid:
                    valid_paths += 1
                total_errors += len(result.errors)
                total_warnings += len(result.warnings)
        
        return {
            "total_paths": total_paths,
            "valid_paths": valid_paths,
            "invalid_paths": total_paths - valid_paths,
            "total_errors": total_errors,
            "total_warnings": total_warnings,
            "success_rate": valid_paths / total_paths if total_paths > 0 else 0
        }