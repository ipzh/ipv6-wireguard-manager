<?php
/**
 * API端点映射配置
 * 定义前端调用的API端点与后端实际端点的映射关系
 */

return [
    // 认证相关
    'auth' => [
        'login' => '/auth/login',
        'logout' => '/auth/logout',
        'me' => '/auth/me',
        'refresh' => '/auth/refresh',
        'health' => '/auth/health'
    ],
    
    // 用户管理
    'users' => [
        'list' => '/users',
        'create' => '/users',
        'get' => '/users/{id}',
        'update' => '/users/{id}',
        'delete' => '/users/{id}'
    ],
    
    // WireGuard管理
    'wireguard' => [
        'config' => '/wireguard/config',
        'servers' => '/wireguard/servers',
        'clients' => '/wireguard/clients',
        'peers' => '/wireguard/peers',
        'status' => '/wireguard/status'
    ],
    
    // 网络管理
    'network' => [
        'interfaces' => '/network/interfaces',
        'status' => '/network/status',
        'connections' => '/network/connections',
        'health' => '/network/health'
    ],
    
    // BGP管理
    'bgp' => [
        'sessions' => '/bgp/sessions',
        'routes' => '/bgp/routes',  // 替代announcements
        'status' => '/bgp/status'
    ],
    
    // IPv6管理
    'ipv6' => [
        'pools' => '/ipv6/pools',
        'allocations' => '/ipv6/allocations',
        'health' => '/ipv6/health'
    ],
    
    // 监控
    'monitoring' => [
        'dashboard' => '/monitoring/dashboard',
        'metrics_system' => '/monitoring/metrics/system',
        'metrics_application' => '/monitoring/metrics/application',
        'alerts_active' => '/monitoring/alerts/active',
        'alerts_history' => '/monitoring/alerts/history',
        'alerts_rules' => '/monitoring/alerts/rules',
        'performance' => '/monitoring/performance',
        'health' => '/monitoring/health'
    ],
    
    // 日志管理
    'logs' => [
        'list' => '/logs',
        'get' => '/logs/{id}',
        'delete' => '/logs/{id}',
        'health' => '/logs/health/check'
    ],
    
    // 系统管理
    'system' => [
        'info' => '/system/info',
        'processes' => '/system/processes',
        'restart' => '/system/restart',
        'shutdown' => '/system/shutdown',
        'health' => '/system/health/check'
    ],
    
    // 状态检查
    'status' => [
        'overview' => '/status',
        'health' => '/status/health',
        'services' => '/status/services'
    ],
    
    // 健康检查
    'health' => [
        'basic' => '/health',
        'detailed' => '/health/detailed',
        'readiness' => '/health/readiness',
        'liveness' => '/health/liveness',
        'metrics' => '/metrics'
    ],
    
    // 调试诊断
    'debug' => [
        'system_info' => '/debug/system-info',
        'process_info' => '/debug/process-info',
        'network_info' => '/debug/network-info',
        'api_status' => '/debug/api-status',
        'database_status' => '/debug/database-status',
        'comprehensive_check' => '/debug/comprehensive-check',
        'ping' => '/debug/ping'
    ]
];
?>
