<?php
/**
 * API状态检查页面
 */

// 引入SSL安全配置
require_once __DIR__ . '/includes/ssl_security.php';

// 设置JSON响应头
header("Content-Type: application/json; charset=utf-8");

// 引入配置
if (file_exists("config/config.php")) {
    require_once "config/config.php";
} else {
    // 如果配置文件不存在，使用默认值
    define('APP_NAME', 'IPv6 WireGuard Manager');
    define('APP_DEBUG', true);
    define('API_BASE_URL', 'http://' . ($_SERVER['HTTP_HOST'] ?? 'localhost') . ':8000');
    define('API_TIMEOUT', 30);
}

// 检查API连接
function checkApiConnection() {
    $apiUrl = API_BASE_URL . "/health";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $apiUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Accept: application/json",
        "Content-Type: application/json"
    ]);
    
    // 应用安全的SSL配置
    applySecureSSLConfig($ch);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        return [
            "success" => false,
            "error" => "连接失败: " . $error,
            "http_code" => 0,
            "backend_url" => $apiUrl
        ];
    }
    
    if ($httpCode === 200) {
        $data = json_decode($response, true);
        return [
            "success" => true,
            "data" => $data,
            "http_code" => $httpCode,
            "backend_url" => $apiUrl
        ];
    } else {
        return [
            "success" => false,
            "error" => "HTTP错误: " . $httpCode,
            "http_code" => $httpCode,
            "response" => substr($response, 0, 200),
            "backend_url" => $apiUrl
        ];
    }
}

// 执行检查
$result = checkApiConnection();

// 输出结果
echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>