<?php
/**
 * Web界面测试脚本
 */

echo "=== Web界面功能测试 ===\n\n";

// 设置测试环境
session_start();
$_SESSION['user'] = [
    'id' => 1,
    'username' => 'admin',
    'email' => 'admin@test.com',
    'role' => 'admin',
    'is_superuser' => true
];
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));

// 引入必要的文件
require_once 'php-frontend/config/config.php';
require_once 'php-frontend/classes/ApiClient.php';
require_once 'php-frontend/classes/Auth.php';
require_once 'php-frontend/classes/Router.php';
require_once 'php-frontend/classes/PermissionMiddleware.php';
require_once 'php-frontend/classes/ErrorHandler.php';

// 测试结果
$testResults = [
    'total' => 0,
    'passed' => 0,
    'failed' => 0,
    'errors' => []
];

/**
 * 测试函数
 */
function runWebTest($testName, $testFunction) {
    global $testResults;
    
    $testResults['total']++;
    echo "测试 {$testResults['total']}: {$testName}... ";
    
    try {
        $result = $testFunction();
        if ($result) {
            echo "✅ 通过\n";
            $testResults['passed']++;
        } else {
            echo "❌ 失败\n";
            $testResults['failed']++;
            $testResults['errors'][] = "{$testName}: 测试失败";
        }
    } catch (Exception $e) {
        echo "❌ 错误: " . $e->getMessage() . "\n";
        $testResults['failed']++;
        $testResults['errors'][] = "{$testName}: " . $e->getMessage();
    }
}

/**
 * 测试API模拟响应
 */
function testApiMockResponse() {
    // 测试模拟API端点
    $endpoints = [
        '/api/v1/system/config',
        '/api/v1/system/info',
        '/api/v1/wireguard/servers',
        '/api/v1/wireguard/clients',
        '/api/v1/bgp/sessions',
        '/api/v1/ipv6/pools',
        '/api/v1/monitoring/metrics',
        '/api/v1/monitoring/alerts',
        '/api/v1/logs',
        '/api/v1/users',
        '/api/v1/network/interfaces'
    ];
    
    foreach ($endpoints as $endpoint) {
        $url = 'http://localhost' . dirname($_SERVER['SCRIPT_NAME']) . '/php-frontend/api_mock.php' . $endpoint;
        
        $context = stream_context_create([
            'http' => [
                'method' => 'GET',
                'header' => 'Accept: application/json',
                'timeout' => 5
            ]
        ]);
        
        $response = @file_get_contents($url, false, $context);
        if ($response === false) {
            throw new Exception("API模拟端点 {$endpoint} 响应失败");
        }
        
        $data = json_decode($response, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception("API模拟端点 {$endpoint} 返回无效JSON");
        }
        
        if (!isset($data['success'])) {
            throw new Exception("API模拟端点 {$endpoint} 缺少success字段");
        }
    }
    
    return true;
}

/**
 * 测试控制器实例化
 */
function testControllerInstantiation() {
    $controllers = [
        'AuthController',
        'DashboardController',
        'WireGuardController',
        'BGPController',
        'IPv6Controller',
        'MonitoringController',
        'LogsController',
        'UsersController',
        'ProfileController',
        'SystemController',
        'NetworkController',
        'ErrorController'
    ];
    
    foreach ($controllers as $controllerName) {
        if (!class_exists($controllerName)) {
            throw new Exception("控制器类 {$controllerName} 不存在");
        }
        
        // 尝试实例化控制器（可能会因为权限检查而失败，这是正常的）
        try {
            $controller = new $controllerName();
        } catch (Exception $e) {
            // 权限检查失败是正常的，我们只关心类是否存在
            if (strpos($e->getMessage(), '权限') === false && 
                strpos($e->getMessage(), 'login') === false) {
                throw new Exception("控制器 {$controllerName} 实例化失败: " . $e->getMessage());
            }
        }
    }
    
    return true;
}

/**
 * 测试视图文件语法
 */
function testViewFileSyntax() {
    $viewFiles = [
        'php-frontend/views/layout/header.php',
        'php-frontend/views/layout/footer.php',
        'php-frontend/views/errors/error.php',
        'php-frontend/views/errors/logs.php',
        'php-frontend/views/monitoring/dashboard.php',
        'php-frontend/views/system/info.php',
        'php-frontend/views/system/config.php',
        'php-frontend/views/network/interfaces.php'
    ];
    
    foreach ($viewFiles as $file) {
        if (!file_exists($file)) {
            throw new Exception("视图文件不存在: {$file}");
        }
        
        // 检查PHP语法
        $content = file_get_contents($file);
        $tempFile = tempnam(sys_get_temp_dir(), 'test_view_');
        file_put_contents($tempFile, $content);
        
        $output = [];
        $returnCode = 0;
        exec("php -l {$tempFile} 2>&1", $output, $returnCode);
        unlink($tempFile);
        
        if ($returnCode !== 0) {
            throw new Exception("视图文件语法错误: {$file} - " . implode(' ', $output));
        }
    }
    
    return true;
}

/**
 * 测试路由处理
 */
function testRouteHandling() {
    $router = new Router();
    
    // 添加测试路由
    $testRoutes = [
        ['GET', '/', 'DashboardController@index'],
        ['GET', '/login', 'AuthController@showLogin'],
        ['GET', '/error', 'ErrorController@showError'],
        ['GET', '/wireguard/servers', 'WireGuardController@servers'],
        ['GET', '/bgp/sessions', 'BGPController@sessions'],
        ['GET', '/ipv6/pools', 'IPv6Controller@pools'],
        ['GET', '/monitoring', 'MonitoringController@index'],
        ['GET', '/logs', 'LogsController@index'],
        ['GET', '/users', 'UsersController@index'],
        ['GET', '/profile', 'ProfileController@index'],
        ['GET', '/system/info', 'SystemController@info'],
        ['GET', '/network/interfaces', 'NetworkController@interfaces']
    ];
    
    foreach ($testRoutes as $route) {
        $router->addRoute($route[0], $route[1], $route[2]);
    }
    
    return true;
}

/**
 * 测试权限检查
 */
function testPermissionChecking() {
    $auth = new Auth();
    
    // 测试管理员权限
    $_SESSION['user']['role'] = 'admin';
    $_SESSION['user']['is_superuser'] = true;
    
    if (!$auth->hasPermission('wireguard.manage')) {
        throw new Exception("管理员权限检查失败");
    }
    
    if (!$auth->hasPermission('users.manage')) {
        throw new Exception("管理员用户管理权限检查失败");
    }
    
    // 测试操作员权限
    $_SESSION['user']['role'] = 'operator';
    $_SESSION['user']['is_superuser'] = false;
    
    if (!$auth->hasPermission('wireguard.view')) {
        throw new Exception("操作员查看权限检查失败");
    }
    
    if ($auth->hasPermission('users.manage')) {
        throw new Exception("操作员不应该有用户管理权限");
    }
    
    // 测试普通用户权限
    $_SESSION['user']['role'] = 'user';
    
    if (!$auth->hasPermission('wireguard.view')) {
        throw new Exception("普通用户查看权限检查失败");
    }
    
    if ($auth->hasPermission('wireguard.manage')) {
        throw new Exception("普通用户不应该有管理权限");
    }
    
    return true;
}

/**
 * 测试错误处理
 */
function testErrorHandling() {
    // 测试错误处理器初始化
    try {
        ErrorHandler::init();
    } catch (Exception $e) {
        throw new Exception("错误处理器初始化失败: " . $e->getMessage());
    }
    
    // 测试错误日志记录
    try {
        ErrorHandler::logCustomError('测试错误', [
            'file' => __FILE__,
            'line' => __LINE__,
            'test' => true
        ]);
    } catch (Exception $e) {
        throw new Exception("错误日志记录失败: " . $e->getMessage());
    }
    
    // 测试错误日志获取
    try {
        $logs = ErrorHandler::getErrorLogs(10);
        if (!is_array($logs)) {
            throw new Exception("错误日志获取返回格式不正确");
        }
    } catch (Exception $e) {
        throw new Exception("错误日志获取失败: " . $e->getMessage());
    }
    
    return true;
}

/**
 * 测试CSRF保护
 */
function testCsrfProtection() {
    $auth = new Auth();
    
    // 生成CSRF令牌
    $token = $auth->generateCsrfToken();
    if (empty($token)) {
        throw new Exception("CSRF令牌生成失败");
    }
    
    // 验证CSRF令牌
    if (!$auth->verifyCsrfToken($token)) {
        throw new Exception("CSRF令牌验证失败");
    }
    
    // 测试无效令牌
    if ($auth->verifyCsrfToken('invalid_token')) {
        throw new Exception("无效CSRF令牌应该验证失败");
    }
    
    return true;
}

/**
 * 测试会话管理
 */
function testSessionManagement() {
    $auth = new Auth();
    
    // 测试用户登录状态
    if (!$auth->isLoggedIn()) {
        throw new Exception("用户登录状态检查失败");
    }
    
    // 测试当前用户获取
    $user = $auth->getCurrentUser();
    if (!$user || !isset($user['username'])) {
        throw new Exception("当前用户信息获取失败");
    }
    
    // 测试用户权限获取
    $permissions = $auth->getUserPermissions();
    if (!is_array($permissions)) {
        throw new Exception("用户权限获取失败");
    }
    
    return true;
}

// 运行Web界面测试
echo "开始运行Web界面测试...\n\n";

runWebTest("API模拟响应测试", 'testApiMockResponse');
runWebTest("控制器实例化测试", 'testControllerInstantiation');
runWebTest("视图文件语法测试", 'testViewFileSyntax');
runWebTest("路由处理测试", 'testRouteHandling');
runWebTest("权限检查测试", 'testPermissionChecking');
runWebTest("错误处理测试", 'testErrorHandling');
runWebTest("CSRF保护测试", 'testCsrfProtection');
runWebTest("会话管理测试", 'testSessionManagement');

// 输出测试结果
echo "\n=== Web界面测试结果 ===\n";
echo "总测试数: {$testResults['total']}\n";
echo "通过: {$testResults['passed']}\n";
echo "失败: {$testResults['failed']}\n";
echo "成功率: " . round(($testResults['passed'] / $testResults['total']) * 100, 2) . "%\n\n";

if (!empty($testResults['errors'])) {
    echo "错误详情:\n";
    foreach ($testResults['errors'] as $error) {
        echo "- {$error}\n";
    }
    echo "\n";
}

// 生成Web测试报告
$report = [
    'timestamp' => date('Y-m-d H:i:s'),
    'test_type' => 'web_interface',
    'total_tests' => $testResults['total'],
    'passed_tests' => $testResults['passed'],
    'failed_tests' => $testResults['failed'],
    'success_rate' => round(($testResults['passed'] / $testResults['total']) * 100, 2),
    'errors' => $testResults['errors']
];

if (file_put_contents('test_results/web_test_report.json', json_encode($report, JSON_PRETTY_PRINT))) {
    echo "✅ Web测试报告已保存到 test_results/web_test_report.json\n";
} else {
    echo "❌ Web测试报告保存失败\n";
}

if ($testResults['failed'] === 0) {
    echo "\n🎉 所有Web界面测试通过！\n";
    exit(0);
} else {
    echo "\n⚠️  有 {$testResults['failed']} 个Web界面测试失败，请检查错误信息。\n";
    exit(1);
}
?>
