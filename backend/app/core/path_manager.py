"""
路径管理器实现
提供统一的API路径管理功能
"""

from typing import Dict, Any, Optional, List, Set, TYPE_CHECKING

if TYPE_CHECKING:
    from app.core.api_paths import APIPaths, APIVersion

# 使用延迟导入避免循环依赖
def get_api_paths():
    from app.core.api_paths import APIPaths
    return APIPaths

def get_api_version():
    from app.core.api_paths import APIVersion
    return APIVersion

from app.core.api_config import (
    get_api_path, get_auth_path, get_users_path, get_wireguard_path,
    get_bgp_path, get_ipv6_path, get_mfa_path, get_system_path,
    get_monitoring_path, get_logs_path
)


class PathManager:
    """统一的API路径管理器"""
    
    def __init__(self):
        # 使用延迟导入避免循环依赖
        APIPaths = get_api_paths()
        APIVersion = get_api_version()
        
        self.api_paths = APIPaths()
        self._current_version = APIVersion.V1
        self._supported_versions: Set[APIVersion] = {APIVersion.V1}
        self._deprecated_versions: Set[APIVersion] = set()
    
    @property
    def current_version(self) -> APIVersion:
        """获取当前API版本"""
        return self._current_version
    
    @property
    def supported_versions(self) -> List[APIVersion]:
        """获取支持的API版本列表"""
        return list(self._supported_versions)
    
    @property
    def deprecated_versions(self) -> List[APIVersion]:
        """获取已弃用的API版本列表"""
        return list(self._deprecated_versions)
    
    def add_version(self, version, is_deprecated: bool = False) -> None:
        """添加API版本"""
        # 使用延迟导入避免循环依赖
        APIVersion = get_api_version()
        
        self._supported_versions.add(version)
        if is_deprecated:
            self._deprecated_versions.add(version)
    
    def set_current_version(self, version) -> None:
        """设置当前API版本"""
        # 使用延迟导入避免循环依赖
        APIVersion = get_api_version()
        
        if version not in self._supported_versions:
            self.add_version(version)
        self._current_version = version
    
    def validate_path(self, path: str) -> Dict[str, Any]:
        """验证API路径格式"""
        import re
        
        result = {
            'valid': False,
            'version': None,
            'pattern': None,
            'errors': [],
            'suggestions': []
        }
        
        # 检查基本格式
        if not path.startswith('/api/v'):
            result['errors'].append("路径必须以 /api/v 开头")
            result['suggestions'].append("使用格式: /api/v1/resource")
            return result
        
        # 检查版本号
        version_match = re.match(r'^/api/v(\d+)/', path)
        if not version_match:
            result['errors'].append("版本号格式错误")
            result['suggestions'].append("使用格式: /api/v1/")
            return result
        
        version_num = int(version_match.group(1))
        if version_num < 1:
            result['errors'].append("版本号必须大于等于1")
            result['suggestions'].append("使用版本号: v1, v2, v3...")
            return result
        
        # 检查版本是否支持
        version_str = f"v{version_num}"
        try:
            # 使用延迟导入避免循环依赖
            APIVersion = get_api_version()
            version = APIVersion(version_str)
            result['version'] = version
            
            if version not in self._supported_versions:
                result['errors'].append(f"版本 {version_str} 不受支持")
                result['suggestions'].append(f"支持的版本: {[v.value for v in self._supported_versions]}")
                return result
            
            if version in self._deprecated_versions:
                result['warnings'] = [f"版本 {version_str} 已弃用，请升级到更新版本"]
            
        except ValueError:
            result['errors'].append(f"未知版本: {version_str}")
            result['suggestions'].append(f"支持的版本: {[v.value for v in self._supported_versions]}")
            return result
        
        # 检查路径模式
        path_patterns = {
            'resource': r'^/api/v\d+/[a-z][a-z0-9-]*$',
            'resource_id': r'^/api/v\d+/[a-z][a-z0-9-]*/\d+$',
            'nested_resource': r'^/api/v\d+/[a-z][a-z0-9-]*/\d+/[a-z][a-z0-9-]*$',
            'action': r'^/api/v\d+/[a-z][a-z0-9-]*/[a-z][a-z0-9-]*$'
        }
        
        for pattern_name, pattern in path_patterns.items():
            if re.match(pattern, path):
                result['valid'] = True
                result['pattern'] = pattern_name
                break
        
        if not result['valid']:
            result['errors'].append("路径格式不正确")
            result['suggestions'].append("使用RESTful路径格式，如: /api/v1/users/123")
        
        return result
    
    def normalize_path(self, path: str) -> str:
        """标准化路径格式"""
        import re
        
        # 使用延迟导入避免循环依赖
        APIVersion = get_api_version()
        
        # 移除多余的斜杠
        path = re.sub(r'/+', '/', path)
        
        # 确保以/api/v开头
        if not path.startswith('/api/v'):
            if path.startswith('/api/'):
                # 如果只有/api但没有版本，添加当前版本
                path = f"/api/{self._current_version.value}{path[5:]}"
            else:
                # 如果完全缺少API前缀，添加完整前缀
                path = f"/api/{self._current_version.value}{path}"
        
        # 移除末尾斜杠（除非是根路径）
        if path != f"/api/{self._current_version.value}/" and path.endswith('/'):
            path = path[:-1]
        
        return path
    
    def get_full_path(self, path: str) -> str:
        """获取完整路径"""
        return self.api_paths.get_full_path(path)
    
    def get_auth_path(self, action: str) -> str:
        """获取认证路径"""
        return self.api_paths.get_auth_path(action)
    
    def get_users_path(self, action: str) -> str:
        """获取用户管理路径"""
        return self.api_paths.get_users_path(action)
    
    def get_wireguard_servers_path(self, action: str) -> str:
        """获取WireGuard服务器路径"""
        return self.api_paths.get_wireguard_servers_path(action)
    
    def get_wireguard_clients_path(self, action: str) -> str:
        """获取WireGuard客户端路径"""
        return self.api_paths.get_wireguard_clients_path(action)
    
    def get_bgp_sessions_path(self, action: str) -> str:
        """获取BGP会话路径"""
        return self.api_paths.get_bgp_sessions_path(action)
    
    def get_bgp_routes_path(self, action: str) -> str:
        """获取BGP路由路径"""
        return self.api_paths.get_bgp_routes_path(action)
    
    def get_ipv6_pools_path(self, action: str) -> str:
        """获取IPv6地址池路径"""
        return self.api_paths.get_ipv6_pools_path(action)
    
    def get_ipv6_addresses_path(self, action: str) -> str:
        """获取IPv6地址路径"""
        return self.api_paths.get_ipv6_addresses_path(action)
    
    def get_system_path(self, action: str) -> str:
        """获取系统管理路径"""
        return self.api_paths.get_system_path(action)
    
    def get_monitoring_path(self, action: str, sub_action: str = None) -> str:
        """获取监控路径"""
        return self.api_paths.get_monitoring_path(action, sub_action)
    
    def get_logs_path(self, action: str) -> str:
        """获取日志路径"""
        return self.api_paths.get_logs_path(action)
    
    def get_network_path(self, action: str) -> str:
        """获取网络工具路径"""
        return self.api_paths.get_network_path(action)
    
    def get_audit_path(self, action: str) -> str:
        """获取审计日志路径"""
        return self.api_paths.get_audit_path(action)
    
    def get_upload_path(self, action: str) -> str:
        """获取文件上传路径"""
        return self.api_paths.get_upload_path(action)
    
    def get_websocket_path(self, action: str) -> str:
        """获取WebSocket路径"""
        return self.api_paths.get_websocket_path(action)
    
    # 使用api_config中的函数
    def build_api_path(self, *parts, version=None) -> str:
        """构建API路径"""
        return get_api_path(*parts, version=version)
    
    def build_auth_path(self, action: str, version=None) -> str:
        """构建认证路径"""
        return get_auth_path(action, version=version)
    
    def build_users_path(self, action: str = None, user_id: int = None, version=None) -> str:
        """构建用户管理路径"""
        return get_users_path(action, user_id, version=version)
    
    def build_wireguard_path(self, resource: str, action: str = None, resource_id: int = None, version=None) -> str:
        """构建WireGuard路径"""
        return get_wireguard_path(resource, action, resource_id, version=version)
    
    def build_bgp_path(self, resource: str, action: str = None, resource_id: int = None, version=None) -> str:
        """构建BGP路径"""
        return get_bgp_path(resource, action, resource_id, version=version)
    
    def build_ipv6_path(self, resource: str, action: str = None, resource_id: int = None, version=None) -> str:
        """构建IPv6路径"""
        return get_ipv6_path(resource, action, resource_id, version=version)
    
    def build_mfa_path(self, action: str, version=None) -> str:
        """构建MFA路径"""
        return get_mfa_path(action, version=version)
    
    def build_system_path(self, action: str, version=None) -> str:
        """构建系统路径"""
        return get_system_path(action, version=version)
    
    def build_monitoring_path(self, action: str, version=None) -> str:
        """构建监控路径"""
        return get_monitoring_path(action, version=version)
    
    def build_logs_path(self, action: str, version=None) -> str:
        """构建日志路径"""
        return get_logs_path(action, version=version)
    
    def get_all_paths(self) -> Dict[str, Any]:
        """获取所有路径定义"""
        return {
            "auth": self.api_paths.AUTH,
            "users": self.api_paths.USERS,
            "wireguard": self.api_paths.WIREGUARD,
            "bgp": self.api_paths.BGP,
            "ipv6": self.api_paths.IPV6,
            "system": self.api_paths.SYSTEM,
            "monitoring": self.api_paths.MONITORING,
            "logs": self.api_paths.LOGS,
            "network": self.api_paths.NETWORK,
            "audit": self.api_paths.AUDIT,
            "upload": self.api_paths.UPLOAD,
            "websocket": self.api_paths.WEBSOCKET
        }


# 创建全局路径管理器实例
path_manager = PathManager()

# 导出主要组件
__all__ = ["PathManager", "path_manager"]