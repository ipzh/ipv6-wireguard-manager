"""
简化的API路径配置模块
"""

# API基础配置
API_BASE_PATH = "/api"
API_CURRENT_VERSION = "v1"

# 路径常量
AUTH_LOGIN = "/login"
AUTH_LOGOUT = "/logout"
AUTH_REFRESH = "/refresh"
AUTH_ME = "/me"
USERS_LIST = ""
USERS_CREATE = ""
USERS_DETAIL = "/{user_id}"
USERS_UPDATE = "/{user_id}"
USERS_DELETE = "/{user_id}"
WIREGUARD_SERVERS = "/servers"
WIREGUARD_SERVER_CREATE = "/servers"
WIREGUARD_SERVER_DETAIL = "/servers/{server_id}"
WIREGUARD_CLIENTS = "/clients"
WIREGUARD_CLIENT_CREATE = "/clients"
WIREGUARD_CLIENT_DETAIL = "/clients/{client_id}"

# 路径构建函数
def get_api_path(*parts):
    """构建API路径"""
    path = "/".join(str(part) for part in parts if part)
    return f"/api/{API_CURRENT_VERSION}/{path}"


def get_auth_path(action: str = None, **kwargs):
    """获取auth路径"""
    parts = ["/auth"]
    
    if action:
        parts.append(action)
    
    return get_api_path(*parts)


def get_users_path(action: str = None, **kwargs):
    """获取users路径"""
    parts = ["/users"]
    
    if action:
        parts.append(action)
    
    return get_api_path(*parts)


def get_wireguard_path(action: str = None, **kwargs):
    """获取wireguard路径"""
    parts = ["/wireguard"]
    
    if action:
        parts.append(action)
    
    return get_api_path(*parts)

