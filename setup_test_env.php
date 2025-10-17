<?php
/**
 * 本地测试环境设置脚本
 */

echo "=== IPv6 WireGuard Manager 本地测试环境设置 ===\n\n";

// 检查PHP版本
echo "1. 检查PHP环境...\n";
echo "PHP版本: " . PHP_VERSION . "\n";

if (version_compare(PHP_VERSION, '8.1.0') < 0) {
    echo "❌ PHP版本过低，需要PHP 8.1.0或更高版本\n";
    exit(1);
}
echo "✅ PHP版本检查通过\n\n";

// 检查必需扩展
echo "2. 检查PHP扩展...\n";
$requiredExtensions = [
    'session' => '会话管理',
    'json' => 'JSON处理',
    'mbstring' => '多字节字符串处理',
    'filter' => '数据过滤',
    'pdo' => '数据库连接',
    'curl' => 'HTTP客户端',
    'openssl' => '加密支持'
];

$missingExtensions = [];
foreach ($requiredExtensions as $ext => $description) {
    if (extension_loaded($ext)) {
        echo "✅ {$ext} - {$description}\n";
    } else {
        echo "❌ {$ext} - {$description} (缺失)\n";
        $missingExtensions[] = $ext;
    }
}

if (!empty($missingExtensions)) {
    echo "\n❌ 缺少必需的PHP扩展: " . implode(', ', $missingExtensions) . "\n";
    echo "请安装缺少的扩展后重试\n";
    exit(1);
}
echo "\n✅ 所有必需扩展检查通过\n\n";

// 创建必要的目录
echo "3. 创建必要的目录...\n";
$directories = [
    'php-frontend/logs',
    'php-frontend/cache',
    'php-frontend/backups',
    'test_results',
    'test_data'
];

foreach ($directories as $dir) {
    if (!is_dir($dir)) {
        if (mkdir($dir, 0755, true)) {
            echo "✅ 创建目录: {$dir}\n";
        } else {
            echo "❌ 创建目录失败: {$dir}\n";
        }
    } else {
        echo "✅ 目录已存在: {$dir}\n";
    }
}
echo "\n";

// 设置文件权限
echo "4. 设置文件权限...\n";
$writableDirs = [
    'php-frontend/logs',
    'php-frontend/cache',
    'php-frontend/backups'
];

foreach ($writableDirs as $dir) {
    if (is_dir($dir)) {
        if (is_writable($dir)) {
            echo "✅ 目录可写: {$dir}\n";
        } else {
            echo "⚠️  目录不可写: {$dir}\n";
        }
    }
}
echo "\n";

// 检查配置文件
echo "5. 检查配置文件...\n";
$configFiles = [
    'php-frontend/config/config.php',
    'php-frontend/config/database.php'
];

foreach ($configFiles as $file) {
    if (file_exists($file)) {
        echo "✅ 配置文件存在: {$file}\n";
    } else {
        echo "❌ 配置文件缺失: {$file}\n";
    }
}
echo "\n";

// 创建测试配置
echo "6. 创建测试配置...\n";
$testConfig = '<?php
// 测试环境配置
define("API_BASE_URL", "http://localhost:8000/api/v1");
define("SESSION_LIFETIME", 3600);
define("APP_DEBUG", true);
define("LOG_LEVEL", "debug");

// 测试数据库配置
define("DB_HOST", "localhost");
define("DB_NAME", "ipv6_wireguard_test");
define("DB_USER", "root");
define("DB_PASS", "");
define("DB_CHARSET", "utf8mb4");
?>';

if (file_put_contents('php-frontend/config/test_config.php', $testConfig)) {
    echo "✅ 创建测试配置文件\n";
} else {
    echo "❌ 创建测试配置文件失败\n";
}
echo "\n";

// 创建测试用户会话
echo "7. 创建测试用户会话...\n";
session_start();

// 创建测试用户数据
$testUsers = [
    'admin' => [
        'id' => 1,
        'username' => 'admin',
        'email' => 'admin@test.com',
        'role' => 'admin',
        'is_superuser' => true,
        'permissions' => ['*']
    ],
    'operator' => [
        'id' => 2,
        'username' => 'operator',
        'email' => 'operator@test.com',
        'role' => 'operator',
        'is_superuser' => false,
        'permissions' => [
            'wireguard.manage',
            'wireguard.view',
            'bgp.manage',
            'bgp.view',
            'ipv6.manage',
            'ipv6.view',
            'monitoring.view',
            'logs.view',
            'system.view',
            'users.view'
        ]
    ],
    'user' => [
        'id' => 3,
        'username' => 'user',
        'email' => 'user@test.com',
        'role' => 'user',
        'is_superuser' => false,
        'permissions' => [
            'wireguard.view',
            'monitoring.view'
        ]
    ]
];

// 保存测试用户数据
if (file_put_contents('test_data/test_users.json', json_encode($testUsers, JSON_PRETTY_PRINT))) {
    echo "✅ 创建测试用户数据\n";
} else {
    echo "❌ 创建测试用户数据失败\n";
}

// 设置默认测试用户
$_SESSION['user'] = $testUsers['admin'];
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));
echo "✅ 设置默认测试用户: admin\n";
echo "\n";

// 创建简单的Web服务器启动脚本
echo "8. 创建Web服务器启动脚本...\n";
$serverScript = '<?php
// 简单的PHP内置服务器启动脚本
$host = "localhost";
$port = 8080;
$root = __DIR__ . "/php-frontend";

echo "启动IPv6 WireGuard Manager测试服务器...\n";
echo "访问地址: http://{$host}:{$port}\n";
echo "按 Ctrl+C 停止服务器\n\n";

$command = "php -S {$host}:{$port} -t {$root}";
system($command);
?>';

if (file_put_contents('start_test_server.php', $serverScript)) {
    echo "✅ 创建服务器启动脚本\n";
} else {
    echo "❌ 创建服务器启动脚本失败\n";
}
echo "\n";

// 创建测试数据
echo "9. 创建测试数据...\n";
$testData = [
    'wireguard_servers' => [
        [
            'id' => 1,
            'name' => 'wg0',
            'interface' => 'wg0',
            'port' => 51820,
            'status' => 'running',
            'clients_count' => 3,
            'created_at' => '2024-01-01T00:00:00Z'
        ],
        [
            'id' => 2,
            'name' => 'wg1',
            'interface' => 'wg1',
            'port' => 51821,
            'status' => 'stopped',
            'clients_count' => 0,
            'created_at' => '2024-01-02T00:00:00Z'
        ]
    ],
    'wireguard_clients' => [
        [
            'id' => 1,
            'name' => 'client1',
            'public_key' => 'ABC123...',
            'allowed_ips' => '10.0.0.2/32',
            'server_id' => 1,
            'status' => 'active',
            'last_seen' => '2024-01-15T10:30:00Z'
        ],
        [
            'id' => 2,
            'name' => 'client2',
            'public_key' => 'DEF456...',
            'allowed_ips' => '10.0.0.3/32',
            'server_id' => 1,
            'status' => 'inactive',
            'last_seen' => '2024-01-14T15:20:00Z'
        ]
    ],
    'bgp_sessions' => [
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
    ],
    'ipv6_pools' => [
        [
            'id' => 1,
            'name' => 'main-pool',
            'prefix' => '2001:db8::/48',
            'allocated' => '2001:db8::/64',
            'available' => '2001:db8:1::/64',
            'usage_percent' => 25.5
        ]
    ]
];

if (file_put_contents('test_data/test_data.json', json_encode($testData, JSON_PRETTY_PRINT))) {
    echo "✅ 创建测试数据\n";
} else {
    echo "❌ 创建测试数据失败\n";
}
echo "\n";

echo "=== 测试环境设置完成 ===\n\n";
echo "下一步操作:\n";
echo "1. 运行测试: php run_tests.php\n";
echo "2. 启动服务器: php start_test_server.php\n";
echo "3. 访问测试: http://localhost:8080\n\n";
?>
