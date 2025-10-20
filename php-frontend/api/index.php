<?php
/**
 * API代理端点 - 解决跨域和路径问题
 */

// 引入SSL安全配置
require_once __DIR__ . '/../includes/ssl_security.php';

// 设置CORS头 - 生产环境应该限制域名
$allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:5173',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:8080',
    'http://127.0.0.1:5173'
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$allowedOrigin = in_array($origin, $allowedOrigins) ? $origin : (APP_DEBUG ? '*' : '');

if ($allowedOrigin) {
    header("Access-Control-Allow-Origin: $allowedOrigin");
}
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Credentials: true");
header("Content-Type: application/json; charset=utf-8");

// 处理预检请求
if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    exit;
}

// 引入配置
if (file_exists("../config/config.php")) {
    require_once "../config/config.php";
} else {
    // 如果配置文件不存在，使用默认值
    define('APP_NAME', 'IPv6 WireGuard Manager');
    define('APP_DEBUG', true);
    define('API_BASE_URL', 'http://' . ($_SERVER['HTTP_HOST'] ?? 'localhost') . ':8000');
    define('API_TIMEOUT', 30);
}

// 获取请求路径
$requestUri = $_SERVER["REQUEST_URI"];
$path = parse_url($requestUri, PHP_URL_PATH);

// 移除/api前缀
$apiPath = preg_replace("#^/api#", "", $path);

// 构建后端API URL
$backendUrl = API_BASE_URL . $apiPath;

// 如果有查询参数，添加到URL
if (!empty($_SERVER["QUERY_STRING"])) {
    $backendUrl .= "?" . $_SERVER["QUERY_STRING"];
}

// 准备请求数据
$requestData = null;
if ($_SERVER["REQUEST_METHOD"] === "POST" || $_SERVER["REQUEST_METHOD"] === "PUT") {
    $requestData = file_get_contents("php://input");
}

// 设置请求头
$headers = [
    "Content-Type: application/json",
    "Accept: application/json"
];

// 如果有Authorization头，传递它
if (isset($_SERVER["HTTP_AUTHORIZATION"])) {
    $headers[] = "Authorization: " . $_SERVER["HTTP_AUTHORIZATION"];
}

// 初始化cURL
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $backendUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

// 应用安全的SSL配置
applySecureSSLConfig($ch);

// 设置请求方法
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $_SERVER["REQUEST_METHOD"]);

// 如果有请求数据，设置它
if ($requestData) {
    curl_setopt($ch, CURLOPT_POSTFIELDS, $requestData);
}

// 执行请求
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

// 处理响应
if ($error) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "API连接失败: " . $error,
        "message" => "无法连接到后端API服务",
        "backend_url" => $backendUrl
    ], JSON_UNESCAPED_UNICODE);
} else {
    // 设置HTTP状态码
    http_response_code($httpCode);
    
    // 尝试解析JSON响应
    $jsonData = json_decode($response, true);
    if ($jsonData !== null) {
        echo json_encode($jsonData, JSON_UNESCAPED_UNICODE);
    } else {
        // 如果不是JSON，返回错误信息
        echo json_encode([
            "success" => false,
            "error" => "API响应格式错误",
            "message" => "后端返回了非JSON格式的响应",
            "http_code" => $httpCode,
            "raw_response" => substr($response, 0, 200)
        ], JSON_UNESCAPED_UNICODE);
    }
}
?>
