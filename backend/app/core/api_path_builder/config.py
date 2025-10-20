"""
API路径配置管理器
负责管理所有API路径的配置，包括路径定义、参数和元数据
"""

from typing import Dict, Any, Optional, List, Union
from dataclasses import dataclass, field
import json


@dataclass
class PathMetadata:
    """路径元数据"""
    description: str = ""
    auth_required: bool = True
    methods: List[str] = field(default_factory=lambda: ["GET"])
    deprecated: bool = False
    deprecation_message: str = ""
    version: str = "v1"
    parameters: Dict[str, Any] = field(default_factory=dict)
    response_schema: Optional[str] = None
    request_schema: Optional[str] = None


@dataclass
class PathDefinition:
    """路径定义"""
    path: str
    metadata: PathMetadata = field(default_factory=PathMetadata)
    
    def format(self, **kwargs) -> str:
        """
        格式化路径，替换参数
        
        Args:
            **kwargs: 路径参数
            
        Returns:
            str: 格式化后的路径
        """
        formatted_path = self.path
        for key, value in kwargs.items():
            placeholder = "{" + key + "}"
            formatted_path = formatted_path.replace(placeholder, str(value))
        return formatted_path


class PathConfig:
    """路径配置管理器"""
    
    def __init__(self):
        """初始化路径配置管理器"""
        self.paths: Dict[str, Dict[str, PathDefinition]] = {}
        self._initialize_default_paths()
    
    def _initialize_default_paths(self):
        """初始化默认路径配置"""
        # 认证相关路径
        self.add_path("auth", "login", "/auth/login", 
                     metadata=PathMetadata(
                         description="用户登录",
                         methods=["POST"],
                         auth_required=False
                     ))
        self.add_path("auth", "logout", "/auth/logout",
                     metadata=PathMetadata(
                         description="用户登出",
                         methods=["POST"]
                     ))
        self.add_path("auth", "refresh", "/auth/refresh",
                     metadata=PathMetadata(
                         description="刷新访问令牌",
                         methods=["POST"]
                     ))
        self.add_path("auth", "me", "/auth/me",
                     metadata=PathMetadata(
                         description="获取当前用户信息",
                         methods=["GET"]
                     ))
        
        # 用户管理路径
        self.add_path("users", "list", "/users",
                     metadata=PathMetadata(
                         description="获取用户列表",
                         methods=["GET"]
                     ))
        self.add_path("users", "detail", "/users/{user_id}",
                     metadata=PathMetadata(
                         description="获取用户详情",
                         methods=["GET"],
                         parameters={"user_id": "int"}
                     ))
        self.add_path("users", "update", "/users/{user_id}",
                     metadata=PathMetadata(
                         description="更新用户信息",
                         methods=["PUT"],
                         parameters={"user_id": "int"}
                     ))
        self.add_path("users", "delete", "/users/{user_id}",
                     metadata=PathMetadata(
                         description="删除用户",
                         methods=["DELETE"],
                         parameters={"user_id": "int"}
                     ))
        self.add_path("users", "lock", "/users/{user_id}/lock",
                     metadata=PathMetadata(
                         description="锁定用户",
                         methods=["POST"],
                         parameters={"user_id": "int"}
                     ))
        self.add_path("users", "unlock", "/users/{user_id}/unlock",
                     metadata=PathMetadata(
                         description="解锁用户",
                         methods=["POST"],
                         parameters={"user_id": "int"}
                     ))
        
        # WireGuard服务器路径
        self.add_path("wireguard", "servers", "/wireguard/servers",
                     metadata=PathMetadata(
                         description="获取WireGuard服务器列表",
                         methods=["GET"]
                     ))
        self.add_path("wireguard", "server_detail", "/wireguard/servers/{server_id}",
                     metadata=PathMetadata(
                         description="获取WireGuard服务器详情",
                         methods=["GET"],
                         parameters={"server_id": "int"}
                     ))
        self.add_path("wireguard", "server_status", "/wireguard/servers/{server_id}/status",
                     metadata=PathMetadata(
                         description="获取WireGuard服务器状态",
                         methods=["GET"],
                         parameters={"server_id": "int"}
                     ))
        self.add_path("wireguard", "create_server", "/wireguard/servers",
                     metadata=PathMetadata(
                         description="创建WireGuard服务器",
                         methods=["POST"]
                     ))
        self.add_path("wireguard", "update_server", "/wireguard/servers/{server_id}",
                     metadata=PathMetadata(
                         description="更新WireGuard服务器",
                         methods=["PUT"],
                         parameters={"server_id": "int"}
                     ))
        self.add_path("wireguard", "delete_server", "/wireguard/servers/{server_id}",
                     metadata=PathMetadata(
                         description="删除WireGuard服务器",
                         methods=["DELETE"],
                         parameters={"server_id": "int"}
                     ))
        
        # WireGuard客户端路径
        self.add_path("wireguard", "clients", "/wireguard/clients",
                     metadata=PathMetadata(
                         description="获取WireGuard客户端列表",
                         methods=["GET"]
                     ))
        self.add_path("wireguard", "client_detail", "/wireguard/clients/{client_id}",
                     metadata=PathMetadata(
                         description="获取WireGuard客户端详情",
                         methods=["GET"],
                         parameters={"client_id": "int"}
                     ))
        self.add_path("wireguard", "client_config", "/wireguard/clients/{client_id}/config",
                     metadata=PathMetadata(
                         description="获取WireGuard客户端配置",
                         methods=["GET"],
                         parameters={"client_id": "int"}
                     ))
        self.add_path("wireguard", "create_client", "/wireguard/clients",
                     metadata=PathMetadata(
                         description="创建WireGuard客户端",
                         methods=["POST"]
                     ))
        self.add_path("wireguard", "update_client", "/wireguard/clients/{client_id}",
                     metadata=PathMetadata(
                         description="更新WireGuard客户端",
                         methods=["PUT"],
                         parameters={"client_id": "int"}
                     ))
        self.add_path("wireguard", "delete_client", "/wireguard/clients/{client_id}",
                     metadata=PathMetadata(
                         description="删除WireGuard客户端",
                         methods=["DELETE"],
                         parameters={"client_id": "int"}
                     ))
        
        # BGP配置路径
        self.add_path("bgp", "config", "/bgp/config",
                     metadata=PathMetadata(
                         description="获取BGP配置",
                         methods=["GET"]
                     ))
        self.add_path("bgp", "update_config", "/bgp/config",
                     metadata=PathMetadata(
                         description="更新BGP配置",
                         methods=["PUT"]
                     ))
        
        # IPv6路由路径
        self.add_path("ipv6", "routes", "/ipv6/routes",
                     metadata=PathMetadata(
                         description="获取IPv6路由",
                         methods=["GET"]
                     ))
        self.add_path("ipv6", "add_route", "/ipv6/routes",
                     metadata=PathMetadata(
                         description="添加IPv6路由",
                         methods=["POST"]
                     ))
        self.add_path("ipv6", "delete_route", "/ipv6/routes/{route_id}",
                     metadata=PathMetadata(
                         description="删除IPv6路由",
                         methods=["DELETE"],
                         parameters={"route_id": "int"}
                     ))
        
        # 监控路径
        self.add_path("monitoring", "dashboard", "/monitoring/dashboard",
                     metadata=PathMetadata(
                         description="获取监控仪表板数据",
                         methods=["GET"]
                     ))
        self.add_path("monitoring", "alerts", "/monitoring/alerts",
                     metadata=PathMetadata(
                         description="获取告警列表",
                         methods=["GET"]
                     ))
        self.add_path("monitoring", "metrics", "/monitoring/metrics",
                     metadata=PathMetadata(
                         description="获取监控指标",
                         methods=["GET"]
                     ))
        
        # 系统路径
        self.add_path("system", "info", "/system/info",
                     metadata=PathMetadata(
                         description="获取系统信息",
                         methods=["GET"]
                     ))
        self.add_path("system", "status", "/system/status",
                     metadata=PathMetadata(
                         description="获取系统状态",
                         methods=["GET"]
                     ))
        
        # 日志路径
        self.add_path("logs", "list", "/logs",
                     metadata=PathMetadata(
                         description="获取日志列表",
                         methods=["GET"]
                     ))
        self.add_path("logs", "detail", "/logs/{log_id}",
                     metadata=PathMetadata(
                         description="获取单个日志",
                         methods=["GET"],
                         parameters={"log_id": "int"}
                     ))
        self.add_path("logs", "delete", "/logs/{log_id}",
                     metadata=PathMetadata(
                         description="删除日志",
                         methods=["DELETE"],
                         parameters={"log_id": "int"}
                     ))
        self.add_path("logs", "clear", "/logs/clear",
                     metadata=PathMetadata(
                         description="清空日志",
                         methods=["DELETE"]
                     ))
        self.add_path("logs", "health", "/logs/health",
                     metadata=PathMetadata(
                         description="日志健康检查",
                         methods=["GET"],
                         auth_required=False
                     ))
        self.add_path("logs", "search", "/logs/search",
                     metadata=PathMetadata(
                         description="搜索日志",
                         methods=["POST"]
                     ))
    
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
        if category not in self.paths:
            self.paths[category] = {}
        
        self.paths[category][action] = PathDefinition(
            path=path,
            metadata=metadata or PathMetadata()
        )
    
    def get_path(self, category: str, action: str) -> Optional[PathDefinition]:
        """
        获取路径定义
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            Optional[PathDefinition]: 路径定义，如果不存在则返回None
        """
        return self.paths.get(category, {}).get(action)
    
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
        if category not in self.paths or action not in self.paths[category]:
            return False
        
        path_def = self.paths[category][action]
        if path is not None:
            path_def.path = path
        if metadata is not None:
            path_def.metadata = metadata
        
        return True
    
    def remove_path(self, category: str, action: str) -> bool:
        """
        移除路径定义
        
        Args:
            category: 路径类别
            action: 路径动作
            
        Returns:
            bool: 移除是否成功
        """
        if category not in self.paths or action not in self.paths[category]:
            return False
        
        del self.paths[category][action]
        
        # 如果类别为空，也删除类别
        if not self.paths[category]:
            del self.paths[category]
        
        return True
    
    def get_categories(self) -> List[str]:
        """获取所有路径类别"""
        return list(self.paths.keys())
    
    def get_actions_for_category(self, category: str) -> List[str]:
        """
        获取指定类别的所有动作
        
        Args:
            category: 路径类别
            
        Returns:
            List[str]: 动作列表
        """
        return list(self.paths.get(category, {}).keys())
    
    def get_all_paths(self) -> Dict[str, Dict[str, PathDefinition]]:
        """获取所有路径定义"""
        return self.paths.copy()
    
    def export_to_dict(self) -> Dict[str, Any]:
        """将路径配置导出为字典"""
        result = {}
        for category, actions in self.paths.items():
            result[category] = {}
            for action, path_def in actions.items():
                result[category][action] = {
                    "path": path_def.path,
                    "metadata": {
                        "description": path_def.metadata.description,
                        "auth_required": path_def.metadata.auth_required,
                        "methods": path_def.metadata.methods,
                        "deprecated": path_def.metadata.deprecated,
                        "deprecation_message": path_def.metadata.deprecation_message,
                        "version": path_def.metadata.version,
                        "parameters": path_def.metadata.parameters,
                        "response_schema": path_def.metadata.response_schema,
                        "request_schema": path_def.metadata.request_schema
                    }
                }
        return result
    
    def import_from_dict(self, data: Dict[str, Any]) -> None:
        """
        从字典导入路径配置
        
        Args:
            data: 路径配置字典
        """
        self.paths = {}
        for category, actions in data.items():
            for action, config in actions.items():
                metadata = PathMetadata(**config["metadata"])
                self.add_path(category, action, config["path"], metadata)
    
    def export_to_json(self) -> str:
        """将路径配置导出为JSON字符串"""
        return json.dumps(self.export_to_dict(), indent=2, ensure_ascii=False)
    
    def import_from_json(self, json_str: str) -> None:
        """
        从JSON字符串导入路径配置
        
        Args:
            json_str: JSON字符串
        """
        data = json.loads(json_str)
        self.import_from_dict(data)