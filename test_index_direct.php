<?php
/**
 * 直接测试index.php的简化版本，用于诊断
 */

// 启用所有错误显示
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
ini_set('log_errors', 1);

echo "=== 开始测试 ===\n";

// 测试1: 基本PHP功能
echo "1. PHP版本: " . PHP_VERSION . "\n";

// 测试2: 配置加载
echo "2. 测试配置加载...\n";
try {
    require_once '/var/www/html/config/config.php';
    echo "   ✓ config.php 加载成功\n";
    echo "   APP_NAME: " . (defined('APP_NAME') ? APP_NAME : '未定义') . "\n";
} catch (Exception $e) {
    echo "   ✗ config.php 加载失败: " . $e->getMessage() . "\n";
    exit(1);
}

// 测试3: 数据库配置加载
echo "3. 测试database.php加载...\n";
try {
    require_once '/var/www/html/config/database.php';
    echo "   ✓ database.php 加载成功\n";
} catch (Exception $e) {
    echo "   ✗ database.php 加载失败: " . $e->getMessage() . "\n";
}

// 测试4: assets.php
echo "4. 测试assets.php加载...\n";
try {
    require_once '/var/www/html/config/assets.php';
    echo "   ✓ assets.php 加载成功\n";
} catch (Exception $e) {
    echo "   ✗ assets.php 加载失败: " . $e->getMessage() . "\n";
}

// 测试5: 核心类
echo "5. 测试核心类加载...\n";
$classes = [
    'ApiClientJWT' => '/var/www/html/classes/ApiClientJWT.php',
    'AuthJWT' => '/var/www/html/classes/AuthJWT.php',
    'Router' => '/var/www/html/classes/Router.php',
    'SecurityEnhancer' => '/var/www/html/classes/SecurityEnhancer.php',
    'ErrorHandlerJWT' => '/var/www/html/classes/ErrorHandlerJWT.php',
];

foreach ($classes as $class => $file) {
    if (!file_exists($file)) {
        echo "   ✗ $class: 文件不存在 ($file)\n";
        continue;
    }
    try {
        require_once $file;
        if (class_exists($class)) {
            echo "   ✓ $class: 加载成功\n";
        } else {
            echo "   ⚠ $class: 文件加载但类不存在\n";
        }
    } catch (Exception $e) {
        echo "   ✗ $class: 加载失败 - " . $e->getMessage() . "\n";
    } catch (Error $e) {
        echo "   ✗ $class: 致命错误 - " . $e->getMessage() . "\n";
    }
}

// 测试6: 控制器
echo "6. 测试控制器加载...\n";
$controllers = [
    'AuthController',
    'DashboardController',
    'ErrorController'
];

foreach ($controllers as $controller) {
    $file = "/var/www/html/controllers/{$controller}.php";
    if (!file_exists($file)) {
        echo "   ✗ $controller: 文件不存在\n";
        continue;
    }
    try {
        require_once $file;
        if (class_exists($controller)) {
            echo "   ✓ $controller: 加载成功\n";
        } else {
            echo "   ⚠ $controller: 文件加载但类不存在\n";
        }
    } catch (Exception $e) {
        echo "   ✗ $controller: 加载失败 - " . $e->getMessage() . "\n";
    } catch (Error $e) {
        echo "   ✗ $controller: 致命错误 - " . $e->getMessage() . "\n";
    }
}

// 测试7: 会话
echo "7. 测试会话...\n";
try {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
        echo "   ✓ 会话启动成功\n";
    } else {
        echo "   ✓ 会话已启动\n";
    }
} catch (Exception $e) {
    echo "   ✗ 会话启动失败: " . $e->getMessage() . "\n";
}

// 测试8: Router实例化
echo "8. 测试Router实例化...\n";
try {
    $router = new Router();
    echo "   ✓ Router 实例化成功\n";
} catch (Exception $e) {
    echo "   ✗ Router 实例化失败: " . $e->getMessage() . "\n";
    exit(1);
} catch (Error $e) {
    echo "   ✗ Router 致命错误: " . $e->getMessage() . "\n";
    exit(1);
}

echo "\n=== 所有测试完成 ===\n";
echo "如果所有测试通过，问题可能在Router->handleRequest()方法中\n";

