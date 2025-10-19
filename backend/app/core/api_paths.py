"""
API路径常量定义
统一管理所有API路径，确保前后端一致
"""

class APIPaths:
    """API路径常量类"""
    
    # 基础路径
    BASE = "/api/v1"
    
    # 认证相关
    AUTH = {
        "LOGIN": "/auth/login",
        "LOGOUT": "/auth/logout",
        "REFRESH": "/auth/refresh",
        "REGISTER": "/auth/register",
        "VERIFY_EMAIL": "/auth/verify-email",
        "RESET_PASSWORD": "/auth/reset-password",
        "CHANGE_PASSWORD": "/auth/change-password",
        "ME": "/auth/me"
    }
    
    # 用户管理
    USERS = {
        "LIST": "/users",
        "CREATE": "/users",
        "GET": "/users/{user_id}",
        "UPDATE": "/users/{user_id}",
        "DELETE": "/users/{user_id}",
        "LOCK": "/users/{user_id}/lock",
        "UNLOCK": "/users/{user_id}/unlock",
        "PROFILE": "/users/me/profile",
        "AVATAR": "/users/me/avatar"
    }
    
    # 角色和权限管理
    ROLES = {
        "LIST": "/roles",
        "CREATE": "/roles",
        "GET": "/roles/{role_id}",
        "UPDATE": "/roles/{role_id}",
        "DELETE": "/roles/{role_id}",
        "PERMISSIONS": "/roles/{role_id}/permissions"
    }
    
    PERMISSIONS = {
        "LIST": "/permissions",
        "CREATE": "/permissions",
        "GET": "/permissions/{permission_id}",
        "UPDATE": "/permissions/{permission_id}",
        "DELETE": "/permissions/{permission_id}"
    }
    
    # WireGuard管理
    WIREGUARD = {
        "SERVERS": {
            "LIST": "/wireguard/servers",
            "CREATE": "/wireguard/servers",
            "GET": "/wireguard/servers/{server_id}",
            "UPDATE": "/wireguard/servers/{server_id}",
            "DELETE": "/wireguard/servers/{server_id}",
            "STATUS": "/wireguard/servers/{server_id}/status",
            "START": "/wireguard/servers/{server_id}/start",
            "STOP": "/wireguard/servers/{server_id}/stop",
            "RESTART": "/wireguard/servers/{server_id}/restart",
            "CONFIG": "/wireguard/servers/{server_id}/config",
            "PEERS": "/wireguard/servers/{server_id}/peers"
        },
        "CLIENTS": {
            "LIST": "/wireguard/clients",
            "CREATE": "/wireguard/clients",
            "GET": "/wireguard/clients/{client_id}",
            "UPDATE": "/wireguard/clients/{client_id}",
            "DELETE": "/wireguard/clients/{client_id}",
            "CONFIG": "/wireguard/clients/{client_id}/config",
            "QR_CODE": "/wireguard/clients/{client_id}/qr-code",
            "ENABLE": "/wireguard/clients/{client_id}/enable",
            "DISABLE": "/wireguard/clients/{client_id}/disable"
        }
    }
    
    # BGP管理
    BGP = {
        "SESSIONS": {
            "LIST": "/bgp/sessions",
            "CREATE": "/bgp/sessions",
            "GET": "/bgp/sessions/{session_id}",
            "UPDATE": "/bgp/sessions/{session_id}",
            "DELETE": "/bgp/sessions/{session_id}",
            "STATUS": "/bgp/sessions/{session_id}/status",
            "START": "/bgp/sessions/{session_id}/start",
            "STOP": "/bgp/sessions/{session_id}/stop",
            "ROUTES": "/bgp/sessions/{session_id}/routes"
        },
        "ROUTES": {
            "LIST": "/bgp/routes",
            "CREATE": "/bgp/routes",
            "GET": "/bgp/routes/{route_id}",
            "UPDATE": "/bgp/routes/{route_id}",
            "DELETE": "/bgp/routes/{route_id}"
        }
    }
    
    # IPv6管理
    IPV6 = {
        "POOLS": {
            "LIST": "/ipv6/pools",
            "CREATE": "/ipv6/pools",
            "GET": "/ipv6/pools/{pool_id}",
            "UPDATE": "/ipv6/pools/{pool_id}",
            "DELETE": "/ipv6/pools/{pool_id}",
            "ALLOCATE": "/ipv6/pools/{pool_id}/allocate",
            "RELEASE": "/ipv6/pools/{pool_id}/release"
        },
        "ADDRESSES": {
            "LIST": "/ipv6/addresses",
            "CREATE": "/ipv6/addresses",
            "GET": "/ipv6/addresses/{address_id}",
            "UPDATE": "/ipv6/addresses/{address_id}",
            "DELETE": "/ipv6/addresses/{address_id}"
        }
    }
    
    # 系统管理
    SYSTEM = {
        "INFO": "/system/info",
        "STATUS": "/system/status",
        "HEALTH": "/system/health",
        "METRICS": "/system/metrics",
        "CONFIG": "/system/config",
        "LOGS": "/system/logs",
        "BACKUP": "/system/backup",
        "RESTORE": "/system/restore"
    }
    
    # 监控
    MONITORING = {
        "DASHBOARD": "/monitoring/dashboard",
        "ALERTS": {
            "LIST": "/monitoring/alerts",
            "CREATE": "/monitoring/alerts",
            "GET": "/monitoring/alerts/{alert_id}",
            "UPDATE": "/monitoring/alerts/{alert_id}",
            "DELETE": "/monitoring/alerts/{alert_id}",
            "ACKNOWLEDGE": "/monitoring/alerts/{alert_id}/acknowledge"
        },
        "METRICS": {
            "LIST": "/monitoring/metrics",
            "GET": "/monitoring/metrics/{metric_id}"
        }
    }
    
    # 日志
    LOGS = {
        "LIST": "/logs",
        "GET": "/logs/{log_id}",
        "SEARCH": "/logs/search",
        "EXPORT": "/logs/export",
        "CLEANUP": "/logs/cleanup"
    }
    
    # 网络工具
    NETWORK = {
        "PING": "/network/ping",
        "TRACEROUTE": "/network/traceroute",
        "NSLOOKUP": "/network/nslookup",
        "WHOIS": "/network/whois"
    }
    
    # 审计日志
    AUDIT = {
        "LIST": "/audit",
        "GET": "/audit/{audit_id}",
        "SEARCH": "/audit/search",
        "EXPORT": "/audit/export"
    }
    
    # 文件上传
    UPLOAD = {
        "FILE": "/upload/file",
        "IMAGE": "/upload/image",
        "AVATAR": "/upload/avatar"
    }
    
    # WebSocket
    WEBSOCKET = {
        "NOTIFICATIONS": "/ws/notifications",
        "LOGS": "/ws/logs",
        "METRICS": "/ws/metrics"
    }
    
    @classmethod
    def get_full_path(cls, path: str) -> str:
        """获取完整路径"""
        return f"{cls.BASE}{path}"
    
    @classmethod
    def get_auth_path(cls, action: str) -> str:
        """获取认证路径"""
        return cls.get_full_path(cls.AUTH.get(action, ""))
    
    @classmethod
    def get_users_path(cls, action: str) -> str:
        """获取用户管理路径"""
        return cls.get_full_path(cls.USERS.get(action, ""))
    
    @classmethod
    def get_wireguard_servers_path(cls, action: str) -> str:
        """获取WireGuard服务器路径"""
        return cls.get_full_path(cls.WIREGUARD["SERVERS"].get(action, ""))
    
    @classmethod
    def get_wireguard_clients_path(cls, action: str) -> str:
        """获取WireGuard客户端路径"""
        return cls.get_full_path(cls.WIREGUARD["CLIENTS"].get(action, ""))
    
    @classmethod
    def get_bgp_sessions_path(cls, action: str) -> str:
        """获取BGP会话路径"""
        return cls.get_full_path(cls.BGP["SESSIONS"].get(action, ""))
    
    @classmethod
    def get_bgp_routes_path(cls, action: str) -> str:
        """获取BGP路由路径"""
        return cls.get_full_path(cls.BGP["ROUTES"].get(action, ""))
    
    @classmethod
    def get_ipv6_pools_path(cls, action: str) -> str:
        """获取IPv6地址池路径"""
        return cls.get_full_path(cls.IPV6["POOLS"].get(action, ""))
    
    @classmethod
    def get_ipv6_addresses_path(cls, action: str) -> str:
        """获取IPv6地址路径"""
        return cls.get_full_path(cls.IPV6["ADDRESSES"].get(action, ""))
    
    @classmethod
    def get_system_path(cls, action: str) -> str:
        """获取系统管理路径"""
        return cls.get_full_path(cls.SYSTEM.get(action, ""))
    
    @classmethod
    def get_monitoring_path(cls, action: str, sub_action: str = None) -> str:
        """获取监控路径"""
        if sub_action and action in ["ALERTS", "METRICS"]:
            return cls.get_full_path(cls.MONITORING[action.lower()].get(sub_action, ""))
        return cls.get_full_path(cls.MONITORING.get(action.lower(), ""))
    
    @classmethod
    def get_logs_path(cls, action: str) -> str:
        """获取日志路径"""
        return cls.get_full_path(cls.LOGS.get(action, ""))
    
    @classmethod
    def get_network_path(cls, action: str) -> str:
        """获取网络工具路径"""
        return cls.get_full_path(cls.NETWORK.get(action, ""))
    
    @classmethod
    def get_audit_path(cls, action: str) -> str:
        """获取审计日志路径"""
        return cls.get_full_path(cls.AUDIT.get(action, ""))
    
    @classmethod
    def get_upload_path(cls, action: str) -> str:
        """获取文件上传路径"""
        return cls.get_full_path(cls.UPLOAD.get(action, ""))
    
    @classmethod
    def get_websocket_path(cls, action: str) -> str:
        """获取WebSocket路径"""
        return cls.get_full_path(cls.WEBSOCKET.get(action, ""))

# 导出主要组件
__all__ = ["APIPaths"]