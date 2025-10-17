<?php
/**
 * IPv6 WireGuard Manager - JWT认证PHP前端入口文件
 */

// 检查PHP版本
if (version_compare(PHP_VERSION, '8.1.0') < 0) {
    http_response_code(500);
    die('PHP版本过低，需要PHP 8.1.0或更高版本。当前版本: ' . PHP_VERSION);
}

// 检查必需扩展
$requiredExtensions = [
    'session' => '会话管理',
    'json' => 'JSON处理',
    'mbstring' => '多字节字符串处理',
    'filter' => '数据过滤',
    'curl' => 'HTTP客户端',
    'openssl' => '加密支持'
];

$missingExtensions = [];
foreach ($requiredExtensions as $ext => $description) {
    if (!extension_loaded($ext)) {
        $missingExtensions[] = "$ext ($description)";
    }
}

if (!empty($missingExtensions)) {
    http_response_code(500);
    die('缺少必需的PHP扩展: ' . implode(', ', $missingExtensions));
}

// 检查PHP配置
$requiredSettings = [
    'memory_limit' => '128M',
    'max_execution_time' => '300',
    'upload_max_filesize' => '10M',
    'post_max_size' => '10M'
];

$configIssues = [];
foreach ($requiredSettings as $setting => $recommended) {
    $current = ini_get($setting);
    if ($setting === 'memory_limit' && $current !== '-1' && intval($current) < intval($recommended)) {
        $configIssues[] = "$setting 当前值: $current, 推荐值: $recommended";
    }
}

if (!empty($configIssues)) {
    error_log('PHP配置警告: ' . implode(', ', $configIssues));
}

// 设置错误报告级别
error_reporting(E_ALL);
ini_set('display_errors', 0); // 生产环境不显示错误
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/logs/php_errors.log');

// 设置时区
date_default_timezone_set('Asia/Shanghai');

// 会话将在SecurityEnhancer中安全启动

// 设置安全头
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');

// 定义常量
define('APP_ROOT', __DIR__);
define('APP_VERSION', '3.0.0');
define('APP_NAME', 'IPv6 WireGuard Manager');
define('DEBUG', isset($_GET['debug']) && $_GET['debug'] === '1');

// 引入配置
require_once 'config/config.php';
require_once 'config/database.php';
require_once 'config/assets.php';
require_once 'config/api_endpoints.php';

// 引入核心类
require_once 'classes/ApiClientJWT.php';
require_once 'classes/AuthJWT.php';
require_once 'classes/Router.php';
require_once 'classes/PermissionMiddleware.php';
require_once 'classes/SecurityHelper.php';
require_once 'classes/ErrorHandlerJWT.php';
require_once 'classes/InputValidatorJWT.php';
require_once 'classes/ResponseHandler.php';
require_once 'classes/SecurityEnhancer.php';

// 初始化错误处理器
$errorHandler = ErrorHandlerJWT::getInstance();

// 初始化认证系统
$auth = new AuthJWT();

// 检查会话安全性
if (!$auth->checkSessionSecurity()) {
    $auth->logout();
    header('Location: /login');
    exit;
}

// 更新用户最后活动时间
$auth->updateLastActivity();

// 检查会话是否空闲
if ($auth->isSessionIdle()) {
    $auth->logout();
    header('Location: /login?reason=idle');
    exit;
}

// 初始化路由器
$router = new Router();

// 定义路由
$router->addRoute('GET', '/', 'DashboardController@index');
$router->addRoute('GET', '/dashboard', 'DashboardController@index');
$router->addRoute('GET', '/login', 'AuthController@showLogin');
$router->addRoute('POST', '/login', 'AuthController@login');
$router->addRoute('GET', '/logout', 'AuthController@logout');
$router->addRoute('POST', '/logout', 'AuthController@logout');
$router->addRoute('GET', '/register', 'AuthController@showRegister');
$router->addRoute('POST', '/register', 'AuthController@register');

// 用户管理路由
$router->addRoute('GET', '/users', 'UsersController@index');
$router->addRoute('GET', '/users/create', 'UsersController@create');
$router->addRoute('POST', '/users', 'UsersController@store');
$router->addRoute('GET', '/users/{id}', 'UsersController@show');
$router->addRoute('GET', '/users/{id}/edit', 'UsersController@edit');
$router->addRoute('PUT', '/users/{id}', 'UsersController@update');
$router->addRoute('DELETE', '/users/{id}', 'UsersController@destroy');
$router->addRoute('POST', '/users/{id}/lock', 'UsersController@lock');
$router->addRoute('POST', '/users/{id}/unlock', 'UsersController@unlock');

// 个人资料路由
$router->addRoute('GET', '/profile', 'ProfileController@index');
$router->addRoute('PUT', '/profile', 'ProfileController@update');
$router->addRoute('POST', '/profile/change-password', 'ProfileController@changePassword');

// WireGuard管理路由
$router->addRoute('GET', '/wireguard/servers', 'WireGuardController@servers');
$router->addRoute('GET', '/wireguard/servers/create', 'WireGuardController@createServer');
$router->addRoute('POST', '/wireguard/servers', 'WireGuardController@storeServer');
$router->addRoute('GET', '/wireguard/servers/{id}', 'WireGuardController@showServer');
$router->addRoute('GET', '/wireguard/servers/{id}/edit', 'WireGuardController@editServer');
$router->addRoute('PUT', '/wireguard/servers/{id}', 'WireGuardController@updateServer');
$router->addRoute('DELETE', '/wireguard/servers/{id}', 'WireGuardController@destroyServer');
$router->addRoute('POST', '/wireguard/servers/{id}/start', 'WireGuardController@startServer');
$router->addRoute('POST', '/wireguard/servers/{id}/stop', 'WireGuardController@stopServer');
$router->addRoute('POST', '/wireguard/servers/{id}/restart', 'WireGuardController@restartServer');

$router->addRoute('GET', '/wireguard/clients', 'WireGuardController@clients');
$router->addRoute('GET', '/wireguard/clients/create', 'WireGuardController@createClient');
$router->addRoute('POST', '/wireguard/clients', 'WireGuardController@storeClient');
$router->addRoute('GET', '/wireguard/clients/{id}', 'WireGuardController@showClient');
$router->addRoute('GET', '/wireguard/clients/{id}/edit', 'WireGuardController@editClient');
$router->addRoute('PUT', '/wireguard/clients/{id}', 'WireGuardController@updateClient');
$router->addRoute('DELETE', '/wireguard/clients/{id}', 'WireGuardController@destroyClient');
$router->addRoute('GET', '/wireguard/clients/{id}/config', 'WireGuardController@downloadConfig');
$router->addRoute('GET', '/wireguard/clients/{id}/qr', 'WireGuardController@showQR');

// BGP管理路由
$router->addRoute('GET', '/bgp/sessions', 'BGPController@sessions');
$router->addRoute('GET', '/bgp/sessions/create', 'BGPController@createSession');
$router->addRoute('POST', '/bgp/sessions', 'BGPController@storeSession');
$router->addRoute('GET', '/bgp/sessions/{id}', 'BGPController@showSession');
$router->addRoute('GET', '/bgp/sessions/{id}/edit', 'BGPController@editSession');
$router->addRoute('PUT', '/bgp/sessions/{id}', 'BGPController@updateSession');
$router->addRoute('DELETE', '/bgp/sessions/{id}', 'BGPController@destroySession');
$router->addRoute('POST', '/bgp/sessions/{id}/start', 'BGPController@startSession');
$router->addRoute('POST', '/bgp/sessions/{id}/stop', 'BGPController@stopSession');

$router->addRoute('GET', '/bgp/announcements', 'BGPController@announcements');
$router->addRoute('GET', '/bgp/announcements/create', 'BGPController@createAnnouncement');
$router->addRoute('POST', '/bgp/announcements', 'BGPController@storeAnnouncement');
$router->addRoute('GET', '/bgp/announcements/{id}', 'BGPController@showAnnouncement');
$router->addRoute('GET', '/bgp/announcements/{id}/edit', 'BGPController@editAnnouncement');
$router->addRoute('PUT', '/bgp/announcements/{id}', 'BGPController@updateAnnouncement');
$router->addRoute('DELETE', '/bgp/announcements/{id}', 'BGPController@destroyAnnouncement');

// IPv6管理路由
$router->addRoute('GET', '/ipv6/pools', 'IPv6Controller@pools');
$router->addRoute('GET', '/ipv6/pools/create', 'IPv6Controller@createPool');
$router->addRoute('POST', '/ipv6/pools', 'IPv6Controller@storePool');
$router->addRoute('GET', '/ipv6/pools/{id}', 'IPv6Controller@showPool');
$router->addRoute('GET', '/ipv6/pools/{id}/edit', 'IPv6Controller@editPool');
$router->addRoute('PUT', '/ipv6/pools/{id}', 'IPv6Controller@updatePool');
$router->addRoute('DELETE', '/ipv6/pools/{id}', 'IPv6Controller@destroyPool');

$router->addRoute('GET', '/ipv6/allocations', 'IPv6Controller@allocations');
$router->addRoute('GET', '/ipv6/allocations/create', 'IPv6Controller@createAllocation');
$router->addRoute('POST', '/ipv6/allocations', 'IPv6Controller@storeAllocation');
$router->addRoute('GET', '/ipv6/allocations/{id}', 'IPv6Controller@showAllocation');
$router->addRoute('GET', '/ipv6/allocations/{id}/edit', 'IPv6Controller@editAllocation');
$router->addRoute('PUT', '/ipv6/allocations/{id}', 'IPv6Controller@updateAllocation');
$router->addRoute('DELETE', '/ipv6/allocations/{id}', 'IPv6Controller@destroyAllocation');

// 系统管理路由
$router->addRoute('GET', '/system/info', 'SystemController@info');
$router->addRoute('GET', '/system/config', 'SystemController@config');
$router->addRoute('GET', '/system/status', 'SystemController@status');
$router->addRoute('GET', '/system/logs', 'SystemController@logs');
$router->addRoute('POST', '/system/backup', 'SystemController@backup');
$router->addRoute('POST', '/system/restore', 'SystemController@restore');

// 监控路由
$router->addRoute('GET', '/monitoring/dashboard', 'MonitoringController@dashboard');
$router->addRoute('GET', '/monitoring/metrics', 'MonitoringController@metrics');
$router->addRoute('GET', '/monitoring/alerts', 'MonitoringController@alerts');
$router->addRoute('GET', '/monitoring/graphs', 'MonitoringController@graphs');
$router->addRoute('GET', '/monitoring/reports', 'MonitoringController@reports');

// 网络管理路由
$router->addRoute('GET', '/network/interfaces', 'NetworkController@interfaces');
$router->addRoute('GET', '/network/interfaces/{id}', 'NetworkController@showInterface');
$router->addRoute('PUT', '/network/interfaces/{id}', 'NetworkController@updateInterface');
$router->addRoute('GET', '/network/routes', 'NetworkController@routes');
$router->addRoute('POST', '/network/routes', 'NetworkController@createRoute');
$router->addRoute('DELETE', '/network/routes/{id}', 'NetworkController@deleteRoute');

// 错误处理路由
$router->addRoute('GET', '/error', 'ErrorController@index');
$router->addRoute('GET', '/error/{code}', 'ErrorController@show');

// API路由
$router->addRoute('GET', '/api/status', 'ApiController@status');
$router->addRoute('GET', '/api/health', 'ApiController@health');
$router->addRoute('POST', '/api/upload', 'ApiController@upload');

// 处理请求
try {
    $router->handleRequest();
} catch (Exception $e) {
    $errorHandler->handleException($e);
}
?>
