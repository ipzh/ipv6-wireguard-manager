<?php
/**
 * 认证流程测试脚本
 * 用于测试前后端认证集成
 */

// 设置错误报告
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 模拟环境
define('APP_NAME', 'IPv6 WireGuard Manager');
define('API_BASE_URL', 'http://127.0.0.1:8000/api/v1');

echo "=== 认证流程测试 ===\n\n";

// 测试1: 直接测试后端API
echo "1. 测试后端API直接访问\n";
echo "----------------------------------------\n";

$api_url = API_BASE_URL . '/auth/login';
$post_data = [
    'username' => 'admin',
    'password' => 'admin123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($post_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

if ($curl_error) {
    echo "❌ cURL错误: $curl_error\n";
} else {
    echo "HTTP状态码: $http_code\n";
    echo "响应内容: $response\n";
    
    if ($http_code == 200) {
        $data = json_decode($response, true);
        if (isset($data['access_token'])) {
            echo "✅ 后端API认证成功\n";
            echo "Token: " . substr($data['access_token'], 0, 20) . "...\n";
        } else {
            echo "❌ 后端API响应格式错误\n";
        }
    } else {
        echo "❌ 后端API认证失败\n";
    }
}

echo "\n";

// 测试2: 测试Nginx代理
echo "2. 测试Nginx代理访问\n";
echo "----------------------------------------\n";

$proxy_url = 'http://localhost/api/auth/login';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $proxy_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($post_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

if ($curl_error) {
    echo "❌ cURL错误: $curl_error\n";
} else {
    echo "HTTP状态码: $http_code\n";
    echo "响应内容: $response\n";
    
    if ($http_code == 200) {
        $data = json_decode($response, true);
        if (isset($data['access_token'])) {
            echo "✅ Nginx代理认证成功\n";
        } else {
            echo "❌ Nginx代理响应格式错误\n";
        }
    } else {
        echo "❌ Nginx代理认证失败\n";
    }
}

echo "\n";

// 测试3: 测试JSON格式登录
echo "3. 测试JSON格式登录\n";
echo "----------------------------------------\n";

$json_url = API_BASE_URL . '/auth/login-json';
$json_data = json_encode($post_data);

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $json_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $json_data);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

if ($curl_error) {
    echo "❌ cURL错误: $curl_error\n";
} else {
    echo "HTTP状态码: $http_code\n";
    echo "响应内容: $response\n";
    
    if ($http_code == 200) {
        $data = json_decode($response, true);
        if (isset($data['access_token'])) {
            echo "✅ JSON格式认证成功\n";
        } else {
            echo "❌ JSON格式响应错误\n";
        }
    } else {
        echo "❌ JSON格式认证失败\n";
    }
}

echo "\n";

// 测试4: 测试错误的密码
echo "4. 测试错误密码\n";
echo "----------------------------------------\n";

$wrong_data = [
    'username' => 'admin',
    'password' => 'wrongpassword'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($wrong_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP状态码: $http_code\n";
echo "响应内容: $response\n";

if ($http_code == 401) {
    echo "✅ 错误密码正确返回401\n";
} else {
    echo "❌ 错误密码处理异常\n";
}

echo "\n";

// 测试5: 检查API健康状态
echo "5. 检查API健康状态\n";
echo "----------------------------------------\n";

$health_url = API_BASE_URL . '/health';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $health_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "健康检查HTTP状态码: $http_code\n";
echo "健康检查响应: $response\n";

if ($http_code == 200) {
    echo "✅ API健康检查通过\n";
} else {
    echo "❌ API健康检查失败\n";
}

echo "\n=== 测试完成 ===\n";
?>
