<?php
/**
 * API端点配置 - 与后端JWT认证系统完全兼容
 */

// 引入配置
require_once __DIR__ . '/config.php';

// API基础配置 - 使用config.php中定义的API_BASE_URL
// API_BASE_URL已在config.php中定义，此处不再重复定义
define('API_TIMEOUT', 30);

// 认证相关端点
define('API_AUTH_LOGIN', '/auth/login');
define('API_AUTH_LOGOUT', '/auth/logout');
define('API_AUTH_REFRESH', '/auth/refresh');
define('API_AUTH_ME', '/auth/me');
define('API_AUTH_VERIFY', '/auth/verify-token');
define('API_AUTH_REGISTER', '/auth/register');
define('API_AUTH_CHANGE_PASSWORD', '/auth/change-password');
define('API_AUTH_FORGOT_PASSWORD', '/auth/forgot-password');
define('API_AUTH_RESET_PASSWORD', '/auth/reset-password');

// 用户管理端点
define('API_USERS_LIST', '/users');
define('API_USERS_CREATE', '/users');
define('API_USERS_GET', '/users/{id}');
define('API_USERS_UPDATE', '/users/{id}');
define('API_USERS_DELETE', '/users/{id}');
define('API_USERS_LOCK', '/users/{id}/lock');
define('API_USERS_UNLOCK', '/users/{id}/unlock');
define('API_USERS_ROLES', '/users/{id}/roles');
define('API_USERS_PERMISSIONS', '/users/{id}/permissions');

// 角色管理端点
define('API_ROLES_LIST', '/roles');
define('API_ROLES_CREATE', '/roles');
define('API_ROLES_GET', '/roles/{id}');
define('API_ROLES_UPDATE', '/roles/{id}');
define('API_ROLES_DELETE', '/roles/{id}');

// 权限管理端点
define('API_PERMISSIONS_LIST', '/permissions');
define('API_PERMISSIONS_GET', '/permissions/{id}');

// WireGuard管理端点
define('API_WIREGUARD_SERVERS', '/wireguard/servers');
define('API_WIREGUARD_SERVER_CREATE', '/wireguard/servers');
define('API_WIREGUARD_SERVER_GET', '/wireguard/servers/{id}');
define('API_WIREGUARD_SERVER_UPDATE', '/wireguard/servers/{id}');
define('API_WIREGUARD_SERVER_DELETE', '/wireguard/servers/{id}');
define('API_WIREGUARD_SERVER_START', '/wireguard/servers/{id}/start');
define('API_WIREGUARD_SERVER_STOP', '/wireguard/servers/{id}/stop');
define('API_WIREGUARD_SERVER_RESTART', '/wireguard/servers/{id}/restart');
define('API_WIREGUARD_SERVER_STATUS', '/wireguard/servers/{id}/status');

define('API_WIREGUARD_CLIENTS', '/wireguard/clients');
define('API_WIREGUARD_CLIENT_CREATE', '/wireguard/clients');
define('API_WIREGUARD_CLIENT_GET', '/wireguard/clients/{id}');
define('API_WIREGUARD_CLIENT_UPDATE', '/wireguard/clients/{id}');
define('API_WIREGUARD_CLIENT_DELETE', '/wireguard/clients/{id}');
define('API_WIREGUARD_CLIENT_ENABLE', '/wireguard/clients/{id}/enable');
define('API_WIREGUARD_CLIENT_DISABLE', '/wireguard/clients/{id}/disable');
define('API_WIREGUARD_CLIENT_CONFIG', '/wireguard/clients/{id}/config');
define('API_WIREGUARD_CLIENT_QR', '/wireguard/clients/{id}/qr');

// BGP管理端点
define('API_BGP_SESSIONS', '/bgp/sessions');
define('API_BGP_SESSION_CREATE', '/bgp/sessions');
define('API_BGP_SESSION_GET', '/bgp/sessions/{id}');
define('API_BGP_SESSION_UPDATE', '/bgp/sessions/{id}');
define('API_BGP_SESSION_DELETE', '/bgp/sessions/{id}');
define('API_BGP_SESSION_START', '/bgp/sessions/{id}/start');
define('API_BGP_SESSION_STOP', '/bgp/sessions/{id}/stop');
define('API_BGP_SESSION_STATUS', '/bgp/sessions/{id}/status');

define('API_BGP_ANNOUNCEMENTS', '/bgp/announcements');
define('API_BGP_ANNOUNCEMENT_CREATE', '/bgp/announcements');
define('API_BGP_ANNOUNCEMENT_GET', '/bgp/announcements/{id}');
define('API_BGP_ANNOUNCEMENT_UPDATE', '/bgp/announcements/{id}');
define('API_BGP_ANNOUNCEMENT_DELETE', '/bgp/announcements/{id}');

// IPv6管理端点
define('API_IPV6_POOLS', '/ipv6/pools');
define('API_IPV6_POOL_CREATE', '/ipv6/pools');
define('API_IPV6_POOL_GET', '/ipv6/pools/{id}');
define('API_IPV6_POOL_UPDATE', '/ipv6/pools/{id}');
define('API_IPV6_POOL_DELETE', '/ipv6/pools/{id}');

define('API_IPV6_ALLOCATIONS', '/ipv6/allocations');
define('API_IPV6_ALLOCATION_CREATE', '/ipv6/allocations');
define('API_IPV6_ALLOCATION_GET', '/ipv6/allocations/{id}');
define('API_IPV6_ALLOCATION_UPDATE', '/ipv6/allocations/{id}');
define('API_IPV6_ALLOCATION_DELETE', '/ipv6/allocations/{id}');

// 系统管理端点
define('API_SYSTEM_INFO', '/system/info');
define('API_SYSTEM_CONFIG', '/system/config');
define('API_SYSTEM_STATUS', '/system/status');
define('API_SYSTEM_HEALTH', '/system/health');
define('API_SYSTEM_METRICS', '/system/metrics');
define('API_SYSTEM_LOGS', '/system/logs');
define('API_SYSTEM_BACKUP', '/system/backup');
define('API_SYSTEM_RESTORE', '/system/restore');

// 监控端点
define('API_MONITORING_DASHBOARD', '/monitoring/dashboard');
define('API_MONITORING_METRICS', '/monitoring/metrics');
define('API_MONITORING_ALERTS', '/monitoring/alerts');
define('API_MONITORING_GRAPHS', '/monitoring/graphs');
define('API_MONITORING_REPORTS', '/monitoring/reports');

// 日志端点
define('API_LOGS_LIST', '/logs');
define('API_LOGS_GET', '/logs/{id}');
define('API_LOGS_CLEAR', '/logs/clear');
define('API_LOGS_EXPORT', '/logs/export');
define('API_LOGS_SEARCH', '/logs/search');

// 网络端点
define('API_NETWORK_INTERFACES', '/network/interfaces');
define('API_NETWORK_INTERFACE_GET', '/network/interfaces/{id}');
define('API_NETWORK_INTERFACE_UPDATE', '/network/interfaces/{id}');
define('API_NETWORK_ROUTES', '/network/routes');
define('API_NETWORK_ROUTE_CREATE', '/network/routes');
define('API_NETWORK_ROUTE_DELETE', '/network/routes/{id}');

// 审计日志端点
define('API_AUDIT_LOGS', '/audit/logs');
define('API_AUDIT_LOGS_GET', '/audit/logs/{id}');
define('API_AUDIT_LOGS_SEARCH', '/audit/logs/search');
define('API_AUDIT_LOGS_EXPORT', '/audit/logs/export');

// 文件上传端点
define('API_UPLOAD_FILE', '/upload/file');
define('API_UPLOAD_IMAGE', '/upload/image');
define('API_UPLOAD_CONFIG', '/upload/config');

// WebSocket端点
define('WS_SYSTEM_STATUS', 'ws://' . ($_ENV['LOCAL_HOST'] ?? 'localhost') . ':8000/ws/system/status');
define('WS_MONITORING_DATA', 'ws://' . ($_ENV['LOCAL_HOST'] ?? 'localhost') . ':8000/ws/monitoring/data');
define('WS_LOGS_STREAM', 'ws://' . ($_ENV['LOCAL_HOST'] ?? 'localhost') . ':8000/ws/logs/stream');

/**
 * 获取API端点URL
 */
function getApiUrl($endpoint, $params = []) {
    $url = API_BASE_URL . $endpoint;
    
    // 替换路径参数
    foreach ($params as $key => $value) {
        $url = str_replace('{' . $key . '}', $value, $url);
    }
    
    return $url;
}

/**
 * 获取认证端点URL
 */
function getAuthUrl($endpoint) {
    return API_BASE_URL . $endpoint;
}

/**
 * 获取用户管理端点URL
 */
function getUserUrl($endpoint, $userId = null) {
    $url = API_BASE_URL . $endpoint;
    if ($userId) {
        $url = str_replace('{id}', $userId, $url);
    }
    return $url;
}

/**
 * 获取WireGuard端点URL
 */
function getWireGuardUrl($endpoint, $id = null) {
    $url = API_BASE_URL . $endpoint;
    if ($id) {
        $url = str_replace('{id}', $id, $url);
    }
    return $url;
}

/**
 * 获取BGP端点URL
 */
function getBGPUrl($endpoint, $id = null) {
    $url = API_BASE_URL . $endpoint;
    if ($id) {
        $url = str_replace('{id}', $id, $url);
    }
    return $url;
}

/**
 * 获取IPv6端点URL
 */
function getIPv6Url($endpoint, $id = null) {
    $url = API_BASE_URL . $endpoint;
    if ($id) {
        $url = str_replace('{id}', $id, $url);
    }
    return $url;
}

/**
 * 获取系统端点URL
 */
function getSystemUrl($endpoint) {
    return API_BASE_URL . $endpoint;
}

/**
 * 获取监控端点URL
 */
function getMonitoringUrl($endpoint) {
    return API_BASE_URL . $endpoint;
}

/**
 * 获取日志端点URL
 */
function getLogsUrl($endpoint, $id = null) {
    $url = API_BASE_URL . $endpoint;
    if ($id) {
        $url = str_replace('{id}', $id, $url);
    }
    return $url;
}

/**
 * 获取网络端点URL
 */
function getNetworkUrl($endpoint, $id = null) {
    $url = API_BASE_URL . $endpoint;
    if ($id) {
        $url = str_replace('{id}', $id, $url);
    }
    return $url;
}

/**
 * API端点配置数组
 */
$API_ENDPOINTS = [
    // 认证端点
    'auth' => [
        'login' => API_AUTH_LOGIN,
        'logout' => API_AUTH_LOGOUT,
        'refresh' => API_AUTH_REFRESH,
        'me' => API_AUTH_ME,
        'verify' => API_AUTH_VERIFY,
        'register' => API_AUTH_REGISTER,
        'change_password' => API_AUTH_CHANGE_PASSWORD,
        'forgot_password' => API_AUTH_FORGOT_PASSWORD,
        'reset_password' => API_AUTH_RESET_PASSWORD,
    ],
    
    // 用户管理端点
    'users' => [
        'list' => API_USERS_LIST,
        'create' => API_USERS_CREATE,
        'get' => API_USERS_GET,
        'update' => API_USERS_UPDATE,
        'delete' => API_USERS_DELETE,
        'lock' => API_USERS_LOCK,
        'unlock' => API_USERS_UNLOCK,
        'roles' => API_USERS_ROLES,
        'permissions' => API_USERS_PERMISSIONS,
    ],
    
    // WireGuard端点
    'wireguard' => [
        'servers' => [
            'list' => API_WIREGUARD_SERVERS,
            'create' => API_WIREGUARD_SERVER_CREATE,
            'get' => API_WIREGUARD_SERVER_GET,
            'update' => API_WIREGUARD_SERVER_UPDATE,
            'delete' => API_WIREGUARD_SERVER_DELETE,
            'start' => API_WIREGUARD_SERVER_START,
            'stop' => API_WIREGUARD_SERVER_STOP,
            'restart' => API_WIREGUARD_SERVER_RESTART,
            'status' => API_WIREGUARD_SERVER_STATUS,
        ],
        'clients' => [
            'list' => API_WIREGUARD_CLIENTS,
            'create' => API_WIREGUARD_CLIENT_CREATE,
            'get' => API_WIREGUARD_CLIENT_GET,
            'update' => API_WIREGUARD_CLIENT_UPDATE,
            'delete' => API_WIREGUARD_CLIENT_DELETE,
            'enable' => API_WIREGUARD_CLIENT_ENABLE,
            'disable' => API_WIREGUARD_CLIENT_DISABLE,
            'config' => API_WIREGUARD_CLIENT_CONFIG,
            'qr' => API_WIREGUARD_CLIENT_QR,
        ],
    ],
    
    // BGP端点
    'bgp' => [
        'sessions' => [
            'list' => API_BGP_SESSIONS,
            'create' => API_BGP_SESSION_CREATE,
            'get' => API_BGP_SESSION_GET,
            'update' => API_BGP_SESSION_UPDATE,
            'delete' => API_BGP_SESSION_DELETE,
            'start' => API_BGP_SESSION_START,
            'stop' => API_BGP_SESSION_STOP,
            'status' => API_BGP_SESSION_STATUS,
        ],
        'announcements' => [
            'list' => API_BGP_ANNOUNCEMENTS,
            'create' => API_BGP_ANNOUNCEMENT_CREATE,
            'get' => API_BGP_ANNOUNCEMENT_GET,
            'update' => API_BGP_ANNOUNCEMENT_UPDATE,
            'delete' => API_BGP_ANNOUNCEMENT_DELETE,
        ],
    ],
    
    // IPv6端点
    'ipv6' => [
        'pools' => [
            'list' => API_IPV6_POOLS,
            'create' => API_IPV6_POOL_CREATE,
            'get' => API_IPV6_POOL_GET,
            'update' => API_IPV6_POOL_UPDATE,
            'delete' => API_IPV6_POOL_DELETE,
        ],
        'allocations' => [
            'list' => API_IPV6_ALLOCATIONS,
            'create' => API_IPV6_ALLOCATION_CREATE,
            'get' => API_IPV6_ALLOCATION_GET,
            'update' => API_IPV6_ALLOCATION_UPDATE,
            'delete' => API_IPV6_ALLOCATION_DELETE,
        ],
    ],
    
    // 系统端点
    'system' => [
        'info' => API_SYSTEM_INFO,
        'config' => API_SYSTEM_CONFIG,
        'status' => API_SYSTEM_STATUS,
        'health' => API_SYSTEM_HEALTH,
        'metrics' => API_SYSTEM_METRICS,
        'logs' => API_SYSTEM_LOGS,
        'backup' => API_SYSTEM_BACKUP,
        'restore' => API_SYSTEM_RESTORE,
    ],
    
    // 监控端点
    'monitoring' => [
        'dashboard' => API_MONITORING_DASHBOARD,
        'metrics' => API_MONITORING_METRICS,
        'alerts' => API_MONITORING_ALERTS,
        'graphs' => API_MONITORING_GRAPHS,
        'reports' => API_MONITORING_REPORTS,
    ],
    
    // 日志端点
    'logs' => [
        'list' => API_LOGS_LIST,
        'get' => API_LOGS_GET,
        'clear' => API_LOGS_CLEAR,
        'export' => API_LOGS_EXPORT,
        'search' => API_LOGS_SEARCH,
    ],
    
    // 网络端点
    'network' => [
        'interfaces' => [
            'list' => API_NETWORK_INTERFACES,
            'get' => API_NETWORK_INTERFACE_GET,
            'update' => API_NETWORK_INTERFACE_UPDATE,
        ],
        'routes' => [
            'list' => API_NETWORK_ROUTES,
            'create' => API_NETWORK_ROUTE_CREATE,
            'delete' => API_NETWORK_ROUTE_DELETE,
        ],
    ],
];

/**
 * 获取端点配置
 */
function getEndpointConfig($category, $subcategory = null, $action = null) {
    global $API_ENDPOINTS;
    
    if (!isset($API_ENDPOINTS[$category])) {
        return null;
    }
    
    $config = $API_ENDPOINTS[$category];
    
    if ($subcategory && isset($config[$subcategory])) {
        $config = $config[$subcategory];
        
        if ($action && isset($config[$action])) {
            return $config[$action];
        }
        
        return $config;
    }
    
    return $config;
}

/**
 * 检查端点是否存在
 */
function endpointExists($category, $subcategory = null, $action = null) {
    return getEndpointConfig($category, $subcategory, $action) !== null;
}
?>