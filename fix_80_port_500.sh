#!/bin/bash
# 80端口500错误修复脚本

echo "=========================================="
echo "80端口500错误修复脚本"
echo "=========================================="

# 1. 启用PHP错误显示（临时调试）
echo ""
echo "1. 创建临时调试PHP文件..."
cat > /var/www/html/debug_test.php << 'PHP_EOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '/var/www/html/logs/php_debug.log');

echo "PHP Version: " . PHP_VERSION . "\n";
echo "SAPI: " . php_sapi_name() . "\n\n";

echo "Testing config loading...\n";
try {
    require_once __DIR__ . '/config/config.php';
    echo "✓ config.php loaded\n";
} catch (Exception $e) {
    echo "✗ config.php error: " . $e->getMessage() . "\n";
    exit(1);
}

echo "Testing database.php loading...\n";
try {
    require_once __DIR__ . '/config/database.php';
    echo "✓ database.php loaded\n";
} catch (Exception $e) {
    echo "✗ database.php error: " . $e->getMessage() . "\n";
}

echo "Testing assets.php loading...\n";
try {
    require_once __DIR__ . '/config/assets.php';
    echo "✓ assets.php loaded\n";
} catch (Exception $e) {
    echo "✗ assets.php error: " . $e->getMessage() . "\n";
}

echo "Testing SecurityEnhancer class...\n";
try {
    require_once __DIR__ . '/classes/SecurityEnhancer.php';
    echo "✓ SecurityEnhancer loaded\n";
} catch (Exception $e) {
    echo "✗ SecurityEnhancer error: " . $e->getMessage() . "\n";
}

echo "\nAll tests passed!\n";
PHP_EOF

chmod 644 /var/www/html/debug_test.php
chown www-data:www-data /var/www/html/debug_test.php

echo "✅ 调试文件已创建: /var/www/html/debug_test.php"
echo "访问: http://localhost/debug_test.php"

# 2. 检查并修复logs目录
echo ""
echo "2. 检查logs目录..."
if [ ! -d "/var/www/html/logs" ]; then
    mkdir -p /var/www/html/logs
    echo "✅ 创建logs目录"
fi
chown -R www-data:www-data /var/www/html/logs
chmod 775 /var/www/html/logs
echo "✅ logs目录权限已设置"

# 3. 修复PHP配置以显示错误（仅用于调试）
echo ""
echo "3. 检查PHP配置..."
if [ -f "/etc/php/8.2/fpm/php.ini" ]; then
    echo "检查PHP-FPM php.ini..."
    grep -q "display_errors" /etc/php/8.2/fpm/php.ini || echo "display_errors = On" | sudo tee -a /etc/php/8.2/fpm/php.ini
    grep -q "display_startup_errors" /etc/php/8.2/fpm/php.ini || echo "display_startup_errors = On" | sudo tee -a /etc/php/8.2/fpm/php.ini
    echo "✅ PHP配置已更新（仅用于调试）"
fi

# 4. 测试index.php并捕获错误
echo ""
echo "4. 测试index.php执行..."
cd /var/www/html
php -f index.php 2>&1 | tee /tmp/index_php_output.txt | head -100
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ index.php执行失败，查看完整输出:"
    cat /tmp/index_php_output.txt
fi

# 5. 检查Nginx最新错误
echo ""
echo "5. 检查Nginx最新错误日志..."
sudo tail -20 /var/log/nginx/error.log | grep -i error || echo "无错误信息"

# 6. 检查PHP-FPM最新错误
echo ""
echo "6. 检查PHP-FPM最新错误日志..."
sudo tail -20 /var/log/php8.2-fpm.log | grep -i -E "error|warning|fatal" || echo "无错误信息"

# 7. 测试PHP-FPM连接
echo ""
echo "7. 测试PHP-FPM socket连接..."
if [ -S /var/run/php/php8.2-fpm.sock ]; then
    echo "✅ Socket文件存在"
    ls -lh /var/run/php/php8.2-fpm.sock
else
    echo "❌ Socket文件不存在"
fi

# 8. 重启服务
echo ""
echo "8. 重启服务..."
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx
echo "✅ 服务已重启"

echo ""
echo "=========================================="
echo "修复脚本执行完成"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 访问 http://localhost/debug_test.php 查看详细测试结果"
echo "2. 检查 /var/www/html/logs/php_debug.log"
echo "3. 访问 http://localhost/ 看是否还有500错误"
echo "4. 如果仍有错误，查看: sudo tail -50 /var/log/nginx/error.log"

