<?php
/**
 * API模拟器 - 用于前端开发测试
 * 当后端API服务不可用时，提供模拟数据
 */

// 设置响应头
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// 处理OPTIONS请求
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// 获取请求信息
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = str_replace('/api_mock.php', '', $path);

// 移除/api/v1前缀（如果存在）
$path = preg_replace('/^\/api\/v1/', '', $path);

// 模拟API响应
function mockResponse($data, $status = 200) {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

// 模拟数据
$mockData = [
    '/system/config' => [
        'success' => true,
        'data' => [
            'system_name' => 'IPv6 WireGuard Manager',
            'version' => '1.0.0',
            'timezone' => 'Asia/Shanghai',
            'language' => 'zh-CN',
            'debug_mode' => false,
            'log_level' => 'info'
        ]
    ],
    '/system/info' => [
        'success' => true,
        'data' => [
            'hostname' => 'wireguard-server',
            'os' => 'Ubuntu 22.04 LTS',
            'kernel' => '5.15.0-91-generic',
            'uptime' => '15 days, 3 hours',
            'cpu_usage' => 25.5,
            'memory_usage' => 68.2,
            'disk_usage' => 45.8
        ]
    ],
    '/wireguard/servers' => [
        'success' => true,
        'data' => [
            [
                'id' => 1,
                'name' => 'wg0',
                'interface' => 'wg0',
                'port' => 51820,
                'private_key' => '***',
                'public_key' => 'ABC123...',
                'status' => 'running',
                'clients_count' => 5,
                'created_at' => '2024-01-01T00:00:00Z'
            ]
        ]
    ],
    '/wireguard/clients' => [
        'success' => true,
        'data' => [
            [
                'id' => 1,
                'name' => 'client1',
                'public_key' => 'DEF456...',
                'allowed_ips' => '10.0.0.2/32',
                'server_id' => 1,
                'status' => 'active',
                'last_seen' => '2024-01-15T10:30:00Z'
            ]
        ]
    ],
    '/bgp/sessions' => [
        'success' => true,
        'data' => [
            [
                'id' => 1,
                'name' => 'upstream1',
                'remote_as' => 65001,
                'remote_ip' => '192.168.1.1',
                'status' => 'established',
                'uptime' => '10 days, 2 hours',
                'routes_received' => 1500,
                'routes_advertised' => 5
            ]
        ]
    ],
    '/ipv6/pools' => [
        'success' => true,
        'data' => [
            [
                'id' => 1,
                'name' => 'main-pool',
                'prefix' => '2001:db8::/48',
                'allocated' => '2001:db8::/64',
                'available' => '2001:db8:1::/64',
                'usage_percent' => 25.5
            ]
        ]
    ],
    '/monitoring/metrics' => [
        'success' => true,
        'data' => [
            'cpu_usage' => 25.5,
            'memory_usage' => 68.2,
            'disk_usage' => 45.8,
            'network_in' => 1024,
            'network_out' => 2048,
            'active_connections' => 150
        ]
    ],
    '/monitoring/alerts' => [
        'success' => true,
        'data' => [
            [
                'id' => 1,
                'level' => 'warning',
                'message' => 'CPU使用率较高',
                'timestamp' => '2024-01-15T10:30:00Z',
                'status' => 'active'
            ]
        ]
    ],
    '/logs' => [
        'success' => true,
        'data' => [
            'logs' => [
                [
                    'id' => 1,
                    'level' => 'info',
                    'message' => 'WireGuard服务启动成功',
                    'source' => 'wireguard',
                    'timestamp' => '2024-01-15T10:30:00Z'
                ]
            ],
            'total' => 1000
        ]
    ],
    '/users' => [
        'success' => true,
        'data' => [
            [
                'id' => 1,
                'username' => 'admin',
                'email' => 'admin@example.com',
                'role' => 'admin',
                'status' => 'active',
                'created_at' => '2024-01-01T00:00:00Z',
                'last_login' => '2024-01-15T10:30:00Z'
            ]
        ]
    ],
    '/network/interfaces' => [
        'success' => true,
        'data' => [
            'interfaces' => [
                [
                    'name' => 'eth0',
                    'status' => 'up',
                    'ipv4' => '192.168.1.100',
                    'ipv6' => '2001:db8::1',
                    'mtu' => 1500,
                    'speed' => '1000Mbps'
                ]
            ]
        ]
    ]
];

// 检查是否有匹配的模拟数据
if (isset($mockData[$path])) {
    mockResponse($mockData[$path]);
}

// 如果没有匹配的数据，返回404
mockResponse([
    'success' => false,
    'error' => 'API endpoint not found',
    'message' => "Endpoint '{$path}' not implemented in mock API",
    'available_endpoints' => array_keys($mockData)
], 404);
?>
