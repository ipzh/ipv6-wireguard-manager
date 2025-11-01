#!/bin/bash
# 查找500错误的具体原因

echo "=========================================="
echo "查找500错误的具体原因"
echo "=========================================="

# 1. 启用错误显示并测试index.php
echo ""
echo "1. 创建带错误显示的测试文件..."
cat > /var/www/html/test_with_errors.php << 'EOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
ini_set('log_errors', 1);

// 捕获所有输出
ob_start();

try {
    // 模拟访问根路径
    $_SERVER['REQUEST_METHOD'] = 'GET';
    $_SERVER['REQUEST_URI'] = '/';
    $_SERVER['HTTP_HOST'] = 'localhost';
    $_SERVER['SCRIPT_NAME'] = '/index.php';
    
    // 加载index.php
    require_once __DIR__ . '/index.php';
    
    $output = ob_get_clean();
    echo "=== 执行成功 ===\n";
    echo "输出长度: " . strlen($output) . " 字节\n";
    if (strlen($output) > 0) {
        echo "前500字符:\n";
        echo substr($output, 0, 500) . "\n";
    }
} catch (Exception $e) {
    ob_end_clean();
    echo "=== 捕获到异常 ===\n";
    echo "错误: " . $e->getMessage() . "\n";
    echo "文件: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "堆栈:\n" . $e->getTraceAsString() . "\n";
} catch (Error $e) {
    ob_end_clean();
    echo "=== 捕获到致命错误 ===\n";
    echo "错误: " . $e->getMessage() . "\n";
    echo "文件: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "堆栈:\n" . $e->getTraceAsString() . "\n";
} catch (Throwable $e) {
    ob_end_clean();
    echo "=== 捕获到可抛出错误 ===\n";
    echo "错误: " . $e->getMessage() . "\n";
    echo "文件: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
EOF

chmod 644 /var/www/html/test_with_errors.php
chown www-data:www-data /var/www/html/test_with_errors.php

echo "✅ 测试文件已创建"
echo "访问: http://localhost/test_with_errors.php"
echo "或者运行: php /var/www/html/test_with_errors.php"

# 2. 临时修改index.php启用错误显示
echo ""
echo "2. 备份并修改index.php以显示错误..."
sudo cp /var/www/html/index.php /var/www/html/index.php.bak

# 在index.php开头添加错误显示
sudo sed -i '2a\
error_reporting(E_ALL);\
ini_set("display_errors", 1);\
ini_set("display_startup_errors", 1);
' /var/www/html/index.php

echo "✅ index.php已修改（已备份）"
echo "⚠️  现在访问 http://localhost/ 应该能看到具体错误信息"
echo "⚠️  修复后记得还原: sudo mv /var/www/html/index.php.bak /var/www/html/index.php"

# 3. 检查关键文件
echo ""
echo "3. 检查关键文件是否存在..."
files=(
    "/var/www/html/index.php"
    "/var/www/html/classes/Router.php"
    "/var/www/html/controllers/DashboardController.php"
    "/var/www/html/views/layout/header.php"
    "/var/www/html/views/layout/footer.php"
    "/var/www/html/views/dashboard/index.php"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $(basename $file): 存在"
    else
        echo "❌ $(basename $file): 不存在 ($file)"
    fi
done

# 4. 检查文件权限
echo ""
echo "4. 检查关键文件权限..."
ls -lh /var/www/html/index.php
ls -lh /var/www/html/controllers/DashboardController.php 2>/dev/null || echo "⚠️  DashboardController.php不存在"

echo ""
echo "=========================================="
echo "下一步操作"
echo "=========================================="
echo "1. 访问 http://localhost/ 查看具体错误信息"
echo "2. 或者运行: curl http://localhost/test_with_errors.php"
echo "3. 查看PHP-FPM日志: sudo tail -50 /var/log/php8.2-fpm.log"
echo "4. 查看应用日志: sudo tail -50 /var/www/html/logs/error.log 2>/dev/null || echo '日志不存在'"

