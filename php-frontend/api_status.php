<?php
/**
 * API连接状态检测页面
 */
require_once 'config/config.php';
require_once 'includes/ApiClient.php';

// 设置JSON响应头
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');

try {
    $apiClient = new ApiClient();
    
    // 获取详细的连接状态
    $connectionStatus = $apiClient->getConnectionStatus();
    $healthCheck = $apiClient->healthCheck();
    $apiStatus = $apiClient->getApiStatus();
    
    // 获取系统信息
    $systemInfo = null;
    try {
        $systemResponse = $apiClient->get('/debug/system-info');
        $systemInfo = $systemResponse['data'];
    } catch (Exception $e) {
        // 忽略系统信息获取失败
    }
    
    // 获取数据库状态
    $databaseStatus = null;
    try {
        $dbResponse = $apiClient->get('/debug/database-status');
        $databaseStatus = $dbResponse['data'];
    } catch (Exception $e) {
        // 忽略数据库状态获取失败
    }
    
    $response = [
        'timestamp' => time(),
        'datetime' => date('Y-m-d H:i:s'),
        'api_config' => [
            'base_url' => API_BASE_URL,
            'timeout' => API_TIMEOUT
        ],
        'connection_status' => $connectionStatus,
        'health_check' => $healthCheck,
        'api_status' => $apiStatus,
        'system_info' => $systemInfo,
        'database_status' => $databaseStatus,
        'overall_status' => [
            'healthy' => $connectionStatus['connected'] && $healthCheck['status'] === 'healthy',
            'connected' => $connectionStatus['connected'],
            'response_time' => $connectionStatus['response_time'] ?? 0,
            'last_check' => time()
        ]
    ];
    
    // 设置HTTP状态码
    http_response_code($response['overall_status']['healthy'] ? 200 : 503);
    
    echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    $errorResponse = [
        'timestamp' => time(),
        'datetime' => date('Y-m-d H:i:s'),
        'error' => true,
        'message' => 'API连接检测失败: ' . $e->getMessage(),
        'api_config' => [
            'base_url' => API_BASE_URL,
            'timeout' => API_TIMEOUT
        ],
        'overall_status' => [
            'healthy' => false,
            'connected' => false,
            'error' => $e->getMessage()
        ]
    ];
    
    http_response_code(503);
    echo json_encode($errorResponse, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
}
?>
