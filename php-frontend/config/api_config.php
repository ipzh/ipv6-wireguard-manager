<?php
/**
 * API基础配置
 */

return [
    'api' => [
        'base_url' => 'http://localhost:8000',
        'version' => 'v1',
        'timeout' => 30,
        'retry_attempts' => 3,
        'retry_delay' => 1000, // ms
    ],
    
    'paths' => [
        // 认证路径
        'auth' => [
            'login' => '/auth/login',
            'logout' => '/auth/logout',
            'refresh' => '/auth/refresh',
            'me' => '/auth/me',
            'verify' => '/auth/verify-token',
            'register' => '/auth/register',
            'change_password' => '/auth/change-password',
            'forgot_password' => '/auth/forgot-password',
            'reset_password' => '/auth/reset-password',
        ],
        
        // 用户管理路径
        'users' => [
            'list' => '/users',
            'create' => '/users',
            'get' => '/users/{id}',
            'update' => '/users/{id}',
            'delete' => '/users/{id}',
            'lock' => '/users/{id}/lock',
            'unlock' => '/users/{id}/unlock',
            'roles' => '/users/{id}/roles',
            'permissions' => '/users/{id}/permissions',
            'search' => '/users/search',
            'export' => '/users/export',
        ],
        
        // WireGuard管理路径
        'wireguard' => [
            'servers' => [
                'list' => '/wireguard/servers',
                'create' => '/wireguard/servers',
                'get' => '/wireguard/servers/{id}',
                'update' => '/wireguard/servers/{id}',
                'delete' => '/wireguard/servers/{id}',
                'start' => '/wireguard/servers/{id}/start',
                'stop' => '/wireguard/servers/{id}/stop',
                'restart' => '/wireguard/servers/{id}/restart',
                'status' => '/wireguard/servers/{id}/status',
                'search' => '/wireguard/servers/search',
                'export' => '/wireguard/servers/export-config',
            ],
            'clients' => [
                'list' => '/wireguard/clients',
                'create' => '/wireguard/clients',
                'get' => '/wireguard/clients/{id}',
                'update' => '/wireguard/clients/{id}',
                'delete' => '/wireguard/clients/{id}',
                'enable' => '/wireguard/clients/{id}/enable',
                'disable' => '/wireguard/clients/{id}/disable',
                'config' => '/wireguard/clients/{id}/config',
                'qr' => '/wireguard/clients/{id}/qr',
                'search' => '/wireguard/clients/search',
                'export' => '/wireguard/clients/export-config',
            ],
        ],
        
        // BGP管理路径
        'bgp' => [
            'sessions' => [
                'list' => '/bgp/sessions',
                'create' => '/bgp/sessions',
                'get' => '/bgp/sessions/{id}',
                'update' => '/bgp/sessions/{id}',
                'delete' => '/bgp/sessions/{id}',
                'start' => '/bgp/sessions/{id}/start',
                'stop' => '/bgp/sessions/{id}/stop',
                'status' => '/bgp/sessions/{id}/status',
                'search' => '/bgp/sessions/search',
                'export' => '/bgp/sessions/export',
            ],
            'announcements' => [
                'list' => '/bgp/announcements',
                'create' => '/bgp/announcements',
                'get' => '/bgp/announcements/{id}',
                'update' => '/bgp/announcements/{id}',
                'delete' => '/bgp/announcements/{id}',
                'search' => '/bgp/announcements/search',
                'export' => '/bgp/announcements/export',
            ],
        ],
        
        // IPv6管理路径
        'ipv6' => [
            'pools' => [
                'list' => '/ipv6/pools',
                'create' => '/ipv6/pools',
                'get' => '/ipv6/pools/{id}',
                'update' => '/ipv6/pools/{id}',
                'delete' => '/ipv6/pools/{id}',
                'search' => '/ipv6/pools/search',
                'export' => '/ipv6/pools/export',
            ],
            'allocations' => [
                'list' => '/ipv6/allocations',
                'create' => '/ipv6/allocations',
                'get' => '/ipv6/allocations/{id}',
                'update' => '/ipv6/allocations/{id}',
                'delete' => '/ipv6/allocations/{id}',
                'search' => '/ipv6/allocations/search',
                'export' => '/ipv6/allocations/export',
            ],
        ],
        
        // MFA管理路径
        'mfa' => [
            'setup_totp' => '/mfa/setup-totp',
            'verify_totp' => '/mfa/verify-totp',
            'disable_totp' => '/mfa/disable-totp',
            'generate_backup_codes' => '/mfa/generate-backup-codes',
            'verify_backup_code' => '/mfa/verify-backup-code',
            'settings' => '/mfa/settings',
        ],
        
        // 系统路径
        'system' => [
            'status' => '/system/status',
            'health' => '/system/health',
            'info' => '/system/info',
            'metrics' => '/system/metrics',
        ],
        
        // 监控路径
        'monitoring' => [
            'dashboard' => '/monitoring/dashboard',
            'services' => '/monitoring/services',
            'alerts' => '/monitoring/alerts',
            'performance' => '/monitoring/performance',
        ],
        
        // 日志路径
        'logs' => [
            'system' => '/logs/system',
            'audit' => '/logs/audit',
            'security' => '/logs/security',
            'recent' => '/logs/recent',
        ],
    ],
    
    'websocket' => [
        'system_status' => 'ws://localhost:8000/ws/system/status',
        'monitoring_data' => 'ws://localhost:8000/ws/monitoring/data',
        'logs_stream' => 'ws://localhost:8000/ws/logs/stream',
    ]
];
