<?php
/**
 * 应用配置文件
 */

// 应用配置
define('APP_NAME', getenv('APP_NAME') ?: 'IPv6 WireGuard Manager');
define('APP_VERSION', getenv('APP_VERSION') ?: '3.0.0');
define('APP_DEBUG', filter_var(getenv('APP_DEBUG') ?: true, FILTER_VALIDATE_BOOLEAN));

// API配置
if (!defined('API_BASE_URL')) {
    define('API_BASE_URL', getenv('API_BASE_URL') ?: 'http://' . ($_SERVER['HTTP_HOST'] ?? 'localhost') . ':8000/api/v1');
}
if (!defined('API_TIMEOUT')) {
    define('API_TIMEOUT', getenv('API_TIMEOUT') ?: 30);
}

// 会话配置
define('SESSION_LIFETIME', 3600); // 1小时

// 分页配置
define('DEFAULT_PAGE_SIZE', 20);
define('MAX_PAGE_SIZE', 100);

// 文件上传配置
define('UPLOAD_MAX_SIZE', 10 * 1024 * 1024); // 10MB
define('UPLOAD_ALLOWED_TYPES', ['txt', 'conf', 'key']);

// 安全配置
define('CSRF_TOKEN_NAME', '_token');
define('PASSWORD_MIN_LENGTH', 8);

// 错误处理
if (APP_DEBUG) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// 时区设置
date_default_timezone_set('Asia/Shanghai');

// 字符编码
mb_internal_encoding('UTF-8');
mb_http_output('UTF-8');
?>
