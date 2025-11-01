#!/bin/bash
# 最终修复500错误的脚本

echo "=========================================="
echo "修复500错误 - 最终方案"
echo "=========================================="

# 1. 临时启用错误显示
echo ""
echo "1. 启用错误显示..."
sudo cp /var/www/html/index.php /var/www/html/index.php.bak.$(date +%Y%m%d_%H%M%S)

# 在index.php开头添加错误显示
sudo sed -i '2a\
error_reporting(E_ALL);\
ini_set("display_errors", 1);\
ini_set("display_startup_errors", 1);
' /var/www/html/index.php

echo "✅ index.php已修改（已备份）"

# 2. 修复DashboardController中的相对路径
echo ""
echo "2. 修复DashboardController中的include路径..."
DASHBOARD_CTRL="/var/www/html/controllers/DashboardController.php"
if [ -f "$DASHBOARD_CTRL" ]; then
    sudo cp "$DASHBOARD_CTRL" "${DASHBOARD_CTRL}.bak"
    
    # 修复include路径 - 使用绝对路径
    sudo sed -i "s|include 'views/|include __DIR__ . '/../views/|g" "$DASHBOARD_CTRL"
    sudo sed -i "s|include \"views/|include __DIR__ . '/../views/|g" "$DASHBOARD_CTRL"
    
    echo "✅ DashboardController路径已修复"
    
    # 检查语法
    php -l "$DASHBOARD_CTRL"
else
    echo "⚠️  DashboardController.php不存在"
fi

# 3. 修复其他控制器中的相对路径
echo ""
echo "3. 修复其他控制器中的include路径..."
for ctrl in /var/www/html/controllers/*.php; do
    if [ -f "$ctrl" ]; then
        # 只修复相对路径，不修复已使用__DIR__的
        sudo sed -i "s|include 'views/|include __DIR__ . '/../views/|g" "$ctrl"
        sudo sed -i "s|include \"views/|include __DIR__ . '/../views/|g" "$ctrl"
    fi
done
echo "✅ 所有控制器路径已修复"

# 4. 检查ApiPathBuilder是否存在
echo ""
echo "4. 检查ApiPathBuilder..."
if [ -f "/var/www/html/includes/ApiPathBuilder/index.php" ]; then
    echo "✅ ApiPathBuilder存在"
else
    echo "⚠️  ApiPathBuilder不存在，但可能不是必需的"
fi

# 5. 重启服务
echo ""
echo "5. 重启服务..."
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx
echo "✅ 服务已重启"

echo ""
echo "=========================================="
echo "修复完成"
echo "=========================================="
echo ""
echo "现在请："
echo "1. 访问 http://localhost/ 查看是否还有错误"
echo "2. 如果仍有错误，现在应该能看到具体的错误信息了"
echo "3. 修复后，记得还原index.php:"
echo "   sudo mv /var/www/html/index.php.bak.* /var/www/html/index.php"
echo ""
echo "查看错误日志："
echo "  sudo tail -50 /var/log/nginx/error.log"
echo "  sudo tail -50 /var/log/php8.2-fpm.log"

