#!/bin/bash
# 诊断80端口500错误的快速脚本

echo "=========================================="
echo "80端口500错误诊断"
echo "=========================================="

echo ""
echo "1. 检查PHP-FPM服务状态..."
sudo systemctl status php8.2-fpm --no-pager | head -20

echo ""
echo "2. 检查PHP-FPM socket是否存在..."
ls -lh /var/run/php/php8.2-fpm.sock 2>/dev/null || echo "❌ Socket文件不存在"

echo ""
echo "3. 检查PHP-FPM错误日志..."
sudo tail -20 /var/log/php8.2-fpm.log 2>/dev/null || echo "❌ 日志不存在"

echo ""
echo "4. 检查Nginx错误日志..."
sudo tail -20 /var/log/nginx/error.log

echo ""
echo "5. 测试index.php是否能直接执行..."
cd /var/www/html
php -f index.php 2>&1 | head -30

echo ""
echo "6. 检查文件权限..."
ls -ld /var/www/html
ls -ld /var/www/html/index.php

echo ""
echo "7. 检查PHP扩展..."
php -m | grep -E "session|json|mbstring|curl|openssl"

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="

