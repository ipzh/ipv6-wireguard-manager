#!/bin/bash
# 80端口500错误快速诊断脚本

echo "=========================================="
echo "80端口500错误诊断"
echo "=========================================="

echo ""
echo "1. 检查PHP-FPM服务状态..."
sudo systemctl status php8.2-fpm --no-pager | head -15

echo ""
echo "2. 检查PHP-FPM错误日志..."
sudo tail -30 /var/log/php8.2-fpm.log 2>/dev/null || echo "⚠️ 日志文件不存在"

echo ""
echo "3. 检查Nginx错误日志..."
sudo tail -30 /var/log/nginx/error.log

echo ""
echo "4. 检查index.php文件是否存在..."
ls -lh /var/www/html/index.php 2>/dev/null || echo "❌ index.php不存在"

echo ""
echo "5. 检查文件权限..."
ls -ld /var/www/html
ls -lh /var/www/html/index.php

echo ""
echo "6. 测试PHP是否可以直接执行..."
cd /var/www/html 2>/dev/null && php -r "echo 'PHP CLI works\n';" 2>&1 || echo "❌ PHP CLI不可用"

echo ""
echo "7. 检查必需的PHP扩展..."
php -m 2>/dev/null | grep -E "session|json|mbstring|filter|pdo|pdo_mysql|curl|openssl" || echo "⚠️ 部分扩展缺失"

echo ""
echo "8. 测试配置文件是否能加载..."
php -r "
require_once '/var/www/html/config/config.php';
echo 'Config loaded: ' . (defined('APP_NAME') ? APP_NAME : 'Failed') . PHP_EOL;
" 2>&1 | head -20 || echo "❌ 配置文件加载失败"

echo ""
echo "=========================================="
echo "诊断完成 - 请查看上面的输出查找问题"
echo "=========================================="
echo ""
echo "如果仍无法解决，请运行以下命令获取更详细的错误信息："
echo "  sudo tail -50 /var/log/php8.2-fpm.log"
echo "  sudo tail -50 /var/log/nginx/error.log"
echo "  php -f /var/www/html/index.php"

