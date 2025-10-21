"""
统一API路径构建器
使用JSON配置文件，支持前后端一致性
"""

import json
import os
from typing import Dict, Any, Optional, List
from pathlib import Path


class UnifiedAPIPathBuilder:
    """统一的API路径构建器"""
    
    def __init__(self, config_path: str = None):
        """
        初始化统一API路径构建器
        
        Args:
            config_path: API路径配置文件路径
        """
        if config_path is None:
            # 默认配置文件路径
            try:
                current_dir = Path(__file__).parent.parent.parent.parent
            except NameError:
                # 如果__file__未定义，使用当前工作目录
                current_dir = Path.cwd()
            config_path = current_dir / "config" / "api_paths.json"
        
        self.config_path = Path(config_path)
        self.config = self._load_config()
        self.base_url = self.config["api"]["base_url"]
        self.version = self.config["api"]["version"]
        self.timeout = self.config["api"]["timeout"]
    
    def _load_config(self) -> Dict[str, Any]:
        """加载API路径配置"""
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"API路径配置文件不存在: {self.config_path}")
        except json.JSONDecodeError as e:
            raise ValueError(f"API路径配置文件格式错误: {e}")
    
    def get_endpoint(self, category: str, action: str) -> Dict[str, Any]:
        """
        获取API端点信息
        
        Args:
            category: 端点类别 (如: auth, users, wireguard)
            action: 端点动作 (如: login, list, create)
            
        Returns:
            端点信息字典
        """
        if category not in self.config["endpoints"]:
            raise ValueError(f"未知的端点类别: {category}")
        
        if action not in self.config["endpoints"][category]:
            raise ValueError(f"未知的端点动作: {category}.{action}")
        
        return self.config["endpoints"][category][action]
    
    def build_url(self, category: str, action: str, **kwargs) -> str:
        """
        构建完整的API URL
        
        Args:
            category: 端点类别
            action: 端点动作
            **kwargs: URL参数
            
        Returns:
            完整的API URL
        """
        endpoint = self.get_endpoint(category, action)
        path = endpoint["path"]
        
        # 替换路径参数
        for key, value in kwargs.items():
            path = path.replace(f"{{{key}}}", str(value))
        
        # 构建完整URL
        full_url = f"{self.base_url}/api/{self.version}{path}"
        return full_url
    
    def get_method(self, category: str, action: str) -> str:
        """
        获取HTTP方法
        
        Args:
            category: 端点类别
            action: 端点动作
            
        Returns:
            HTTP方法
        """
        endpoint = self.get_endpoint(category, action)
        return endpoint["method"]
    
    def get_description(self, category: str, action: str) -> str:
        """
        获取端点描述
        
        Args:
            category: 端点类别
            action: 端点动作
            
        Returns:
            端点描述
        """
        endpoint = self.get_endpoint(category, action)
        return endpoint["description"]
    
    def list_endpoints(self, category: str = None) -> Dict[str, Any]:
        """
        列出所有端点
        
        Args:
            category: 指定类别，None表示所有类别
            
        Returns:
            端点列表
        """
        if category:
            if category not in self.config["endpoints"]:
                raise ValueError(f"未知的端点类别: {category}")
            return {category: self.config["endpoints"][category]}
        else:
            return self.config["endpoints"]
    
    def validate_endpoint(self, category: str, action: str) -> bool:
        """
        验证端点是否存在
        
        Args:
            category: 端点类别
            action: 端点动作
            
        Returns:
            是否存在
        """
        try:
            self.get_endpoint(category, action)
            return True
        except ValueError:
            return False
    
    def get_all_categories(self) -> List[str]:
        """获取所有端点类别"""
        return list(self.config["endpoints"].keys())
    
    def get_category_actions(self, category: str) -> List[str]:
        """
        获取指定类别的所有动作
        
        Args:
            category: 端点类别
            
        Returns:
            动作列表
        """
        if category not in self.config["endpoints"]:
            raise ValueError(f"未知的端点类别: {category}")
        
        return list(self.config["endpoints"][category].keys())
    
    def export_config(self, output_path: str = None) -> str:
        """
        导出配置到文件
        
        Args:
            output_path: 输出文件路径
            
        Returns:
            导出的文件路径
        """
        if output_path is None:
            output_path = self.config_path
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, indent=2, ensure_ascii=False)
        
        return output_path


# 创建全局实例
api_path_builder = UnifiedAPIPathBuilder()


def get_api_path_builder() -> UnifiedAPIPathBuilder:
    """获取API路径构建器实例"""
    return api_path_builder


def build_api_url(category: str, action: str, **kwargs) -> str:
    """
    便捷函数：构建API URL
    
    Args:
        category: 端点类别
        action: 端点动作
        **kwargs: URL参数
        
    Returns:
        完整的API URL
    """
    return api_path_builder.build_url(category, action, **kwargs)


def get_api_method(category: str, action: str) -> str:
    """
    便捷函数：获取HTTP方法
    
    Args:
        category: 端点类别
        action: 端点动作
        
    Returns:
        HTTP方法
    """
    return api_path_builder.get_method(category, action)
