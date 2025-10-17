<?php
/**
 * IPv6 WireGuard Manager - PHP前端入口文件
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
    'pdo' => '数据库连接',
    'pdo_mysql' => 'MySQL数据库支持',
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

// 启动会话
session_start();

// 引入配置
require_once 'config/config.php';
require_once 'config/database.php';

// 引入核心类
require_once 'classes/ApiClient.php';
require_once 'classes/Auth.php';
require_once 'classes/Router.php';
require_once 'classes/PermissionMiddleware.php';
require_once 'classes/SecurityHelper.php';

// 引入控制器
require_once 'controllers/AuthController.php';
require_once 'controllers/DashboardController.php';
require_once 'controllers/WireGuardController.php';
require_once 'controllers/BGPController.php';
require_once 'controllers/IPv6Controller.php';
require_once 'controllers/MonitoringController.php';
require_once 'controllers/LogsController.php';
require_once 'controllers/UsersController.php';
require_once 'controllers/ProfileController.php';
require_once 'controllers/SystemController.php';
require_once 'controllers/NetworkController.php';
require_once 'controllers/ErrorController.php';

// 初始化路由
$router = new Router();

// 定义路由
$router->addRoute('GET', '/', 'DashboardController@index');
$router->addRoute('GET', '/dashboard/realtime', 'DashboardController@getRealtimeData');
$router->addRoute('GET', '/login', 'AuthController@showLogin');
$router->addRoute('POST', '/login', 'AuthController@login');
$router->addRoute('GET', '/logout', 'AuthController@logout');

// API代理路由
$router->addRoute('GET', '/api/health', 'AuthController@checkApiStatus');
$router->addRoute('GET', '/api/status', 'AuthController@checkApiStatus');

// 错误页面路由
$router->addRoute('GET', '/error', 'ErrorController@showError');

// WireGuard管理
$router->addRoute('GET', '/wireguard/servers', 'WireGuardController@servers');
$router->addRoute('GET', '/wireguard/clients', 'WireGuardController@clients');
$router->addRoute('POST', '/wireguard/servers', 'WireGuardController@createServer');
$router->addRoute('POST', '/wireguard/clients', 'WireGuardController@createClient');
$router->addRoute('GET', '/wireguard/servers/{id}', 'WireGuardController@getServer');
$router->addRoute('GET', '/wireguard/clients/{id}', 'WireGuardController@getClient');
$router->addRoute('POST', '/wireguard/servers/{id}/update', 'WireGuardController@updateServer');
$router->addRoute('POST', '/wireguard/clients/{id}/update', 'WireGuardController@updateClient');
$router->addRoute('GET', '/wireguard/servers/{id}/delete', 'WireGuardController@deleteServer');
$router->addRoute('GET', '/wireguard/clients/{id}/delete', 'WireGuardController@deleteClient');
$router->addRoute('GET', '/wireguard/servers/{id}/start', 'WireGuardController@startServer');
$router->addRoute('GET', '/wireguard/servers/{id}/stop', 'WireGuardController@stopServer');
$router->addRoute('GET', '/wireguard/servers/{id}/export', 'WireGuardController@exportConfig');
$router->addRoute('GET', '/wireguard/clients/{id}/export', 'WireGuardController@exportConfig');

// BGP管理
$router->addRoute('GET', '/bgp/sessions', 'BGPController@sessions');
$router->addRoute('POST', '/bgp/sessions', 'BGPController@createSession');
$router->addRoute('GET', '/bgp/sessions/create', 'BGPController@createSession');
$router->addRoute('GET', '/bgp/sessions/{id}/edit', 'BGPController@editSession');
$router->addRoute('POST', '/bgp/sessions/{id}/edit', 'BGPController@editSession');
$router->addRoute('GET', '/bgp/sessions/{id}/delete', 'BGPController@deleteSession');
$router->addRoute('GET', '/bgp/sessions/{id}/start', 'BGPController@startSession');
$router->addRoute('GET', '/bgp/sessions/{id}/stop', 'BGPController@stopSession');
$router->addRoute('GET', '/bgp/announcements', 'BGPController@announcements');
$router->addRoute('POST', '/bgp/announcements', 'BGPController@createAnnouncement');
$router->addRoute('GET', '/bgp/announcements/create', 'BGPController@createAnnouncement');
$router->addRoute('GET', '/bgp/announcements/{id}/edit', 'BGPController@editAnnouncement');
$router->addRoute('POST', '/bgp/announcements/{id}/edit', 'BGPController@editAnnouncement');
$router->addRoute('GET', '/bgp/announcements/{id}/delete', 'BGPController@deleteAnnouncement');
$router->addRoute('GET', '/bgp/status', 'BGPController@status');

// IPv6管理
$router->addRoute('GET', '/ipv6/pools', 'IPv6Controller@pools');
$router->addRoute('POST', '/ipv6/pools', 'IPv6Controller@createPool');
$router->addRoute('GET', '/ipv6/pools/create', 'IPv6Controller@createPool');
$router->addRoute('GET', '/ipv6/pools/{id}/edit', 'IPv6Controller@editPool');
$router->addRoute('POST', '/ipv6/pools/{id}/edit', 'IPv6Controller@editPool');
$router->addRoute('GET', '/ipv6/pools/{id}/delete', 'IPv6Controller@deletePool');
$router->addRoute('GET', '/ipv6/allocations', 'IPv6Controller@allocations');
$router->addRoute('POST', '/ipv6/allocations', 'IPv6Controller@allocatePrefix');
$router->addRoute('GET', '/ipv6/allocations/allocate', 'IPv6Controller@allocatePrefix');
$router->addRoute('GET', '/ipv6/allocations/{id}/edit', 'IPv6Controller@editAllocation');
$router->addRoute('POST', '/ipv6/allocations/{id}/edit', 'IPv6Controller@editAllocation');
$router->addRoute('GET', '/ipv6/allocations/{id}/release', 'IPv6Controller@releasePrefix');
$router->addRoute('GET', '/ipv6/statistics', 'IPv6Controller@statistics');

// 监控
$router->addRoute('GET', '/monitoring', 'MonitoringController@index');
$router->addRoute('GET', '/monitoring/metrics', 'MonitoringController@metrics');
$router->addRoute('GET', '/monitoring/alerts', 'MonitoringController@alerts');
$router->addRoute('GET', '/monitoring/history', 'MonitoringController@history');
$router->addRoute('GET', '/monitoring/system', 'MonitoringController@system');
$router->addRoute('GET', '/monitoring/processes', 'MonitoringController@processes');
$router->addRoute('GET', '/monitoring/network', 'MonitoringController@network');
$router->addRoute('GET', '/monitoring/disk', 'MonitoringController@disk');
$router->addRoute('GET', '/monitoring/alerts/create', 'MonitoringController@createAlert');
$router->addRoute('POST', '/monitoring/alerts/create', 'MonitoringController@createAlert');
$router->addRoute('GET', '/monitoring/alerts/{id}/edit', 'MonitoringController@editAlert');
$router->addRoute('POST', '/monitoring/alerts/{id}/edit', 'MonitoringController@editAlert');
$router->addRoute('GET', '/monitoring/alerts/{id}/delete', 'MonitoringController@deleteAlert');
$router->addRoute('GET', '/monitoring/alerts/{id}/acknowledge', 'MonitoringController@acknowledgeAlert');
$router->addRoute('GET', '/monitoring/realtime-data', 'MonitoringController@getRealtimeData');

// 日志
$router->addRoute('GET', '/logs', 'LogsController@index');
$router->addRoute('GET', '/logs/search', 'LogsController@search');
$router->addRoute('GET', '/logs/{id}/details', 'LogsController@details');
$router->addRoute('GET', '/logs/export', 'LogsController@export');
$router->addRoute('GET', '/logs/cleanup', 'LogsController@cleanup');
$router->addRoute('POST', '/logs/cleanup', 'LogsController@cleanup');
$router->addRoute('GET', '/logs/stream', 'LogsController@stream');
$router->addRoute('GET', '/logs/statistics', 'LogsController@statistics');

// 用户管理
$router->addRoute('GET', '/users', 'UsersController@index');
$router->addRoute('POST', '/users', 'UsersController@create');
$router->addRoute('GET', '/users/create', 'UsersController@create');
$router->addRoute('GET', '/users/{id}/edit', 'UsersController@edit');
$router->addRoute('POST', '/users/{id}/edit', 'UsersController@edit');
$router->addRoute('GET', '/users/{id}/delete', 'UsersController@delete');
$router->addRoute('GET', '/users/{id}/details', 'UsersController@details');
$router->addRoute('GET', '/users/roles', 'UsersController@roles');
$router->addRoute('GET', '/users/roles/create', 'UsersController@createRole');
$router->addRoute('POST', '/users/roles/create', 'UsersController@createRole');
$router->addRoute('GET', '/users/roles/{id}/edit', 'UsersController@editRole');
$router->addRoute('POST', '/users/roles/{id}/edit', 'UsersController@editRole');
$router->addRoute('GET', '/users/roles/{id}/delete', 'UsersController@deleteRole');
$router->addRoute('GET', '/users/{id}/permissions', 'UsersController@permissions');
$router->addRoute('POST', '/users/{id}/permissions', 'UsersController@permissions');
$router->addRoute('GET', '/users/{id}/reset-password', 'UsersController@resetPassword');
$router->addRoute('POST', '/users/{id}/reset-password', 'UsersController@resetPassword');
$router->addRoute('GET', '/users/{id}/activity', 'UsersController@activity');
$router->addRoute('POST', '/users/batch', 'UsersController@batch');

// 个人资料管理
$router->addRoute('GET', '/profile', 'ProfileController@index');
$router->addRoute('POST', '/profile', 'ProfileController@update');
$router->addRoute('GET', '/profile/settings', 'ProfileController@settings');
$router->addRoute('GET', '/profile/change-password', 'ProfileController@changePassword');
$router->addRoute('POST', '/profile/change-password', 'ProfileController@updatePassword');
$router->addRoute('GET', '/profile/security', 'ProfileController@security');

// 系统管理
$router->addRoute('GET', '/system/info', 'SystemController@info');
$router->addRoute('GET', '/system/config', 'SystemController@config');
$router->addRoute('POST', '/system/config', 'SystemController@config');
$router->addRoute('GET', '/system/services', 'SystemController@services');
$router->addRoute('GET', '/system/services/{name}/start', 'SystemController@startService');
$router->addRoute('GET', '/system/services/{name}/stop', 'SystemController@stopService');
$router->addRoute('GET', '/system/services/{name}/restart', 'SystemController@restartService');
$router->addRoute('GET', '/system/backup', 'SystemController@backup');
$router->addRoute('POST', '/system/backup', 'SystemController@backup');
$router->addRoute('GET', '/system/backups/{id}/restore', 'SystemController@restore');
$router->addRoute('POST', '/system/backups/{id}/restore', 'SystemController@restore');
$router->addRoute('GET', '/system/backups/{id}/delete', 'SystemController@deleteBackup');
$router->addRoute('GET', '/system/backups/{id}/download', 'SystemController@downloadBackup');
$router->addRoute('GET', '/system/update', 'SystemController@update');
$router->addRoute('POST', '/system/update', 'SystemController@update');
$router->addRoute('GET', '/system/maintenance', 'SystemController@maintenance');
$router->addRoute('POST', '/system/maintenance', 'SystemController@maintenance');
$router->addRoute('GET', '/system/logs', 'SystemController@logs');
$router->addRoute('GET', '/system/performance', 'SystemController@performance');

// 网络管理
$router->addRoute('GET', '/network/interfaces', 'NetworkController@interfaces');
$router->addRoute('GET', '/network/status', 'NetworkController@status');
$router->addRoute('GET', '/network/routes', 'NetworkController@routes');
$router->addRoute('GET', '/network/diagnostics', 'NetworkController@diagnostics');
$router->addRoute('POST', '/network/diagnostics', 'NetworkController@diagnostics');
$router->addRoute('GET', '/network/config', 'NetworkController@config');
$router->addRoute('POST', '/network/config', 'NetworkController@config');
$router->addRoute('GET', '/network/firewall', 'NetworkController@firewall');
$router->addRoute('POST', '/network/firewall', 'NetworkController@firewall');
$router->addRoute('GET', '/network/portscan', 'NetworkController@portscan');
$router->addRoute('POST', '/network/portscan', 'NetworkController@portscan');
$router->addRoute('GET', '/network/traffic', 'NetworkController@traffic');
$router->addRoute('GET', '/network/dns', 'NetworkController@dns');
$router->addRoute('POST', '/network/dns', 'NetworkController@dns');
$router->addRoute('GET', '/network/topology', 'NetworkController@topology');

// 处理请求
$router->handleRequest();
?>
