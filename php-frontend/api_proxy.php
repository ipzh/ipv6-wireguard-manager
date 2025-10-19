<?php
/**
 * API代理 - 将前端请求转发到后端API
 */

// 引入SSL安全配置
require_once __DIR__ . '/includes/ssl_security.php';

// 设置JSON响应头
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-cache, no-store, must-revalidate');

// 获取请求路径
$requestUri = $_SERVER['REQUEST_URI'];
$path = parse_url($requestUri, PHP_URL_PATH);

// 移除 /api/v1 前缀
$apiPath = preg_replace('/^\/api\/v1/', '', $path);

// 构建后端API URL
$backendUrl = getenv('API_BASE_URL') ?: 'http://localhost:8000/api/v1';
$fullUrl = $backendUrl . $apiPath;

// 添加查询参数
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

// 添加认证头（如果有）
if (isset($_SESSION['access_token'])) {
    $headers[] = 'Authorization: Bearer ' . $_SESSION['access_token'];
}

// 准备请求数据
$data = null;
if (in_array($method, ['POST', 'PUT', 'PATCH'])) {
    $data = file_get_contents('php://input');
}

// 发送请求到后端
$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $fullUrl,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CUSTOMREQUEST => $method,
    CURLOPT_HTTPHEADER => $headers,
    CURLOPT_TIMEOUT => 30,
    CURLOPT_CONNECTTIMEOUT => 10,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_MAXREDIRS => 3
]);

// 应用安全的SSL配置
applySecureSSLConfig($ch);

if ($data) {
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
}

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

// 处理响应
if ($response === false) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'CURL错误: ' . $error,
        'message' => '无法连接到后端API服务'
    ]);
    exit;
}

// 设置HTTP状态码
http_response_code($httpCode);

// 如果是JSON响应，解析并重新格式化
$decodedResponse = json_decode($response, true);
if (json_last_error() === JSON_ERROR_NONE) {
    echo json_encode($decodedResponse, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
} else {
    // 如果不是JSON，直接输出
    echo $response;
}
?>
