<?php
/**
 * 健康检查端点
 */
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');

$health = [
    'status' => 'healthy',
    'service' => 'IPv6 WireGuard Manager Frontend',
    'version' => '3.1.0',
    'timestamp' => time(),
    'datetime' => date('Y-m-d H:i:s'),
    'php_version' => PHP_VERSION,
    'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'
];

// 检查PHP扩展
$required_extensions = ['pdo', 'pdo_mysql', 'mysqli', 'json', 'curl'];
$missing_extensions = [];

foreach ($required_extensions as $ext) {
    if (!extension_loaded($ext)) {
        $missing_extensions[] = $ext;
    }
}

if (!empty($missing_extensions)) {
    $health['status'] = 'unhealthy';
    $health['missing_extensions'] = $missing_extensions;
}

// 检查配置文件
$config_files = [
    'config/config.php',
    'config/database.php'
];

$missing_configs = [];
foreach ($config_files as $config) {
    if (!file_exists($config)) {
        $missing_configs[] = $config;
    }
}

if (!empty($missing_configs)) {
    $health['status'] = 'unhealthy';
    $health['missing_configs'] = $missing_configs;
}

// 设置HTTP状态码
http_response_code($health['status'] === 'healthy' ? 200 : 503);

echo json_encode($health, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
