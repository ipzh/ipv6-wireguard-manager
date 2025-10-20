"""
API路径标准化模块
统一管理API路径，确保前后端路径一致性
"""
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)

class APIPathManager:
    """API路径管理器"""
    
    def __init__(self):
        self.paths: Dict[str, Dict] = {}
        self.version = "v1"
        self.base_path = f"/api/{self.version}"
        
    def register_path(self, name: str, path: str, methods: List[str], 
                     description: str = "", parameters: List[str] = None):
        """注册API路径"""
        self.paths[name] = {
            "path": path,
            "methods": methods,
            "description": description,
            "parameters": parameters or []
        }
        logger.debug(f"注册API路径: {name} -> {path}")
    
    def get_path(self, name: str, params: Dict = None) -> str:
        """获取API路径"""
        if name not in self.paths:
            logger.warning(f"未找到API路径: {name}")
            return ""
        
        path_config = self.paths[name]
        path = self.base_path + path_config["path"]
        
        # 替换路径参数
        if params:
            for key, value in params.items():
                placeholder = f"{{{key}}}"
                if placeholder in path:
                    path = path.replace(placeholder, str(value))
        
        return path
    
    def validate_path(self, name: str, method: str = "GET") -> bool:
        """验证API路径和方法"""
        if name not in self.paths:
            return False
        
        path_config = self.paths[name]
        return method.upper() in [m.upper() for m in path_config["methods"]]
    
    def get_all_paths(self) -> Dict[str, Dict]:
        """获取所有API路径"""
        return self.paths.copy()
    
    def setup_default_paths(self):
        """设置默认API路径"""
        # 认证相关路径
        self.register_path("auth.login", "/auth/login", ["POST"], "用户登录")
        self.register_path("auth.logout", "/auth/logout", ["POST"], "用户登出")
        self.register_path("auth.refresh", "/auth/refresh", ["POST"], "刷新令牌")
        self.register_path("auth.register", "/auth/register", ["POST"], "用户注册")
        self.register_path("auth.me", "/auth/me", ["GET"], "获取当前用户信息")
        
        # 用户管理路径
        self.register_path("users.list", "/users", ["GET"], "获取用户列表")
        self.register_path("users.create", "/users", ["POST"], "创建用户")
        self.register_path("users.get", "/users/{user_id}", ["GET"], "获取用户详情", ["user_id"])
        self.register_path("users.update", "/users/{user_id}", ["PUT", "PATCH"], "更新用户", ["user_id"])
        self.register_path("users.delete", "/users/{user_id}", ["DELETE"], "删除用户", ["user_id"])
        
        # WireGuard管理路径
        self.register_path("wireguard.servers", "/wireguard/servers", ["GET", "POST"], "WireGuard服务器管理")
        self.register_path("wireguard.servers.get", "/wireguard/servers/{server_id}", ["GET"], "获取服务器详情", ["server_id"])
        self.register_path("wireguard.servers.update", "/wireguard/servers/{server_id}", ["PUT", "PATCH"], "更新服务器", ["server_id"])
        self.register_path("wireguard.servers.delete", "/wireguard/servers/{server_id}", ["DELETE"], "删除服务器", ["server_id"])
        
        self.register_path("wireguard.clients", "/wireguard/clients", ["GET", "POST"], "WireGuard客户端管理")
        self.register_path("wireguard.clients.get", "/wireguard/clients/{client_id}", ["GET"], "获取客户端详情", ["client_id"])
        self.register_path("wireguard.clients.update", "/wireguard/clients/{client_id}", ["PUT", "PATCH"], "更新客户端", ["client_id"])
        self.register_path("wireguard.clients.delete", "/wireguard/clients/{client_id}", ["DELETE"], "删除客户端", ["client_id"])
        
        # 系统管理路径
        self.register_path("system.info", "/system/info", ["GET"], "获取系统信息")
        self.register_path("system.status", "/system/status", ["GET"], "获取系统状态")
        self.register_path("system.health", "/system/health", ["GET"], "系统健康检查")
        
        # 监控路径
        self.register_path("monitoring.dashboard", "/monitoring/dashboard", ["GET"], "监控仪表板")
        self.register_path("monitoring.metrics", "/monitoring/metrics", ["GET"], "获取监控指标")
        
        # 日志路径
        self.register_path("logs.list", "/logs", ["GET"], "获取日志列表")
        self.register_path("logs.search", "/logs/search", ["POST"], "搜索日志")
        
        logger.info(f"✅ 已注册 {len(self.paths)} 个默认API路径")

# 创建全局路径管理器实例
path_manager = APIPathManager()
path_manager.setup_default_paths()

# 便捷函数
def get_api_path(name: str, params: Dict = None) -> str:
    """获取API路径"""
    return path_manager.get_path(name, params)

def get_auth_path(name: str, params: Dict = None) -> str:
    """获取认证相关API路径"""
    return path_manager.get_path(f"auth.{name}", params)

def get_users_path(name: str, params: Dict = None) -> str:
    """获取用户管理API路径"""
    return path_manager.get_path(f"users.{name}", params)

def get_wireguard_path(name: str, params: Dict = None) -> str:
    """获取WireGuard管理API路径"""
    return path_manager.get_path(f"wireguard.{name}", params)

def get_system_path(name: str, params: Dict = None) -> str:
    """获取系统管理API路径"""
    return path_manager.get_path(f"system.{name}", params)

def get_monitoring_path(name: str, params: Dict = None) -> str:
    """获取监控API路径"""
    return path_manager.get_path(f"monitoring.{name}", params)

def get_logs_path(name: str, params: Dict = None) -> str:
    """获取日志API路径"""
    return path_manager.get_path(f"logs.{name}", params)

def validate_api_path(name: str, method: str = "GET") -> bool:
    """验证API路径和方法"""
    return path_manager.validate_path(name, method)

def get_all_api_paths() -> Dict[str, Dict]:
    """获取所有API路径"""
    return path_manager.get_all_paths()
