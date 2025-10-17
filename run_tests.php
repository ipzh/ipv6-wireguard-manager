<?php
/**
 * 全面测试脚本
 */

echo "=== IPv6 WireGuard Manager 全面测试 ===\n\n";

// 引入测试环境
require_once 'php-frontend/config/config.php';
require_once 'php-frontend/config/database.php';
require_once 'php-frontend/classes/ApiClient.php';
require_once 'php-frontend/classes/Auth.php';
require_once 'php-frontend/classes/Router.php';
require_once 'php-frontend/classes/PermissionMiddleware.php';
require_once 'php-frontend/classes/SecurityHelper.php';
require_once 'php-frontend/classes/ErrorHandler.php';

// 测试结果统计
$testResults = [
    'total' => 0,
    'passed' => 0,
    'failed' => 0,
    'errors' => []
];

/**
 * 测试函数
 */
function runTest($testName, $testFunction) {
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
 * 测试类加载
 */
function testClassLoading() {
    $classes = [
        'ApiClient',
        'Auth',
        'Router',
        'PermissionMiddleware',
        'SecurityHelper',
        'ErrorHandler'
    ];
    
    foreach ($classes as $class) {
        if (!class_exists($class)) {
            throw new Exception("类 {$class} 不存在");
        }
    }
    
    return true;
}

/**
 * 测试Auth类
 */
function testAuthClass() {
    $auth = new Auth();
    
    // 测试会话管理
    if (!method_exists($auth, 'isLoggedIn')) {
        throw new Exception("Auth类缺少isLoggedIn方法");
    }
    
    if (!method_exists($auth, 'getCurrentUser')) {
        throw new Exception("Auth类缺少getCurrentUser方法");
    }
    
    if (!method_exists($auth, 'hasPermission')) {
        throw new Exception("Auth类缺少hasPermission方法");
    }
    
    return true;
}

/**
 * 测试ApiClient类
 */
function testApiClientClass() {
    $apiClient = new ApiClient();
    
    // 测试方法存在
    if (!method_exists($apiClient, 'get')) {
        throw new Exception("ApiClient类缺少get方法");
    }
    
    if (!method_exists($apiClient, 'post')) {
        throw new Exception("ApiClient类缺少post方法");
    }
    
    if (!method_exists($apiClient, 'put')) {
        throw new Exception("ApiClient类缺少put方法");
    }
    
    if (!method_exists($apiClient, 'delete')) {
        throw new Exception("ApiClient类缺少delete方法");
    }
    
    return true;
}

/**
 * 测试Router类
 */
function testRouterClass() {
    $router = new Router();
    
    // 测试路由添加
    $router->addRoute('GET', '/test', 'TestController@test');
    
    if (!method_exists($router, 'handleRequest')) {
        throw new Exception("Router类缺少handleRequest方法");
    }
    
    return true;
}

/**
 * 测试PermissionMiddleware类
 */
function testPermissionMiddlewareClass() {
    $middleware = new PermissionMiddleware();
    
    if (!method_exists($middleware, 'requireLogin')) {
        throw new Exception("PermissionMiddleware类缺少requireLogin方法");
    }
    
    if (!method_exists($middleware, 'requirePermission')) {
        throw new Exception("PermissionMiddleware类缺少requirePermission方法");
    }
    
    if (!method_exists($middleware, 'verifyCsrfToken')) {
        throw new Exception("PermissionMiddleware类缺少verifyCsrfToken方法");
    }
    
    return true;
}

/**
 * 测试ErrorHandler类
 */
function testErrorHandlerClass() {
    if (!method_exists('ErrorHandler', 'init')) {
        throw new Exception("ErrorHandler类缺少init方法");
    }
    
    if (!method_exists('ErrorHandler', 'logCustomError')) {
        throw new Exception("ErrorHandler类缺少logCustomError方法");
    }
    
    if (!method_exists('ErrorHandler', 'getErrorLogs')) {
        throw new Exception("ErrorHandler类缺少getErrorLogs方法");
    }
    
    return true;
}

/**
 * 测试权限系统
 */
function testPermissionSystem() {
    $auth = new Auth();
    
    // 设置测试用户
    $_SESSION['user'] = [
        'id' => 1,
        'username' => 'admin',
        'role' => 'admin',
        'is_superuser' => true
    ];
    
    // 测试管理员权限
    if (!$auth->hasPermission('wireguard.manage')) {
        throw new Exception("管理员权限检查失败");
    }
    
    // 测试操作员权限
    $_SESSION['user']['role'] = 'operator';
    $_SESSION['user']['is_superuser'] = false;
    
    if (!$auth->hasPermission('wireguard.view')) {
        throw new Exception("操作员权限检查失败");
    }
    
    if ($auth->hasPermission('users.manage')) {
        throw new Exception("操作员不应该有用户管理权限");
    }
    
    return true;
}

/**
 * 测试API模拟功能
 */
function testApiMock() {
    // 测试模拟API文件是否存在
    if (!file_exists('php-frontend/api_mock.php')) {
        throw new Exception("API模拟文件不存在");
    }
    
    // 测试模拟API内容
    $mockContent = file_get_contents('php-frontend/api_mock.php');
    if (strpos($mockContent, 'mockResponse') === false) {
        throw new Exception("API模拟文件内容不正确");
    }
    
    return true;
}

/**
 * 测试视图文件
 */
function testViewFiles() {
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
    }
    
    return true;
}

/**
 * 测试控制器文件
 */
function testControllerFiles() {
    $controllerFiles = [
        'php-frontend/controllers/AuthController.php',
        'php-frontend/controllers/DashboardController.php',
        'php-frontend/controllers/WireGuardController.php',
        'php-frontend/controllers/BGPController.php',
        'php-frontend/controllers/IPv6Controller.php',
        'php-frontend/controllers/MonitoringController.php',
        'php-frontend/controllers/LogsController.php',
        'php-frontend/controllers/UsersController.php',
        'php-frontend/controllers/ProfileController.php',
        'php-frontend/controllers/SystemController.php',
        'php-frontend/controllers/NetworkController.php',
        'php-frontend/controllers/ErrorController.php'
    ];
    
    foreach ($controllerFiles as $file) {
        if (!file_exists($file)) {
            throw new Exception("控制器文件不存在: {$file}");
        }
    }
    
    return true;
}

/**
 * 测试错误处理
 */
function testErrorHandling() {
    // 测试错误日志目录
    if (!is_dir('php-frontend/logs')) {
        throw new Exception("错误日志目录不存在");
    }
    
    if (!is_writable('php-frontend/logs')) {
        throw new Exception("错误日志目录不可写");
    }
    
    // 测试错误处理器初始化
    try {
        ErrorHandler::init();
    } catch (Exception $e) {
        throw new Exception("错误处理器初始化失败: " . $e->getMessage());
    }
    
    return true;
}

/**
 * 测试配置文件
 */
function testConfigFiles() {
    $configFiles = [
        'php-frontend/config/config.php',
        'php-frontend/config/database.php'
    ];
    
    foreach ($configFiles as $file) {
        if (!file_exists($file)) {
            throw new Exception("配置文件不存在: {$file}");
        }
        
        // 测试配置文件语法
        $content = file_get_contents($file);
        if (strpos($content, '<?php') === false) {
            throw new Exception("配置文件格式不正确: {$file}");
        }
    }
    
    return true;
}

/**
 * 测试路由配置
 */
function testRouteConfiguration() {
    $router = new Router();
    
    // 测试路由添加
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
 * 测试安全功能
 */
function testSecurityFeatures() {
    $securityHelper = new SecurityHelper();
    
    // 测试密码验证
    if (!method_exists($securityHelper, 'validatePassword')) {
        throw new Exception("SecurityHelper缺少密码验证方法");
    }
    
    // 测试输入清理
    if (!method_exists($securityHelper, 'sanitizeInput')) {
        throw new Exception("SecurityHelper缺少输入清理方法");
    }
    
    // 测试XSS防护
    if (!method_exists($securityHelper, 'preventXSS')) {
        throw new Exception("SecurityHelper缺少XSS防护方法");
    }
    
    return true;
}

// 运行所有测试
echo "开始运行测试...\n\n";

runTest("类加载测试", 'testClassLoading');
runTest("Auth类测试", 'testAuthClass');
runTest("ApiClient类测试", 'testApiClientClass');
runTest("Router类测试", 'testRouterClass');
runTest("PermissionMiddleware类测试", 'testPermissionMiddlewareClass');
runTest("ErrorHandler类测试", 'testErrorHandlerClass');
runTest("权限系统测试", 'testPermissionSystem');
runTest("API模拟功能测试", 'testApiMock');
runTest("视图文件测试", 'testViewFiles');
runTest("控制器文件测试", 'testControllerFiles');
runTest("错误处理测试", 'testErrorHandling');
runTest("配置文件测试", 'testConfigFiles');
runTest("路由配置测试", 'testRouteConfiguration');
runTest("安全功能测试", 'testSecurityFeatures');

// 输出测试结果
echo "\n=== 测试结果 ===\n";
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

// 生成测试报告
$report = [
    'timestamp' => date('Y-m-d H:i:s'),
    'total_tests' => $testResults['total'],
    'passed_tests' => $testResults['passed'],
    'failed_tests' => $testResults['failed'],
    'success_rate' => round(($testResults['passed'] / $testResults['total']) * 100, 2),
    'errors' => $testResults['errors']
];

if (file_put_contents('test_results/test_report.json', json_encode($report, JSON_PRETTY_PRINT))) {
    echo "✅ 测试报告已保存到 test_results/test_report.json\n";
} else {
    echo "❌ 测试报告保存失败\n";
}

if ($testResults['failed'] === 0) {
    echo "\n🎉 所有测试通过！系统准备就绪。\n";
    exit(0);
} else {
    echo "\n⚠️  有 {$testResults['failed']} 个测试失败，请检查错误信息。\n";
    exit(1);
}
?>
