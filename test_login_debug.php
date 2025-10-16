<?php
/**
 * 登录调试测试脚本
 */

// 设置错误报告
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 包含必要的文件
require_once 'php-frontend/config/config.php';
require_once 'php-frontend/classes/ApiClient.php';
require_once 'php-frontend/classes/Auth.php';

echo "<h1>登录调试测试</h1>\n";

// 1. 检查配置
echo "<h2>1. 配置检查</h2>\n";
echo "API_BASE_URL: " . API_BASE_URL . "<br>\n";
echo "API_TIMEOUT: " . API_TIMEOUT . "<br>\n";

// 2. 测试API连接
echo "<h2>2. API连接测试</h2>\n";
$apiClient = new ApiClient();

try {
    echo "测试健康检查端点...<br>\n";
    $healthResponse = $apiClient->get('/health');
    echo "健康检查响应: " . json_encode($healthResponse, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "<br>\n";
} catch (Exception $e) {
    echo "健康检查失败: " . $e->getMessage() . "<br>\n";
}

// 3. 测试认证端点
echo "<h2>3. 认证端点测试</h2>\n";

// 测试JSON登录
echo "<h3>3.1 JSON登录测试</h3>\n";
try {
    $loginData = [
        'username' => 'admin',
        'password' => 'admin123'
    ];
    
    echo "发送登录请求到: " . API_BASE_URL . "/auth/login-json<br>\n";
    echo "登录数据: " . json_encode($loginData, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "<br>\n";
    
    $loginResponse = $apiClient->post('/auth/login-json', $loginData);
    echo "登录响应: " . json_encode($loginResponse, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "<br>\n";
    
    if (isset($loginResponse['access_token'])) {
        echo "✅ 登录成功！<br>\n";
        
        // 设置令牌并测试获取用户信息
        $apiClient->setToken($loginResponse['access_token']);
        echo "令牌已设置: " . substr($loginResponse['access_token'], 0, 20) . "...<br>\n";
        
        try {
            $userInfo = $apiClient->get('/auth/me');
            echo "用户信息: " . json_encode($userInfo, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "<br>\n";
        } catch (Exception $e) {
            echo "获取用户信息失败: " . $e->getMessage() . "<br>\n";
        }
    } else {
        echo "❌ 登录失败<br>\n";
    }
    
} catch (Exception $e) {
    echo "❌ 登录请求失败: " . $e->getMessage() . "<br>\n";
}

// 4. 测试Auth类
echo "<h2>4. Auth类测试</h2>\n";
$auth = new Auth();

echo "测试Auth类登录...<br>\n";
$loginResult = $auth->login('admin', 'admin123');
echo "Auth登录结果: " . ($loginResult ? '成功' : '失败') . "<br>\n";

if ($loginResult) {
    $currentUser = $auth->getCurrentUser();
    echo "当前用户: " . json_encode($currentUser, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "<br>\n";
    echo "登录状态: " . ($auth->isLoggedIn() ? '已登录' : '未登录') . "<br>\n";
}

// 5. 测试错误的用户名密码
echo "<h2>5. 错误凭据测试</h2>\n";
try {
    $wrongLoginData = [
        'username' => 'admin',
        'password' => 'wrongpassword'
    ];
    
    echo "测试错误密码...<br>\n";
    $wrongResponse = $apiClient->post('/auth/login-json', $wrongLoginData);
    echo "错误密码响应: " . json_encode($wrongResponse, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "<br>\n";
    
} catch (Exception $e) {
    echo "错误密码测试结果: " . $e->getMessage() . "<br>\n";
}

// 6. 检查后端服务状态
echo "<h2>6. 后端服务状态检查</h2>\n";

// 检查端口是否监听
$port = 8000;
$connection = @fsockopen('localhost', $port, $errno, $errstr, 5);
if ($connection) {
    echo "✅ 端口 $port 正在监听<br>\n";
    fclose($connection);
} else {
    echo "❌ 端口 $port 未监听: $errstr ($errno)<br>\n";
}

// 检查IPv6端口
$ipv6Connection = @fsockopen('[::1]', $port, $errno, $errstr, 5);
if ($ipv6Connection) {
    echo "✅ IPv6端口 $port 正在监听<br>\n";
    fclose($ipv6Connection);
} else {
    echo "❌ IPv6端口 $port 未监听: $errstr ($errno)<br>\n";
}

// 7. 直接HTTP请求测试
echo "<h2>7. 直接HTTP请求测试</h2>\n";

$testUrls = [
    'http://localhost:8000/api/v1/health',
    'http://127.0.0.1:8000/api/v1/health',
    'http://[::1]:8000/api/v1/health'
];

foreach ($testUrls as $url) {
    echo "测试URL: $url<br>\n";
    
    $context = stream_context_create([
        'http' => [
            'method' => 'GET',
            'timeout' => 5,
            'header' => 'Accept: application/json'
        ]
    ]);
    
    $response = @file_get_contents($url, false, $context);
    
    if ($response !== false) {
        echo "✅ 响应成功: " . substr($response, 0, 200) . "...<br>\n";
    } else {
        $error = error_get_last();
        echo "❌ 请求失败: " . ($error['message'] ?? '未知错误') . "<br>\n";
    }
    echo "<br>\n";
}

echo "<h2>测试完成</h2>\n";
?>
