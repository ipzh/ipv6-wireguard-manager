<?php
/**
 * 快速PHP错误诊断脚本
 * 用于诊断80端口500错误
 */

// 启用所有错误显示
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
ini_set('log_errors', 1);

echo "<!DOCTYPE html>\n<html>\n<head>\n<title>PHP诊断</title>\n</head>\n<body>\n";
echo "<h1>PHP环境诊断</h1>\n";

echo "<h2>1. PHP版本</h2>\n";
echo "<p>" . PHP_VERSION . "</p>\n";

echo "<h2>2. PHP扩展检查</h2>\n";
$required = ['session', 'json', 'mbstring', 'filter', 'pdo', 'pdo_mysql', 'curl', 'openssl'];
echo "<ul>\n";
foreach ($required as $ext) {
    $loaded = extension_loaded($ext);
    echo "<li>" . ($loaded ? "✅" : "❌") . " $ext: " . ($loaded ? "已加载" : "未加载") . "</li>\n";
}
echo "</ul>\n";

echo "<h2>3. 文件系统检查</h2>\n";
$paths = [
    '/var/www/html/index.php' => 'index.php',
    '/var/www/html/config/config.php' => 'config.php',
    '/var/www/html/config/database.php' => 'database.php',
    '/var/www/html/config/assets.php' => 'assets.php',
    '/var/www/html/classes/SecurityEnhancer.php' => 'SecurityEnhancer.php',
];

echo "<ul>\n";
foreach ($paths as $full => $display) {
    $exists = file_exists($full);
    echo "<li>" . ($exists ? "✅" : "❌") . " $display: " . ($exists ? "存在" : "不存在");
    if ($exists) {
        echo " (权限: " . substr(sprintf('%o', fileperms($full)), -4) . ")";
    }
    echo "</li>\n";
}
echo "</ul>\n";

echo "<h2>4. 配置文件加载测试</h2>\n";
try {
    require_once '/var/www/html/config/config.php';
    echo "<p>✅ config.php 加载成功</p>\n";
} catch (Exception $e) {
    echo "<p>❌ config.php 加载失败: " . htmlspecialchars($e->getMessage()) . "</p>\n";
}

try {
    require_once '/var/www/html/config/database.php';
    echo "<p>✅ database.php 加载成功</p>\n";
} catch (Exception $e) {
    echo "<p>❌ database.php 加载失败: " . htmlspecialchars($e->getMessage()) . "</p>\n";
}

try {
    require_once '/var/www/html/config/assets.php';
    echo "<p>✅ assets.php 加载成功</p>\n";
} catch (Exception $e) {
    echo "<p>❌ assets.php 加载失败: " . htmlspecialchars($e->getMessage()) . "</p>\n";
}

echo "<h2>5. 类文件加载测试</h2>\n";
try {
    require_once '/var/www/html/classes/SecurityEnhancer.php';
    echo "<p>✅ SecurityEnhancer.php 加载成功</p>\n";
} catch (Exception $e) {
    echo "<p>❌ SecurityEnhancer.php 加载失败: " . htmlspecialchars($e->getMessage()) . "</p>\n";
}

echo "<h2>6. 权限检查</h2>\n";
$testFile = '/var/www/html/logs/test_' . time() . '.txt';
if (file_exists('/var/www/html/logs')) {
    if (is_writable('/var/www/html/logs')) {
        echo "<p>✅ /var/www/html/logs 可写</p>\n";
    } else {
        echo "<p>❌ /var/www/html/logs 不可写</p>\n";
    }
} else {
    echo "<p>❌ /var/www/html/logs 不存在</p>\n";
}

echo "<h2>7. 测试index.php加载</h2>\n";
echo "<pre>\n";
try {
    ob_start();
    // 不直接include，先看看语法
    $content = file_get_contents('/var/www/html/index.php');
    echo "文件内容长度: " . strlen($content) . " 字节\n";
    echo "文件前500字符:\n" . htmlspecialchars(substr($content, 0, 500)) . "\n";
    ob_end_clean();
} catch (Exception $e) {
    ob_end_clean();
    echo "❌ 读取index.php失败: " . htmlspecialchars($e->getMessage()) . "\n";
}
echo "</pre>\n";

echo "</body>\n</html>\n";
?>

