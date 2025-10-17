<?php
/**
 * JWT认证API模拟器 - 与后端JWT认证系统完全兼容
 * 当后端API服务不可用时，提供模拟数据
 */

// 设置响应头
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// 处理OPTIONS请求
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// 获取请求信息
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = str_replace('/api_mock_jwt.php', '', $path);
$query = parse_url($_SERVER['REQUEST_URI'], PHP_URL_QUERY);

// 获取请求体
$input = file_get_contents('php://input');
$data = json_decode($input, true);

// 获取Authorization头
$headers = getallheaders();
$authorization = $headers['Authorization'] ?? '';

// 模拟JWT令牌验证
function verifyMockToken($authHeader) {
    if (!$authHeader || !str_starts_with($authHeader, 'Bearer ')) {
        return false;
    }
    
    $token = substr($authHeader, 7);
    
    // 简单的模拟令牌验证
    // 在实际环境中，这里应该验证JWT令牌
    if ($token === 'mock_access_token' || $token === 'valid_token') {
        return [
            'sub' => '1',
            'username' => 'admin',
            'email' => 'admin@example.com',
            'is_superuser' => true,
            'exp' => time() + 3600
        ];
    }
    
    return false;
}

// 模拟API响应
function mockResponse($data, $status = 200) {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

// 模拟错误响应
function mockError($message, $status = 400, $code = null) {
    $response = [
        'success' => false,
        'error' => $message,
        'detail' => $message
    ];
    
    if ($code) {
        $response['code'] = $code;
    }
    
    mockResponse($response, $status);
}

// 模拟成功响应
function mockSuccess($data, $message = null) {
    $response = [
        'success' => true,
        'data' => $data
    ];
    
    if ($message) {
        $response['message'] = $message;
    }
    
    mockResponse($response);
}

// 检查认证
function requireAuth() {
    global $authorization;
    
    $user = verifyMockToken($authorization);
    if (!$user) {
        mockError('未提供有效的认证令牌', 401);
    }
    
    return $user;
}

// 模拟数据存储
$mockStorage = [
    'users' => [
        [
            'id' => 1,
            'username' => 'admin',
            'email' => 'admin@example.com',
            'full_name' => '系统管理员',
            'is_active' => true,
            'is_superuser' => true,
            'created_at' => '2024-01-01T00:00:00Z',
            'last_login' => '2024-01-15T10:30:00Z',
            'roles' => [
                ['id' => 1, 'name' => 'admin', 'display_name' => '管理员']
            ]
        ],
        [
            'id' => 2,
            'username' => 'operator',
            'email' => 'operator@example.com',
            'full_name' => '系统操作员',
            'is_active' => true,
            'is_superuser' => false,
            'created_at' => '2024-01-02T00:00:00Z',
            'last_login' => '2024-01-15T09:15:00Z',
            'roles' => [
                ['id' => 2, 'name' => 'operator', 'display_name' => '操作员']
            ]
        ]
    ],
    'wireguard_servers' => [
        [
            'id' => 1,
            'name' => 'wg0',
            'description' => '主WireGuard服务器',
            'interface' => 'wg0',
            'listen_port' => 51820,
            'address' => '10.0.0.1/24',
            'dns' => '8.8.8.8',
            'status' => 'active',
            'is_enabled' => true,
            'total_clients' => 5,
            'active_clients' => 3,
            'created_at' => '2024-01-01T00:00:00Z',
            'created_by' => 1
        ]
    ],
    'wireguard_clients' => [
        [
            'id' => 1,
            'name' => 'client1',
            'description' => '客户端1',
            'allowed_ips' => '10.0.0.2/32',
            'status' => 'active',
            'is_enabled' => true,
            'bytes_sent' => 1024000,
            'bytes_received' => 2048000,
            'last_handshake' => '2024-01-15T10:25:00Z',
            'server_id' => 1,
            'created_at' => '2024-01-01T00:00:00Z',
            'created_by' => 1
        ]
    ],
    'bgp_sessions' => [
        [
            'id' => 1,
            'name' => 'bgp-session-1',
            'description' => 'BGP会话1',
            'local_as' => 65001,
            'remote_as' => 65002,
            'local_ip' => '192.168.1.1',
            'remote_ip' => '192.168.1.2',
            'status' => 'established',
            'is_enabled' => true,
            'established_time' => '2024-01-01T00:00:00Z',
            'prefixes_received' => 100,
            'prefixes_sent' => 50,
            'created_at' => '2024-01-01T00:00:00Z',
            'created_by' => 1
        ]
    ],
    'ipv6_pools' => [
        [
            'id' => 1,
            'name' => 'ipv6-pool-1',
            'description' => 'IPv6前缀池1',
            'prefix' => '2001:db8::/48',
            'prefix_length' => 48,
            'total_addresses' => 1208925819614629174706176,
            'allocated_addresses' => 0,
            'available_addresses' => 1208925819614629174706176,
            'status' => 'active',
            'is_enabled' => true,
            'created_at' => '2024-01-01T00:00:00Z',
            'created_by' => 1
        ]
    ]
];

// 路由处理
switch ($path) {
    // 认证相关端点
    case '/auth/login':
        if ($method === 'POST') {
            $username = $data['username'] ?? '';
            $password = $data['password'] ?? '';
            
            if ($username === 'admin' && $password === 'admin123') {
                mockSuccess([
                    'access_token' => 'mock_access_token',
                    'refresh_token' => 'mock_refresh_token',
                    'token_type' => 'bearer',
                    'expires_in' => 3600,
                    'user' => $mockStorage['users'][0]
                ]);
            } else {
                mockError('用户名或密码错误', 401);
            }
        }
        break;
        
    case '/auth/logout':
        if ($method === 'POST') {
            mockSuccess(['message' => '登出成功']);
        }
        break;
        
    case '/auth/refresh':
        if ($method === 'POST') {
            $refreshToken = $data['refresh_token'] ?? '';
            
            if ($refreshToken === 'mock_refresh_token') {
                mockSuccess([
                    'access_token' => 'new_mock_access_token',
                    'refresh_token' => 'new_mock_refresh_token',
                    'token_type' => 'bearer',
                    'expires_in' => 3600
                ]);
            } else {
                mockError('无效的刷新令牌', 401);
            }
        }
        break;
        
    case '/auth/me':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess($mockStorage['users'][0]);
        }
        break;
        
    case '/auth/verify-token':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess([
                'valid' => true,
                'user' => [
                    'id' => $user['sub'],
                    'username' => $user['username'],
                    'email' => $user['email'],
                    'is_superuser' => $user['is_superuser']
                ]
            ]);
        }
        break;
        
    case '/auth/register':
        if ($method === 'POST') {
            $username = $data['username'] ?? '';
            $email = $data['email'] ?? '';
            $password = $data['password'] ?? '';
            
            if (empty($username) || empty($email) || empty($password)) {
                mockError('用户名、邮箱和密码不能为空', 400);
            }
            
            // 检查用户名是否已存在
            foreach ($mockStorage['users'] as $user) {
                if ($user['username'] === $username || $user['email'] === $email) {
                    mockError('用户名或邮箱已存在', 400);
                }
            }
            
            $newUser = [
                'id' => count($mockStorage['users']) + 1,
                'username' => $username,
                'email' => $email,
                'full_name' => $data['full_name'] ?? '',
                'is_active' => true,
                'is_superuser' => false,
                'created_at' => date('c'),
                'last_login' => null,
                'roles' => [
                    ['id' => 3, 'name' => 'user', 'display_name' => '普通用户']
                ]
            ];
            
            $mockStorage['users'][] = $newUser;
            mockSuccess($newUser, '用户注册成功');
        }
        break;
        
    case '/auth/change-password':
        if ($method === 'POST') {
            $user = requireAuth();
            $oldPassword = $data['old_password'] ?? '';
            $newPassword = $data['new_password'] ?? '';
            
            if (empty($oldPassword) || empty($newPassword)) {
                mockError('旧密码和新密码不能为空', 400);
            }
            
            if (strlen($newPassword) < 8) {
                mockError('新密码长度至少8位', 400);
            }
            
            mockSuccess(['message' => '密码修改成功']);
        }
        break;
        
    // 用户管理端点
    case '/users':
        if ($method === 'GET') {
            $user = requireAuth();
            $page = $_GET['page'] ?? 1;
            $limit = $_GET['limit'] ?? 10;
            $search = $_GET['search'] ?? '';
            
            $users = $mockStorage['users'];
            
            // 模拟搜索
            if ($search) {
                $users = array_filter($users, function($u) use ($search) {
                    return stripos($u['username'], $search) !== false ||
                           stripos($u['email'], $search) !== false ||
                           stripos($u['full_name'], $search) !== false;
                });
            }
            
            $total = count($users);
            $offset = ($page - 1) * $limit;
            $users = array_slice($users, $offset, $limit);
            
            mockSuccess([
                'users' => $users,
                'total' => $total,
                'page' => $page,
                'limit' => $limit,
                'pages' => ceil($total / $limit)
            ]);
        } elseif ($method === 'POST') {
            $user = requireAuth();
            
            if (!$user['is_superuser']) {
                mockError('权限不足', 403);
            }
            
            $username = $data['username'] ?? '';
            $email = $data['email'] ?? '';
            $password = $data['password'] ?? '';
            
            if (empty($username) || empty($email) || empty($password)) {
                mockError('用户名、邮箱和密码不能为空', 400);
            }
            
            $newUser = [
                'id' => count($mockStorage['users']) + 1,
                'username' => $username,
                'email' => $email,
                'full_name' => $data['full_name'] ?? '',
                'is_active' => $data['is_active'] ?? true,
                'is_superuser' => $data['is_superuser'] ?? false,
                'created_at' => date('c'),
                'last_login' => null,
                'roles' => [
                    ['id' => 3, 'name' => 'user', 'display_name' => '普通用户']
                ]
            ];
            
            $mockStorage['users'][] = $newUser;
            mockSuccess($newUser, '用户创建成功');
        }
        break;
        
    // WireGuard服务器端点
    case '/wireguard/servers':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess($mockStorage['wireguard_servers']);
        } elseif ($method === 'POST') {
            $user = requireAuth();
            
            if (!$user['is_superuser'] && !in_array('wireguard.manage', ['wireguard.manage'])) {
                mockError('权限不足', 403);
            }
            
            $name = $data['name'] ?? '';
            $description = $data['description'] ?? '';
            $interface = $data['interface'] ?? 'wg0';
            $listenPort = $data['listen_port'] ?? 51820;
            $address = $data['address'] ?? '';
            
            if (empty($name) || empty($address)) {
                mockError('服务器名称和地址不能为空', 400);
            }
            
            $newServer = [
                'id' => count($mockStorage['wireguard_servers']) + 1,
                'name' => $name,
                'description' => $description,
                'interface' => $interface,
                'listen_port' => $listenPort,
                'address' => $address,
                'dns' => $data['dns'] ?? '8.8.8.8',
                'status' => 'inactive',
                'is_enabled' => true,
                'total_clients' => 0,
                'active_clients' => 0,
                'created_at' => date('c'),
                'created_by' => $user['sub']
            ];
            
            $mockStorage['wireguard_servers'][] = $newServer;
            mockSuccess($newServer, 'WireGuard服务器创建成功');
        }
        break;
        
    // BGP会话端点
    case '/bgp/sessions':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess($mockStorage['bgp_sessions']);
        } elseif ($method === 'POST') {
            $user = requireAuth();
            
            if (!$user['is_superuser'] && !in_array('bgp.manage', ['bgp.manage'])) {
                mockError('权限不足', 403);
            }
            
            $name = $data['name'] ?? '';
            $localAs = $data['local_as'] ?? 0;
            $remoteAs = $data['remote_as'] ?? 0;
            $localIp = $data['local_ip'] ?? '';
            $remoteIp = $data['remote_ip'] ?? '';
            
            if (empty($name) || $localAs <= 0 || $remoteAs <= 0 || empty($localIp) || empty($remoteIp)) {
                mockError('BGP会话信息不完整', 400);
            }
            
            $newSession = [
                'id' => count($mockStorage['bgp_sessions']) + 1,
                'name' => $name,
                'description' => $data['description'] ?? '',
                'local_as' => $localAs,
                'remote_as' => $remoteAs,
                'local_ip' => $localIp,
                'remote_ip' => $remoteIp,
                'hold_time' => $data['hold_time'] ?? 180,
                'keepalive_time' => $data['keepalive_time'] ?? 60,
                'status' => 'idle',
                'is_enabled' => true,
                'established_time' => null,
                'prefixes_received' => 0,
                'prefixes_sent' => 0,
                'created_at' => date('c'),
                'created_by' => $user['sub']
            ];
            
            $mockStorage['bgp_sessions'][] = $newSession;
            mockSuccess($newSession, 'BGP会话创建成功');
        }
        break;
        
    // IPv6前缀池端点
    case '/ipv6/pools':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess($mockStorage['ipv6_pools']);
        } elseif ($method === 'POST') {
            $user = requireAuth();
            
            if (!$user['is_superuser'] && !in_array('ipv6.manage', ['ipv6.manage'])) {
                mockError('权限不足', 403);
            }
            
            $name = $data['name'] ?? '';
            $prefix = $data['prefix'] ?? '';
            $prefixLength = $data['prefix_length'] ?? 0;
            
            if (empty($name) || empty($prefix) || $prefixLength <= 0) {
                mockError('IPv6前缀池信息不完整', 400);
            }
            
            $newPool = [
                'id' => count($mockStorage['ipv6_pools']) + 1,
                'name' => $name,
                'description' => $data['description'] ?? '',
                'prefix' => $prefix,
                'prefix_length' => $prefixLength,
                'total_addresses' => pow(2, 128 - $prefixLength),
                'allocated_addresses' => 0,
                'available_addresses' => pow(2, 128 - $prefixLength),
                'status' => 'active',
                'is_enabled' => true,
                'created_at' => date('c'),
                'created_by' => $user['sub']
            ];
            
            $mockStorage['ipv6_pools'][] = $newPool;
            mockSuccess($newPool, 'IPv6前缀池创建成功');
        }
        break;
        
    // 系统信息端点
    case '/system/info':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess([
                'hostname' => 'wireguard-server',
                'os' => 'Ubuntu 22.04 LTS',
                'kernel' => '5.15.0-91-generic',
                'uptime' => '15 days, 3 hours',
                'load_average' => [0.5, 0.8, 1.2],
                'memory' => [
                    'total' => '8GB',
                    'used' => '4.2GB',
                    'free' => '3.8GB',
                    'usage_percent' => 52.5
                ],
                'disk' => [
                    'total' => '100GB',
                    'used' => '45GB',
                    'free' => '55GB',
                    'usage_percent' => 45.0
                ],
                'cpu' => [
                    'cores' => 4,
                    'usage_percent' => 25.8
                ]
            ]);
        }
        break;
        
    case '/system/config':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess([
                'system_name' => 'IPv6 WireGuard Manager',
                'version' => '3.0.0',
                'timezone' => 'Asia/Shanghai',
                'language' => 'zh-CN',
                'debug_mode' => false,
                'log_level' => 'info',
                'api_version' => 'v1',
                'features' => [
                    'wireguard' => true,
                    'bgp' => true,
                    'ipv6' => true,
                    'monitoring' => true,
                    'user_management' => true
                ]
            ]);
        }
        break;
        
    case '/system/status':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess([
                'status' => 'healthy',
                'services' => [
                    'wireguard' => 'running',
                    'bgp' => 'running',
                    'database' => 'connected',
                    'redis' => 'disconnected'
                ],
                'uptime' => '15 days, 3 hours',
                'last_check' => date('c')
            ]);
        }
        break;
        
    // 监控端点
    case '/monitoring/dashboard':
        if ($method === 'GET') {
            $user = requireAuth();
            mockSuccess([
                'summary' => [
                    'total_servers' => 1,
                    'total_clients' => 5,
                    'active_clients' => 3,
                    'total_traffic' => '1.2TB',
                    'bgp_sessions' => 1,
                    'ipv6_pools' => 1
                ],
                'recent_activity' => [
                    [
                        'type' => 'client_connected',
                        'message' => '客户端 client1 已连接',
                        'timestamp' => '2024-01-15T10:25:00Z'
                    ],
                    [
                        'type' => 'bgp_session_established',
                        'message' => 'BGP会话 bgp-session-1 已建立',
                        'timestamp' => '2024-01-15T10:20:00Z'
                    ]
                ],
                'system_metrics' => [
                    'cpu_usage' => 25.8,
                    'memory_usage' => 52.5,
                    'disk_usage' => 45.0,
                    'network_in' => 1024000,
                    'network_out' => 2048000
                ]
            ]);
        }
        break;
        
    // 默认处理
    default:
        mockError('API端点不存在', 404);
        break;
}

// 如果没有匹配的路由，返回404
mockError('API端点不存在', 404);
?>
