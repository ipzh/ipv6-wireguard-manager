<?php
/**
 * API连接修复脚本
 */

echo "🔧 IPv6 WireGuard Manager - API连接修复\n";
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

// 1. 修复前端API调用问题
echo colorize("🔧 1. 修复前端API调用", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

// 修复test_homepage.php中的API检查
$testFile = 'php-frontend/test_homepage.php';
if (file_exists($testFile)) {
    $content = file_get_contents($testFile);
    
    // 查找并替换API检查函数
    $oldApiCheck = 'fetch(\'/api/v1/health\')';
    $newApiCheck = 'fetch(\'<?= defined("API_BASE_URL") ? API_BASE_URL : "http://localhost:8000/api/v1" ?>/health\')';
    
    if (strpos($content, $oldApiCheck) !== false) {
        $content = str_replace($oldApiCheck, $newApiCheck, $content);
        file_put_contents($testFile, $content);
        echo colorize("✅ 修复了test_homepage.php中的API调用", 'green') . "\n";
    } else {
        echo colorize("⚠️ test_homepage.php中未找到需要修复的API调用", 'yellow') . "\n";
    }
} else {
    echo colorize("❌ test_homepage.php文件不存在", 'red') . "\n";
}

// 2. 创建API代理端点
echo colorize("\n🌐 2. 创建API代理端点", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$apiProxyContent = '<?php
/**
 * API代理端点 - 解决跨域和路径问题
 */

// 设置CORS头
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=utf-8");

// 处理预检请求
if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    exit;
}

// 引入配置
if (file_exists("config/config.php")) {
    require_once "config/config.php";
} else {
    define("API_BASE_URL", "http://localhost:8000/api/v1");
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
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

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
        "message" => "无法连接到后端API服务"
    ]);
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
            "raw_response" => substr($response, 0, 200)
        ]);
    }
}
?>';

// 确保目录存在
if (!is_dir('php-frontend/api')) {
    mkdir('php-frontend/api', 0755, true);
}

// 创建API代理文件
file_put_contents('php-frontend/api/index.php', $apiProxyContent);
echo colorize("✅ 创建了API代理端点: php-frontend/api/index.php", 'green') . "\n";

// 3. 修复前端API调用路径
echo colorize("\n🔗 3. 修复前端API调用路径", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

// 修复登录页面的API调用
$loginFile = 'php-frontend/views/auth/login.php';
if (file_exists($loginFile)) {
    $content = file_get_contents($loginFile);
    
    // 替换API调用路径
    $oldApiCall = 'fetch(apiUrl + \'/health\')';
    $newApiCall = 'fetch(\'/api/health\')';
    
    if (strpos($content, $oldApiCall) !== false) {
        $content = str_replace($oldApiCall, $newApiCall, $content);
        file_put_contents($loginFile, $content);
        echo colorize("✅ 修复了登录页面的API调用路径", 'green') . "\n";
    }
}

// 修复test_homepage.php的API调用
if (file_exists($testFile)) {
    $content = file_get_contents($testFile);
    
    // 替换API调用路径
    $oldApiCall = 'fetch(\'<?= defined("API_BASE_URL") ? API_BASE_URL : "http://localhost:8000/api/v1" ?>/health\')';
    $newApiCall = 'fetch(\'/api/health\')';
    
    if (strpos($content, $oldApiCall) !== false) {
        $content = str_replace($oldApiCall, $newApiCall, $content);
        file_put_contents($testFile, $content);
        echo colorize("✅ 修复了test_homepage.php的API调用路径", 'green') . "\n";
    }
}

// 4. 创建.htaccess文件支持API路由
echo colorize("\n📝 4. 创建.htaccess文件", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$htaccessContent = 'RewriteEngine On

# API代理路由
RewriteRule ^api/(.*)$ api/index.php [QSA,L]

# 前端路由
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php [QSA,L]';

file_put_contents('php-frontend/.htaccess', $htaccessContent);
echo colorize("✅ 创建了.htaccess文件", 'green') . "\n";

// 5. 创建简单的API状态检查页面
echo colorize("\n📊 5. 创建API状态检查页面", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$apiStatusContent = '<?php
/**
 * API状态检查页面
 */

// 设置JSON响应头
header("Content-Type: application/json; charset=utf-8");

// 引入配置
if (file_exists("config/config.php")) {
    require_once "config/config.php";
} else {
    define("API_BASE_URL", "http://localhost:8000/api/v1");
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
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        return [
            "success" => false,
            "error" => "连接失败: " . $error,
            "http_code" => 0
        ];
    }
    
    if ($httpCode === 200) {
        $data = json_decode($response, true);
        return [
            "success" => true,
            "data" => $data,
            "http_code" => $httpCode
        ];
    } else {
        return [
            "success" => false,
            "error" => "HTTP错误: " . $httpCode,
            "http_code" => $httpCode,
            "response" => substr($response, 0, 200)
        ];
    }
}

// 执行检查
$result = checkApiConnection();

// 输出结果
echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>';

file_put_contents('php-frontend/api_status.php', $apiStatusContent);
echo colorize("✅ 创建了API状态检查页面: php-frontend/api_status.php", 'green') . "\n";

// 6. 生成修复报告
echo colorize("\n📋 6. 修复报告", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

echo "修复完成！主要修复内容:\n";
echo "1. ✅ 创建了API代理端点 (php-frontend/api/index.php)\n";
echo "2. ✅ 修复了前端API调用路径\n";
echo "3. ✅ 创建了.htaccess文件支持API路由\n";
echo "4. ✅ 创建了API状态检查页面\n";

echo colorize("\n🎯 测试建议:", 'blue') . "\n";
echo "1. 访问 http://localhost/php-frontend/api_status.php 检查API状态\n";
echo "2. 访问 http://localhost/php-frontend/test_homepage.php 测试功能\n";
echo "3. 访问 http://localhost/php-frontend/login 测试登录页面\n";

echo colorize("\n🔧 如果仍有问题:", 'yellow') . "\n";
echo "1. 检查后端服务是否运行: sudo systemctl status ipv6-wireguard-manager\n";
echo "2. 检查端口8000是否监听: sudo netstat -tlnp | grep 8000\n";
echo "3. 查看后端日志: sudo journalctl -u ipv6-wireguard-manager -f\n";
echo "4. 检查防火墙设置: sudo ufw status\n";

echo "\n" . str_repeat('=', 50) . "\n";
echo "修复完成时间: " . date('Y-m-d H:i:s') . "\n";
?>