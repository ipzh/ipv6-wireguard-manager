<?php
/**
 * API连接测试脚本
 */

echo "🔍 IPv6 WireGuard Manager - API连接测试\n";
echo "=====================================\n\n";

// 颜色定义
function colorize($text, $color = 'white') {
    $colors = [
        'red' => "\033[31m",
        'green' => "\033[32m",
        'yellow' => "\033[33m",
        'blue' => "\033[34m",
        'white' => "\033[37m",
        'reset' => "\033[0m"
    ];
    return $colors[$color] . $text . $colors['reset'];
}

// 1. 检查配置文件
echo colorize("📋 1. 检查配置文件", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

if (file_exists('php-frontend/config/config.php')) {
    require_once 'php-frontend/config/config.php';
    echo colorize("✅ 配置文件加载成功", 'green') . "\n";
    echo "API_BASE_URL: " . (defined('API_BASE_URL') ? API_BASE_URL : '未定义') . "\n";
    echo "APP_DEBUG: " . (defined('APP_DEBUG') && APP_DEBUG ? '开启' : '关闭') . "\n";
} else {
    echo colorize("❌ 配置文件不存在", 'red') . "\n";
    define('API_BASE_URL', 'http://localhost:8000/api/v1');
}

// 2. 测试API端点
echo colorize("\n🌐 2. 测试API端点", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$apiUrl = API_BASE_URL;
$endpoints = [
    '/health' => '健康检查',
    '/health/detailed' => '详细健康检查',
    '/auth/health' => '认证健康检查',
    '/status' => '状态检查'
];

foreach ($endpoints as $endpoint => $description) {
    echo "测试 $description ($endpoint)... ";
    
    $url = $apiUrl . $endpoint;
    
    // 使用cURL测试
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Accept: application/json',
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        echo colorize("❌ cURL错误: $error", 'red') . "\n";
    } elseif ($httpCode === 200) {
        $data = json_decode($response, true);
        if ($data) {
            echo colorize("✅ 成功 (HTTP $httpCode)", 'green') . "\n";
            echo "  响应: " . json_encode($data, JSON_UNESCAPED_UNICODE) . "\n";
        } else {
            echo colorize("⚠️ 响应不是JSON格式", 'yellow') . "\n";
            echo "  响应: " . substr($response, 0, 100) . "...\n";
        }
    } else {
        echo colorize("❌ HTTP错误: $httpCode", 'red') . "\n";
        echo "  响应: " . substr($response, 0, 200) . "\n";
    }
}

// 3. 测试后端服务状态
echo colorize("\n🔧 3. 测试后端服务状态", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

// 检查后端服务是否运行
$backendUrl = str_replace('/api/v1', '', $apiUrl);
echo "检查后端服务 ($backendUrl)... ";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $backendUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_NOBODY, true); // 只获取头部
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo colorize("❌ 后端服务不可达: $error", 'red') . "\n";
} elseif ($httpCode) {
    echo colorize("✅ 后端服务运行中 (HTTP $httpCode)", 'green') . "\n";
} else {
    echo colorize("❌ 后端服务无响应", 'red') . "\n";
}

// 4. 测试端口连接
echo colorize("\n🔌 4. 测试端口连接", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$parsedUrl = parse_url($apiUrl);
$host = $parsedUrl['host'];
$port = $parsedUrl['port'] ?? 8000;

echo "测试端口连接 ($host:$port)... ";

$connection = @fsockopen($host, $port, $errno, $errstr, 5);
if ($connection) {
    echo colorize("✅ 端口连接成功", 'green') . "\n";
    fclose($connection);
} else {
    echo colorize("❌ 端口连接失败: $errstr ($errno)", 'red') . "\n";
}

// 5. 检查系统服务
echo colorize("\n⚙️ 5. 检查系统服务", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

// 检查systemd服务状态
$services = ['ipv6-wireguard-manager', 'nginx', 'mysql', 'mariadb'];
foreach ($services as $service) {
    echo "检查服务 $service... ";
    
    $output = [];
    $returnCode = 0;
    exec("systemctl is-active $service 2>/dev/null", $output, $returnCode);
    
    if ($returnCode === 0 && !empty($output)) {
        $status = $output[0];
        if ($status === 'active') {
            echo colorize("✅ 运行中", 'green') . "\n";
        } else {
            echo colorize("⚠️ 状态: $status", 'yellow') . "\n";
        }
    } else {
        echo colorize("❌ 未运行或不存在", 'red') . "\n";
    }
}

// 6. 生成诊断报告
echo colorize("\n📋 6. 诊断报告", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

echo "API连接问题可能的原因:\n";
echo "1. 后端服务未启动\n";
echo "2. 端口被占用或防火墙阻止\n";
echo "3. API端点路径错误\n";
echo "4. 网络连接问题\n";
echo "5. 后端服务配置错误\n";

echo colorize("\n🔧 修复建议:", 'yellow') . "\n";
echo "1. 检查后端服务状态: sudo systemctl status ipv6-wireguard-manager\n";
echo "2. 启动后端服务: sudo systemctl start ipv6-wireguard-manager\n";
echo "3. 检查端口监听: sudo netstat -tlnp | grep 8000\n";
echo "4. 查看后端日志: sudo journalctl -u ipv6-wireguard-manager -f\n";
echo "5. 检查防火墙: sudo ufw status\n";

echo "\n" . str_repeat('=', 50) . "\n";
echo "测试完成时间: " . date('Y-m-d H:i:s') . "\n";
?>