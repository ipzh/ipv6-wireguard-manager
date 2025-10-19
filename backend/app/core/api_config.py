"""
API路径配置模块
定义所有API路径常量和配置
"""

from app.core.api_paths import APIVersion

# API基础配置
API_BASE_PATH = "/api"
API_CURRENT_VERSION = APIVersion.V1

# 路径常量 - 使用下划线命名
API_AUTH = "/auth"
API_USERS = "/users"
API_ROLES = "/roles"
API_PERMISSIONS = "/permissions"
API_WIREGUARD = "/wireguard"
API_BGP = "/bgp"
API_IPV6 = "/ipv6"
API_SYSTEM = "/system"
API_MONITORING = "/monitoring"
API_LOGS = "/logs"
API_NETWORK = "/network"
API_AUDIT = "/audit"
API_UPLOAD = "/upload"
API_MFA = "/mfa"

# 认证相关路径
AUTH_LOGIN = "/login"
AUTH_LOGOUT = "/logout"
AUTH_REFRESH = "/refresh"
AUTH_ME = "/me"
AUTH_VERIFY = "/verify-token"
AUTH_REGISTER = "/register"
AUTH_CHANGE_PASSWORD = "/change-password"
AUTH_FORGOT_PASSWORD = "/forgot-password"
AUTH_RESET_PASSWORD = "/reset-password"

# 用户管理路径
USERS_LIST = ""
USERS_CREATE = ""
USERS_DETAIL = "/{user_id}"
USERS_UPDATE = "/{user_id}"
USERS_DELETE = "/{user_id}"
USERS_LOCK = "/{user_id}/lock"
USERS_UNLOCK = "/{user_id}/unlock"
USERS_ROLES = "/{user_id}/roles"
USERS_PERMISSIONS = "/{user_id}/permissions"

# WireGuard管理路径
WIREGUARD_SERVERS = "/servers"
WIREGUARD_SERVER_CREATE = "/servers"
WIREGUARD_SERVER_DETAIL = "/servers/{server_id}"
WIREGUARD_SERVER_UPDATE = "/servers/{server_id}"
WIREGUARD_SERVER_DELETE = "/servers/{server_id}"
WIREGUARD_SERVER_START = "/servers/{server_id}/start"
WIREGUARD_SERVER_STOP = "/servers/{server_id}/stop"
WIREGUARD_SERVER_RESTART = "/servers/{server_id}/restart"
WIREGUARD_SERVER_STATUS = "/servers/{server_id}/status"

WIREGUARD_CLIENTS = "/clients"
WIREGUARD_CLIENT_CREATE = "/clients"
WIREGUARD_CLIENT_DETAIL = "/clients/{client_id}"
WIREGUARD_CLIENT_UPDATE = "/clients/{client_id}"
WIREGUARD_CLIENT_DELETE = "/clients/{client_id}"
WIREGUARD_CLIENT_ENABLE = "/clients/{client_id}/enable"
WIREGUARD_CLIENT_DISABLE = "/clients/{client_id}/disable"
WIREGUARD_CLIENT_CONFIG = "/clients/{client_id}/config"
WIREGUARD_CLIENT_QR = "/clients/{client_id}/qr"

# BGP管理路径
BGP_SESSIONS = "/sessions"
BGP_SESSION_CREATE = "/sessions"
BGP_SESSION_DETAIL = "/sessions/{session_id}"
BGP_SESSION_UPDATE = "/sessions/{session_id}"
BGP_SESSION_DELETE = "/sessions/{session_id}"
BGP_SESSION_START = "/sessions/{session_id}/start"
BGP_SESSION_STOP = "/sessions/{session_id}/stop"
BGP_SESSION_STATUS = "/sessions/{session_id}/status"

BGP_ANNOUNCEMENTS = "/announcements"
BGP_ANNOUNCEMENT_CREATE = "/announcements"
BGP_ANNOUNCEMENT_DETAIL = "/announcements/{announcement_id}"
BGP_ANNOUNCEMENT_UPDATE = "/announcements/{announcement_id}"
BGP_ANNOUNCEMENT_DELETE = "/announcements/{announcement_id}"

# IPv6管理路径
IPV6_POOLS = "/pools"
IPV6_POOL_CREATE = "/pools"
IPV6_POOL_DETAIL = "/pools/{pool_id}"
IPV6_POOL_UPDATE = "/pools/{pool_id}"
IPV6_POOL_DELETE = "/pools/{pool_id}"

IPV6_ALLOCATIONS = "/allocations"
IPV6_ALLOCATION_CREATE = "/allocations"
IPV6_ALLOCATION_DETAIL = "/allocations/{allocation_id}"
IPV6_ALLOCATION_UPDATE = "/allocations/{allocation_id}"
IPV6_ALLOCATION_DELETE = "/allocations/{allocation_id}"

# MFA管理路径
MFA_SETUP_TOTP = "/setup-totp"
MFA_VERIFY_TOTP = "/verify-totp"
MFA_DISABLE_TOTP = "/disable-totp"
MFA_GENERATE_BACKUP_CODES = "/generate-backup-codes"
MFA_VERIFY_BACKUP_CODE = "/verify-backup-code"
MFA_SETTINGS = "/settings"

# 操作路径 - 使用连字符命名
WIREGUARD_SEARCH = "/search"
WIREGUARD_EXPORT = "/export-config"
USERS_SEARCH = "/search"
USERS_EXPORT = "/export"
BGP_SEARCH = "/search"
BGP_EXPORT = "/export"
IPV6_SEARCH = "/search"
IPV6_EXPORT = "/export"

# 系统路径
SYSTEM_STATUS = "/status"
SYSTEM_HEALTH = "/health"
SYSTEM_INFO = "/info"
SYSTEM_METRICS = "/metrics"

# 监控路径
MONITORING_DASHBOARD = "/dashboard"
MONITORING_SERVICES = "/services"
MONITORING_ALERTS = "/alerts"
MONITORING_PERFORMANCE = "/performance"

# 日志路径
LOGS_SYSTEM = "/system"
LOGS_AUDIT = "/audit"
LOGS_SECURITY = "/security"
LOGS_RECENT = "/recent"

# 获取完整路径的辅助函数
def get_api_path(*parts, version: APIVersion = None):
    """构建API路径"""
    if version is None:
        version = API_CURRENT_VERSION
    
    path = "/".join(str(part) for part in parts if part)
    return f"/api/{version.value}/{path}"

def get_auth_path(action: str, version: APIVersion = None):
    """获取认证路径"""
    return get_api_path(API_AUTH, action, version=version)

def get_users_path(action: str = None, user_id: int = None, version: APIVersion = None):
    """获取用户管理路径"""
    parts = [API_USERS]
    
    if user_id:
        parts.append(f"{user_id}")
    
    if action:
        parts.append(action)
    
    return get_api_path(*parts, version=version)

def get_wireguard_path(resource: str, action: str = None, resource_id: int = None, version: APIVersion = None):
    """获取WireGuard路径"""
    parts = [API_WIREGUARD, resource]
    
    if resource_id:
        parts.append(f"{resource_id}")
    
    if action:
        parts.append(action)
    
    return get_api_path(*parts, version=version)

def get_bgp_path(resource: str, action: str = None, resource_id: int = None, version: APIVersion = None):
    """获取BGP路径"""
    parts = [API_BGP, resource]
    
    if resource_id:
        parts.append(f"{resource_id}")
    
    if action:
        parts.append(action)
    
    return get_api_path(*parts, version=version)

def get_ipv6_path(resource: str, action: str = None, resource_id: int = None, version: APIVersion = None):
    """获取IPv6路径"""
    parts = [API_IPV6, resource]
    
    if resource_id:
        parts.append(f"{resource_id}")
    
    if action:
        parts.append(action)
    
    return get_api_path(*parts, version=version)

def get_mfa_path(action: str, version: APIVersion = None):
    """获取MFA路径"""
    return get_api_path(API_MFA, action, version=version)

def get_system_path(action: str, version: APIVersion = None):
    """获取系统路径"""
    return get_api_path(API_SYSTEM, action, version=version)

def get_monitoring_path(action: str, version: APIVersion = None):
    """获取监控路径"""
    return get_api_path(API_MONITORING, action, version=version)

def get_logs_path(action: str, version: APIVersion = None):
    """获取日志路径"""
    return get_api_path(API_LOGS, action, version=version)
