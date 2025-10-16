<?php
/**
 * 前端首页测试脚本
 */

echo "🧪 IPv6 WireGuard Manager - 前端首页测试\n";
echo "==========================================\n\n";

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

// 测试配置
echo colorize("📋 测试配置:", 'blue') . "\n";
echo "前端目录: " . __DIR__ . "/php-frontend\n";
echo "测试URL: http://localhost/php-frontend/\n\n";

// 1. 检查文件存在性
echo colorize("🔍 1. 检查文件存在性", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$requiredFiles = [
    'php-frontend/index.php' => '主入口文件',
    'php-frontend/controllers/DashboardController.php' => '仪表板控制器',
    'php-frontend/views/dashboard/index.php' => '仪表板视图',
    'php-frontend/views/layout/header.php' => '页面头部',
    'php-frontend/views/layout/footer.php' => '页面底部',
    'php-frontend/config/config.php' => '配置文件',
    'php-frontend/classes/Router.php' => '路由类',
    'php-frontend/classes/ApiClient.php' => 'API客户端',
    'php-frontend/classes/Auth.php' => '认证类'
];

$fileStatus = [];
foreach ($requiredFiles as $file => $description) {
    if (file_exists($file)) {
        echo colorize("✅ $description", 'green') . " - $file\n";
        $fileStatus[$file] = 'exists';
    } else {
        echo colorize("❌ $description", 'red') . " - $file (缺失)\n";
        $fileStatus[$file] = 'missing';
    }
}

// 2. 检查PHP语法
echo colorize("\n🔧 2. 检查PHP语法", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$phpFiles = [
    'php-frontend/index.php',
    'php-frontend/controllers/DashboardController.php',
    'php-frontend/views/dashboard/index.php'
];

foreach ($phpFiles as $file) {
    if (file_exists($file)) {
        echo "检查 $file... ";
        
        // 使用php -l检查语法
        $output = [];
        $returnCode = 0;
        exec("php -l \"$file\" 2>&1", $output, $returnCode);
        
        if ($returnCode === 0) {
            echo colorize("✅ 语法正确", 'green') . "\n";
        } else {
            echo colorize("❌ 语法错误", 'red') . "\n";
            foreach ($output as $line) {
                echo "  $line\n";
            }
        }
    }
}

// 3. 检查配置
echo colorize("\n⚙️ 3. 检查配置", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

if (file_exists('php-frontend/config/config.php')) {
    try {
        require_once 'php-frontend/config/config.php';
        echo colorize("✅ 配置文件加载成功", 'green') . "\n";
        
        // 检查必要的常量
        $requiredConstants = ['APP_NAME', 'APP_VERSION', 'API_BASE_URL'];
        foreach ($requiredConstants as $constant) {
            if (defined($constant)) {
                echo "  ✅ $constant: " . constant($constant) . "\n";
            } else {
                echo colorize("  ❌ $constant 未定义", 'red') . "\n";
            }
        }
    } catch (Exception $e) {
        echo colorize("❌ 配置文件加载失败: " . $e->getMessage(), 'red') . "\n";
    }
} else {
    echo colorize("❌ 配置文件不存在", 'red') . "\n";
}

// 4. 检查路由
echo colorize("\n🛣️ 4. 检查路由", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

if (file_exists('php-frontend/classes/Router.php')) {
    try {
        require_once 'php-frontend/classes/Router.php';
        echo colorize("✅ 路由类加载成功", 'green') . "\n";
        
        // 检查Router类方法
        $routerMethods = ['addRoute', 'handleRequest', 'currentPath'];
        foreach ($routerMethods as $method) {
            if (method_exists('Router', $method)) {
                echo "  ✅ Router::$method 方法存在\n";
            } else {
                echo colorize("  ❌ Router::$method 方法不存在", 'red') . "\n";
            }
        }
    } catch (Exception $e) {
        echo colorize("❌ 路由类加载失败: " . $e->getMessage(), 'red') . "\n";
    }
} else {
    echo colorize("❌ 路由类不存在", 'red') . "\n";
}

// 5. 检查控制器
echo colorize("\n🎮 5. 检查控制器", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

if (file_exists('php-frontend/controllers/DashboardController.php')) {
    try {
        require_once 'php-frontend/controllers/DashboardController.php';
        echo colorize("✅ Dashboard控制器加载成功", 'green') . "\n";
        
        // 检查控制器方法
        $controllerMethods = ['index', 'getDashboardData', 'getRealtimeData'];
        foreach ($controllerMethods as $method) {
            if (method_exists('DashboardController', $method)) {
                echo "  ✅ DashboardController::$method 方法存在\n";
            } else {
                echo colorize("  ❌ DashboardController::$method 方法不存在", 'red') . "\n";
            }
        }
    } catch (Exception $e) {
        echo colorize("❌ Dashboard控制器加载失败: " . $e->getMessage(), 'red') . "\n";
    }
} else {
    echo colorize("❌ Dashboard控制器不存在", 'red') . "\n";
}

// 6. 检查视图文件
echo colorize("\n👁️ 6. 检查视图文件", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$viewFiles = [
    'php-frontend/views/dashboard/index.php' => '仪表板视图',
    'php-frontend/views/layout/header.php' => '页面头部',
    'php-frontend/views/layout/footer.php' => '页面底部'
];

foreach ($viewFiles as $file => $description) {
    if (file_exists($file)) {
        echo colorize("✅ $description", 'green') . " - $file\n";
        
        // 检查文件大小
        $fileSize = filesize($file);
        echo "  文件大小: " . number_format($fileSize) . " 字节\n";
        
        // 检查是否包含必要的HTML标签
        $content = file_get_contents($file);
        if (strpos($content, '<html') !== false || strpos($content, '<div') !== false) {
            echo "  ✅ 包含HTML内容\n";
        } else {
            echo colorize("  ⚠️ 可能缺少HTML内容", 'yellow') . "\n";
        }
    } else {
        echo colorize("❌ $description", 'red') . " - $file (缺失)\n";
    }
}

// 7. 模拟首页访问
echo colorize("\n🌐 7. 模拟首页访问", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

// 设置环境变量
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/';
$_SERVER['HTTP_HOST'] = 'localhost';

// 捕获输出
ob_start();
try {
    // 模拟包含index.php
    if (file_exists('php-frontend/index.php')) {
        // 设置错误处理
        set_error_handler(function($severity, $message, $file, $line) {
            throw new ErrorException($message, 0, $severity, $file, $line);
        });
        
        // 尝试执行index.php
        include 'php-frontend/index.php';
        
        $output = ob_get_contents();
        ob_end_clean();
        
        if (!empty($output)) {
            echo colorize("✅ 首页可以正常输出内容", 'green') . "\n";
            echo "输出长度: " . strlen($output) . " 字符\n";
            
            // 检查输出内容
            if (strpos($output, '<html') !== false) {
                echo "✅ 包含HTML结构\n";
            }
            if (strpos($output, 'IPv6 WireGuard') !== false) {
                echo "✅ 包含应用标题\n";
            }
            if (strpos($output, 'bootstrap') !== false) {
                echo "✅ 包含Bootstrap样式\n";
            }
        } else {
            echo colorize("⚠️ 首页输出为空", 'yellow') . "\n";
        }
    } else {
        echo colorize("❌ 首页文件不存在", 'red') . "\n";
    }
} catch (Exception $e) {
    ob_end_clean();
    echo colorize("❌ 首页访问失败: " . $e->getMessage(), 'red') . "\n";
} catch (Error $e) {
    ob_end_clean();
    echo colorize("❌ 首页访问错误: " . $e->getMessage(), 'red') . "\n";
}

// 8. 生成测试报告
echo colorize("\n📋 8. 测试报告", 'blue') . "\n";
echo str_repeat('-', 50) . "\n";

$totalFiles = count($requiredFiles);
$existingFiles = count(array_filter($fileStatus, function($status) {
    return $status === 'exists';
}));
$missingFiles = $totalFiles - $existingFiles;

echo "总文件数: $totalFiles\n";
echo colorize("存在文件: $existingFiles", 'green') . "\n";
echo colorize("缺失文件: $missingFiles", 'red') . "\n";

$successRate = round(($existingFiles / $totalFiles) * 100, 2);
echo "文件完整率: $successRate%\n";

if ($successRate >= 90) {
    echo colorize("\n🎉 前端首页检查通过！", 'green') . "\n";
} elseif ($successRate >= 70) {
    echo colorize("\n⚠️ 前端首页基本正常，但有一些问题需要修复", 'yellow') . "\n";
} else {
    echo colorize("\n❌ 前端首页存在严重问题，需要修复", 'red') . "\n";
}

echo "\n" . str_repeat('=', 50) . "\n";
echo "测试完成时间: " . date('Y-m-d H:i:s') . "\n";
?>
