#!/bin/bash
# 修复前端 500 错误的脚本

echo "=========================================="
echo "前端 500 错误修复工具"
echo "=========================================="

FRONTEND_DIR="/var/www/html"

# 检测 Web 用户
web_user=$(ps aux | grep -E "nginx|apache|www-data" | grep -v grep | head -1 | awk '{print $1}')
if [[ -z "$web_user" ]]; then
    if id www-data &>/dev/null; then
        web_user="www-data"
    elif id nginx &>/dev/null; then
        web_user="nginx"
    elif id apache &>/dev/null; then
        web_user="apache"
    else
        web_user="www-data"
        echo "⚠️  无法检测 Web 用户，使用默认: $web_user"
    fi
fi

echo "检测到的 Web 用户: $web_user"
echo ""

# 1. 修复文件权限
echo "1. 修复文件权限..."
if [[ -d "$FRONTEND_DIR" ]]; then
    sudo chown -R "$web_user:$web_user" "$FRONTEND_DIR"
    sudo find "$FRONTEND_DIR" -type d -exec chmod 755 {} \;
    sudo find "$FRONTEND_DIR" -type f -exec chmod 644 {} \;
    
    # 日志目录需要写权限
    if [[ -d "$FRONTEND_DIR/logs" ]]; then
        sudo chmod -R 775 "$FRONTEND_DIR/logs"
        sudo chown -R "$web_user:$web_user" "$FRONTEND_DIR/logs"
    fi
    
    echo "   ✅ 文件权限已修复"
else
    echo "   ❌ 前端目录不存在: $FRONTEND_DIR"
    exit 1
fi

# 2. 修复会话目录权限
echo ""
echo "2. 修复会话目录权限..."
session_path=$(php -r "echo session_save_path() ?: '/var/lib/php/sessions';" 2>/dev/null)

# 尝试多个可能的会话路径
possible_session_paths=(
    "$session_path"
    "/var/lib/php/sessions"
    "/var/lib/php7.*/sessions"
    "/var/lib/php8.*/sessions"
    "/tmp"
)

for path in "${possible_session_paths[@]}"; do
    # 处理通配符
    for expanded_path in $path; do
        if [[ -d "$expanded_path" ]]; then
            sudo chmod 1733 "$expanded_path" 2>/dev/null || sudo chmod 1777 "$expanded_path" 2>/dev/null
            sudo chown -R "$web_user:$web_user" "$expanded_path" 2>/dev/null
            echo "   ✅ 会话目录权限已修复: $expanded_path"
            break 2
        fi
    done
done

# 3. 启用错误显示（临时）
echo ""
echo "3. 配置错误显示..."
if [[ -f "$FRONTEND_DIR/config/config.php" ]]; then
    # 备份原文件
    sudo cp "$FRONTEND_DIR/config/config.php" "$FRONTEND_DIR/config/config.php.bak"
    
    # 启用调试模式（如果有问题的话）
    if ! grep -q "APP_DEBUG.*true" "$FRONTEND_DIR/config/config.php"; then
        sudo sed -i "s/define('APP_DEBUG'.*/define('APP_DEBUG', true);/" "$FRONTEND_DIR/config/config.php" 2>/dev/null || \
        sudo sed -i "s|define(\"APP_DEBUG\".*|define(\"APP_DEBUG\", true);|" "$FRONTEND_DIR/config/config.php" 2>/dev/null
    fi
    
    echo "   ✅ 已启用调试模式（临时）"
fi

# 4. 创建缺失的目录
echo ""
echo "4. 创建缺失的目录..."
required_dirs=("logs" "cache" "uploads" "tmp")
for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$FRONTEND_DIR/$dir" ]]; then
        sudo mkdir -p "$FRONTEND_DIR/$dir"
        sudo chown "$web_user:$web_user" "$FRONTEND_DIR/$dir"
        sudo chmod 775 "$FRONTEND_DIR/$dir"
        echo "   ✅ 创建目录: $dir"
    fi
done

# 5. 修复 PHP 配置文件中的错误报告
echo ""
echo "5. 修复 PHP 错误处理配置..."
if [[ -f "$FRONTEND_DIR/config/config.php" ]]; then
    # 确保错误报告启用（用于调试）
    if ! grep -q "error_reporting(E_ALL)" "$FRONTEND_DIR/config/config.php"; then
        # 在 APP_DEBUG 设置后添加错误报告
        sudo sed -i "/define('APP_DEBUG'/a\\
// 错误报告配置\\
if (APP_DEBUG) {\\
    error_reporting(E_ALL);\\
    ini_set('display_errors', 1);\\
} else {\\
    error_reporting(E_ALL \& ~E_NOTICE \& ~E_WARNING);\\
    ini_set('display_errors', 0);\\
}" "$FRONTEND_DIR/config/config.php" 2>/dev/null || \
        sudo sed -i "/define(\"APP_DEBUG\"/a\\
// 错误报告配置\\
if (APP_DEBUG) {\\
    error_reporting(E_ALL);\\
    ini_set('display_errors', 1);\\
} else {\\
    error_reporting(E_ALL \& ~E_NOTICE \& ~E_WARNING);\\
    ini_set('display_errors', 0);\\
}" "$FRONTEND_DIR/config/config.php" 2>/dev/null
    fi
fi

# 6. 创建测试 PHP 文件
echo ""
echo "6. 创建测试文件..."
test_file="$FRONTEND_DIR/test_php.php"
sudo tee "$test_file" > /dev/null << 'TESTEOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "PHP Version: " . PHP_VERSION . "\n";
echo "Server: " . ($_SERVER['SERVER_SOFTWARE'] ?? 'Unknown') . "\n";
echo "Document Root: " . ($_SERVER['DOCUMENT_ROOT'] ?? 'Unknown') . "\n";

// 测试扩展
$required = ['session', 'json', 'mbstring', 'curl', 'openssl', 'pdo', 'pdo_mysql'];
foreach ($required as $ext) {
    echo ($ext . ": " . (extension_loaded($ext) ? "✅" : "❌") . "\n");
}

// 测试文件权限
echo "Current dir writable: " . (is_writable('.') ? "✅" : "❌") . "\n";

// 测试会话
echo "Session save path: " . (session_save_path() ?: '/var/lib/php/sessions') . "\n";
$session_path = session_save_path() ?: '/var/lib/php/sessions';
echo "Session path writable: " . (is_writable($session_path) ? "✅" : "❌") . "\n";

echo "✅ PHP 测试成功\n";
TESTEOF

sudo chown "$web_user:$web_user" "$test_file"
sudo chmod 644 "$test_file"
echo "   ✅ 测试文件已创建: /test_php.php"
echo "   访问 http://服务器地址/test_php.php 查看详细信息"

# 7. 检查并修复数据库配置
echo ""
echo "7. 检查数据库配置..."
if [[ -f "$FRONTEND_DIR/config/database.php" ]]; then
    # 检查环境变量
    if [[ -z "${DB_PASS:-}" ]]; then
        echo "   ⚠️  DB_PASS 环境变量未设置"
        echo "   请设置正确的数据库密码环境变量"
    fi
    
    # 测试数据库连接
    php -r "
    try {
        require_once '$FRONTEND_DIR/config/database.php';
        \$db = Database::getInstance();
        echo '   ✅ 数据库配置正确\n';
    } catch (Exception \$e) {
        echo '   ❌ 数据库配置错误: ' . \$e->getMessage() . '\n';
        echo '   提示: 检查环境变量 DB_HOST, DB_NAME, DB_USER, DB_PASS\n';
    }
    " 2>&1
fi

echo ""
echo "=========================================="
echo "修复完成"
echo "=========================================="
echo ""
echo "下一步操作:"
echo "1. 访问 http://服务器地址/test_php.php 查看 PHP 信息"
echo "2. 检查错误日志:"
echo "   sudo tail -f /var/log/nginx/error.log"
echo "   sudo tail -f /var/log/php*-fpm.log"
echo "   sudo tail -f $FRONTEND_DIR/logs/error.log"
echo ""
echo "3. 如果仍有问题，查看具体错误信息："
echo "   - 访问 http://服务器地址/ 查看错误详情"
echo "   - 检查浏览器开发者工具中的 Network 标签"
echo ""
echo "4. 修复后记得禁用调试模式："
echo "   编辑 $FRONTEND_DIR/config/config.php"
echo "   设置 define('APP_DEBUG', false);"
echo ""

