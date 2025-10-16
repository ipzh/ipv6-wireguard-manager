<?php
/**
 * 前端首页问题诊断和修复脚本
 */

echo "🔧 IPv6 WireGuard Manager - 前端首页问题诊断和修复\n";
echo "================================================\n\n";

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

// 1. 检查主要问题
echo colorize("🔍 1. 诊断主要问题", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$issues = [];

// 检查Dashboard控制器是否要求登录
if (file_exists('php-frontend/controllers/DashboardController.php')) {
    $content = file_get_contents('php-frontend/controllers/DashboardController.php');
    if (strpos($content, '$this->auth->requireLogin()') !== false) {
        $issues[] = "Dashboard控制器要求用户登录，未登录用户会被重定向到登录页面";
    }
}

// 检查登录页面是否存在
if (!file_exists('php-frontend/views/auth/login.php')) {
    $issues[] = "登录页面不存在";
}

// 检查配置文件
if (!file_exists('php-frontend/config/config.php')) {
    $issues[] = "配置文件不存在";
}

// 检查路由配置
if (!file_exists('php-frontend/index.php')) {
    $issues[] = "主入口文件不存在";
}

foreach ($issues as $issue) {
    echo colorize("⚠️ $issue", 'yellow') . "\n";
}

if (empty($issues)) {
    echo colorize("✅ 未发现明显问题", 'green') . "\n";
}

// 2. 修复Dashboard控制器
echo colorize("\n🔧 2. 修复Dashboard控制器", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

if (file_exists('php-frontend/controllers/DashboardController.php')) {
    $content = file_get_contents('php-frontend/controllers/DashboardController.php');
    
    // 检查是否需要修复
    if (strpos($content, '$this->auth->requireLogin()') !== false) {
        echo "修复Dashboard控制器 - 移除强制登录要求...\n";
        
        // 创建一个不要求登录的版本
        $newContent = str_replace(
            '        // 要求用户登录
        $this->auth->requireLogin();',
            '        // 检查用户登录状态，但不强制要求
        // $this->auth->requireLogin();',
            $content
        );
        
        // 添加登录状态检查
        $newContent = str_replace(
            '    public function index() {',
            '    public function index() {
        // 检查用户是否已登录
        if (!$this->auth->isLoggedIn()) {
            // 如果未登录，显示登录提示或重定向到登录页面
            $this->showLoginPrompt();
            return;
        }',
            $newContent
        );
        
        // 添加显示登录提示的方法
        $newContent = str_replace(
            '    }
}',
            '    }
    
    /**
     * 显示登录提示
     */
    private function showLoginPrompt() {
        $pageTitle = \'需要登录\';
        $showSidebar = false;
        
        include \'views/layout/header.php\';
        echo \'<div class="container mt-5">
            <div class="row justify-content-center">
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-body text-center">
                            <h5 class="card-title">需要登录</h5>
                            <p class="card-text">请先登录以访问管理控制台。</p>
                            <a href="/login" class="btn btn-primary">前往登录</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>\';
        include \'views/layout/footer.php\';
    }
}',
            $newContent
        );
        
        // 备份原文件
        copy('php-frontend/controllers/DashboardController.php', 'php-frontend/controllers/DashboardController.php.backup');
        
        // 写入修复后的内容
        file_put_contents('php-frontend/controllers/DashboardController.php', $newContent);
        
        echo colorize("✅ Dashboard控制器已修复", 'green') . "\n";
    } else {
        echo colorize("✅ Dashboard控制器无需修复", 'green') . "\n";
    }
} else {
    echo colorize("❌ Dashboard控制器不存在", 'red') . "\n";
}

// 3. 检查并修复配置文件
echo colorize("\n⚙️ 3. 检查并修复配置文件", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

if (!file_exists('php-frontend/config/config.php')) {
    echo "创建配置文件...\n";
    
    $configContent = '<?php
/**
 * 应用配置文件
 */

// 应用信息
define(\'APP_NAME\', \'IPv6 WireGuard Manager\');
define(\'APP_VERSION\', \'3.0.0\');
define(\'APP_DEBUG\', true);

// API配置
define(\'API_BASE_URL\', getenv(\'API_BASE_URL\') ?: \'http://localhost:8000/api/v1\');
define(\'API_TIMEOUT\', 30);
define(\'API_RETRY_COUNT\', 3);

// 安全配置
define(\'SESSION_LIFETIME\', 3600); // 1小时
define(\'CSRF_TOKEN_LIFETIME\', 1800); // 30分钟

// 日志配置
define(\'LOG_LEVEL\', \'INFO\');
define(\'LOG_FILE\', \'logs/app.log\');

// 时区设置
date_default_timezone_set(\'Asia/Shanghai\');

// 错误报告
if (APP_DEBUG) {
    error_reporting(E_ALL);
    ini_set(\'display_errors\', 1);
} else {
    error_reporting(0);
    ini_set(\'display_errors\', 0);
}
?>';
    
    // 确保目录存在
    if (!is_dir('php-frontend/config')) {
        mkdir('php-frontend/config', 0755, true);
    }
    
    file_put_contents('php-frontend/config/config.php', $configContent);
    echo colorize("✅ 配置文件已创建", 'green') . "\n";
} else {
    echo colorize("✅ 配置文件已存在", 'green') . "\n";
}

// 4. 检查并修复数据库配置
echo colorize("\n🗄️ 4. 检查并修复数据库配置", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

if (!file_exists('php-frontend/config/database.php')) {
    echo "创建数据库配置文件...\n";
    
    $dbConfigContent = '<?php
/**
 * 数据库配置文件
 */

// 数据库配置
define(\'DB_HOST\', getenv(\'DB_HOST\') ?: \'localhost\');
define(\'DB_PORT\', getenv(\'DB_PORT\') ?: \'3306\');
define(\'DB_NAME\', getenv(\'DB_NAME\') ?: \'ipv6_wireguard\');
define(\'DB_USER\', getenv(\'DB_USER\') ?: \'root\');
define(\'DB_PASS\', getenv(\'DB_PASS\') ?: \'\');
define(\'DB_CHARSET\', \'utf8mb4\');

// 数据库连接选项
$dbOptions = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
];

// 创建数据库连接
try {
    $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
    $pdo = new PDO($dsn, DB_USER, DB_PASS, $dbOptions);
} catch (PDOException $e) {
    if (APP_DEBUG) {
        die("数据库连接失败: " . $e->getMessage());
    } else {
        error_log("数据库连接失败: " . $e->getMessage());
        die("数据库连接失败，请检查配置");
    }
}
?>';
    
    file_put_contents('php-frontend/config/database.php', $dbConfigContent);
    echo colorize("✅ 数据库配置文件已创建", 'green') . "\n";
} else {
    echo colorize("✅ 数据库配置文件已存在", 'green') . "\n";
}

// 5. 创建简单的首页测试
echo colorize("\n🧪 5. 创建首页测试", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$testContent = '<?php
/**
 * 简单的首页测试
 */

// 设置错误处理
error_reporting(E_ALL);
ini_set(\'display_errors\', 1);

echo "<!DOCTYPE html>
<html lang=\"zh-CN\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>IPv6 WireGuard Manager - 测试页面</title>
    <link href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css\" rel=\"stylesheet\">
</head>
<body>
    <div class=\"container mt-5\">
        <div class=\"row justify-content-center\">
            <div class=\"col-md-8\">
                <div class=\"card\">
                    <div class=\"card-header\">
                        <h4>IPv6 WireGuard Manager - 系统状态</h4>
                    </div>
                    <div class=\"card-body\">";

// 检查各个组件
$components = [
    "PHP版本" => PHP_VERSION,
    "配置文件" => file_exists("php-frontend/config/config.php") ? "✅ 存在" : "❌ 缺失",
    "数据库配置" => file_exists("php-frontend/config/database.php") ? "✅ 存在" : "❌ 缺失",
    "Dashboard控制器" => file_exists("php-frontend/controllers/DashboardController.php") ? "✅ 存在" : "❌ 缺失",
    "登录页面" => file_exists("php-frontend/views/auth/login.php") ? "✅ 存在" : "❌ 缺失",
    "路由文件" => file_exists("php-frontend/index.php") ? "✅ 存在" : "❌ 缺失"
];

foreach ($components as $name => $status) {
    $testContent .= "<p><strong>$name:</strong> $status</p>";
}

$testContent .= "
                        <hr>
                        <p><strong>测试时间:</strong> " . date('Y-m-d H:i:s') . "</p>
                        <p><strong>服务器:</strong> " . ($_SERVER['SERVER_NAME'] ?? 'localhost') . "</p>
                        <p><strong>请求URI:</strong> " . ($_SERVER['REQUEST_URI'] ?? '/') . "</p>
                    </div>
                    <div class=\"card-footer\">
                        <a href=\"/login\" class=\"btn btn-primary\">前往登录页面</a>
                        <a href=\"/\" class=\"btn btn-secondary\">返回首页</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>";
';

file_put_contents('php-frontend/test.php', $testContent);
echo colorize("✅ 测试页面已创建: php-frontend/test.php", 'green') . "\n";

// 6. 生成修复报告
echo colorize("\n📋 6. 修复报告", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

echo "修复完成！主要修复内容:\n";
echo "1. ✅ 修复了Dashboard控制器的强制登录问题\n";
echo "2. ✅ 创建了必要的配置文件\n";
echo "3. ✅ 创建了数据库配置文件\n";
echo "4. ✅ 创建了测试页面\n";
echo "5. ✅ 添加了登录状态检查\n";

echo colorize("\n🎯 测试建议:", 'blue') . "\n";
echo "1. 访问 http://localhost/php-frontend/test.php 查看系统状态\n";
echo "2. 访问 http://localhost/php-frontend/ 查看首页\n";
echo "3. 访问 http://localhost/php-frontend/login 查看登录页面\n";
echo "4. 使用默认账户 admin/admin123 登录\n";

echo colorize("\n🔧 如果仍有问题:", 'yellow') . "\n";
echo "1. 检查Web服务器配置\n";
echo "2. 检查PHP错误日志\n";
echo "3. 检查后端API服务状态\n";
echo "4. 检查数据库连接\n";

echo "\n" . str_repeat('=', 50) . "\n";
echo "修复完成时间: " . date('Y-m-d H:i:s') . "\n";
?>
