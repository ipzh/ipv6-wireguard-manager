<?php
/**
 * API代理 - 将前端请求转发到后端API
 * 功能说明：
 * 1. 统一前后端API调用入口
 * 2. 自动处理认证令牌传递
 * 3. 安全的SSL/TLS配置
 * 4. 错误处理和日志记录
 */

// 引入SSL安全配置
require_once __DIR__ . '/includes/ssl_security.php';

// 启动会话（如果尚未启动）以访问认证令牌
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// 设置JSON响应头，确保正确的字符编码和缓存控制
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

// 获取请求路径
$requestUri = $_SERVER['REQUEST_URI'];
$path = parse_url($requestUri, PHP_URL_PATH);

// 移除 /api/v1 前缀（如果存在）
$apiPath = preg_replace('/^\/api\/v1/', '', $path);

// 构建后端API URL，优先使用环境变量配置
// 支持多种配置方式：环境变量 > 配置文件常量 > 默认值
$backendUrl = null;

// 1. 尝试从环境变量获取
if (getenv('API_BASE_URL')) {
    $backendUrl = getenv('API_BASE_URL');
}

// 2. 尝试从配置文件常量获取
if (!$backendUrl && defined('API_BASE_URL')) {
    $backendUrl = API_BASE_URL;
}

// 3. 尝试从配置文件获取（如果配置文件已加载）
if (!$backendUrl && file_exists(__DIR__ . '/../config/config.php')) {
    // 避免重复加载，只检查是否已定义
    if (!defined('API_BASE_URL')) {
        require_once __DIR__ . '/../config/config.php';
    }
    if (defined('API_BASE_URL')) {
        $backendUrl = API_BASE_URL;
    }
}

// 4. 使用默认值（仅在开发环境）
if (!$backendUrl) {
    $isDev = getenv('APP_ENV') !== 'production' || 
             (defined('APP_DEBUG') && APP_DEBUG) ||
             (php_sapi_name() === 'cli-server');
    
    $backendUrl = $isDev ? 'http://localhost:8000/api/v1' : '';
    
    if (!$backendUrl) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'API_BASE_URL未配置',
            'message' => '请设置API_BASE_URL环境变量或配置文件'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
}

$fullUrl = $backendUrl . $apiPath;

// 添加查询参数（如果有）
if (!empty($_SERVER['QUERY_STRING'])) {
    $fullUrl .= '?' . $_SERVER['QUERY_STRING'];
}

// 设置请求方法
$method = $_SERVER['REQUEST_METHOD'];

// 准备请求头
$headers = [
    'Content-Type: application/json',
    'Accept: application/json',
    'User-Agent: IPv6-WireGuard-Manager-Frontend/1.0'
];

// 添加认证头（如果已登录）
if (isset($_SESSION['access_token'])) {
    $headers[] = 'Authorization: Bearer ' . $_SESSION['access_token'];
}

// 准备Cookie头（支持HttpOnly Cookie方案）
$cookieHeaders = [];
foreach ($_COOKIE as $name => $value) {
    $cookieHeaders[] = $name . '=' . urlencode($value);
}

if (!empty($cookieHeaders)) {
    $headers[] = 'Cookie: ' . implode('; ', $cookieHeaders);
}

// 准备请求数据（POST/PUT/PATCH请求才需要）
$data = null;
if (in_array($method, ['POST', 'PUT', 'PATCH'], true)) {
    $data = file_get_contents('php://input');
}

// 初始化并配置cURL会话
$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $fullUrl,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CUSTOMREQUEST => $method,
    CURLOPT_HTTPHEADER => $headers,
    CURLOPT_TIMEOUT => 30,              // 总超时时间30秒
    CURLOPT_CONNECTTIMEOUT => 10,       // 连接超时时间10秒
    CURLOPT_FOLLOWLOCATION => true,     // 跟随重定向
    CURLOPT_MAXREDIRS => 3,             // 最多跟随3次重定向
    CURLOPT_HEADER => true,              // 包含响应头，用于处理Set-Cookie
]);

// 应用安全的SSL配置（启用证书验证、TLS 1.2+等）
applySecureSSLConfig($ch);

// 如果有请求体数据，添加到请求中
if ($data) {
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
}

// 执行请求并获取响应
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);

// 获取响应头信息（特别是Set-Cookie头）
$responseHeaders = [];
$headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
if ($headerSize > 0) {
    $headerText = substr($response, 0, $headerSize);
    $responseBody = substr($response, $headerSize);
    
    // 解析响应头
    $headerLines = explode("\r\n", $headerText);
    foreach ($headerLines as $headerLine) {
        if (strpos($headerLine, ':') !== false) {
            list($name, $value) = explode(':', $headerLine, 2);
            $name = trim($name);
            $value = trim($value);
            
            // 处理Set-Cookie头
            if (strtolower($name) === 'set-cookie') {
                // 直接转发Set-Cookie头到前端
                header($name . ': ' . $value);
            }
        }
    }
} else {
    $responseBody = $response;
}

curl_close($ch);

// 处理请求失败的情况
if ($responseBody === false) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'CURL错误: ' . $error,
        'message' => '无法连接到后端API服务，请检查网络连接或联系管理员'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// 设置HTTP状态码（与后端保持一致）
http_response_code($httpCode);

// 尝试解析JSON响应并重新格式化
$decodedResponse = json_decode($responseBody, true);
if (json_last_error() === JSON_ERROR_NONE) {
    // 成功解析JSON，使用统一格式输出
    echo json_encode($decodedResponse, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
} else {
    // 如果不是JSON格式，直接输出原始响应
    echo $responseBody;
}
