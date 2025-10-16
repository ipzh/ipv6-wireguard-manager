<?php
/**
 * API连接测试脚本
 */
require_once 'php-frontend/includes/ApiClient.php';

echo "🔍 IPv6 WireGuard Manager - API连接测试\n";
echo "=====================================\n\n";

// 测试配置
$testUrls = [
    'http://localhost:8000/api/v1',
    'http://127.0.0.1:8000/api/v1',
    'http://backend:8000/api/v1',
    'http://172.20.0.2:8000/api/v1'  // Docker网络IP
];

$endpoints = [
    '/health',
    '/health/detailed',
    '/debug/ping'
];

echo "📋 测试配置:\n";
echo "API基础URL: " . (getenv('API_BASE_URL') ?: 'http://localhost:8000/api/v1') . "\n";
echo "测试端点: " . implode(', ', $endpoints) . "\n\n";

// 创建API客户端
$apiClient = new ApiClient();

echo "🧪 开始API连接测试...\n\n";

foreach ($testUrls as $baseUrl) {
    echo "📍 测试URL: $baseUrl\n";
    echo str_repeat('-', 50) . "\n";
    
    // 创建新的API客户端实例
    $testClient = new ApiClient($baseUrl, 10, 1, true); // 启用调试模式
    
    foreach ($endpoints as $endpoint) {
        echo "  🔗 测试端点: $endpoint\n";
        
        try {
            $startTime = microtime(true);
            $response = $testClient->get($endpoint);
            $endTime = microtime(true);
            
            $responseTime = round(($endTime - $startTime) * 1000, 2);
            
            echo "    ✅ 成功 - 状态码: {$response['status']}, 响应时间: {$responseTime}ms\n";
            
            if (isset($response['data']['status'])) {
                echo "    📊 服务状态: {$response['data']['status']}\n";
            }
            
        } catch (Exception $e) {
            echo "    ❌ 失败 - 错误: " . $e->getMessage() . "\n";
        }
        
        echo "\n";
    }
    
    echo "\n";
}

// 测试默认API客户端
echo "🔧 测试默认API客户端...\n";
echo str_repeat('-', 50) . "\n";

try {
    $healthCheck = $apiClient->healthCheck();
    echo "健康检查: " . json_encode($healthCheck, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n\n";
} catch (Exception $e) {
    echo "健康检查失败: " . $e->getMessage() . "\n\n";
}

try {
    $connectionStatus = $apiClient->getConnectionStatus();
    echo "连接状态: " . json_encode($connectionStatus, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n\n";
} catch (Exception $e) {
    echo "连接状态检查失败: " . $e->getMessage() . "\n\n";
}

try {
    $apiStatus = $apiClient->getApiStatus();
    echo "API状态: " . json_encode($apiStatus, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n\n";
} catch (Exception $e) {
    echo "API状态检查失败: " . $e->getMessage() . "\n\n";
}

// 网络连接测试
echo "🌐 网络连接测试...\n";
echo str_repeat('-', 50) . "\n";

$testHosts = [
    'localhost:8000',
    '127.0.0.1:8000',
    'backend:8000'
];

foreach ($testHosts as $host) {
    echo "测试主机: $host\n";
    
    $connection = @fsockopen($host, 8000, $errno, $errstr, 5);
    if ($connection) {
        echo "  ✅ 端口8000可连接\n";
        fclose($connection);
    } else {
        echo "  ❌ 端口8000不可连接 - $errstr ($errno)\n";
    }
}

echo "\n🎯 测试完成！\n";
?>
