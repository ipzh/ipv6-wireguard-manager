#!/bin/bash
# 诊断前端 500 错误的脚本

echo "=========================================="
echo "前端 500 错误诊断工具"
echo "=========================================="

FRONTEND_DIR="/var/www/html"
PHP_ERROR_LOG="/var/log/php*-fpm.log"
NGINX_ERROR_LOG="/var/log/nginx/error.log"

echo ""
echo "1. 检查 PHP 版本和扩展..."
php_version=$(php -v 2>/dev/null | head -1)
echo "   PHP 版本: $php_version"

# 检查必需扩展
required_extensions=("session" "json" "mbstring" "filter" "pdo" "pdo_mysql" "curl" "openssl")
missing_extensions=()

for ext in "${required_extensions[@]}"; do
    if ! php -m | grep -q "^$ext$"; then
        missing_extensions+=("$ext")
        echo "   ❌ 缺少扩展: $ext"
    else
        echo "   ✅ 扩展已安装: $ext"
    fi
done

if [[ ${#missing_extensions[@]} -gt 0 ]]; then
    echo ""
    echo "   ⚠️  缺少以下扩展，这可能导致 500 错误:"
    printf '   %s\n' "${missing_extensions[@]}"
fi

echo ""
echo "2. 检查前端文件..."
if [[ ! -d "$FRONTEND_DIR" ]]; then
    echo "   ❌ 前端目录不存在: $FRONTEND_DIR"
else
    echo "   ✅ 前端目录存在: $FRONTEND_DIR"
    
    # 检查关键文件
    key_files=("index.php" "config/config.php" "config/database.php" "classes/Router.php" "controllers/DashboardController.php")
    for file in "${key_files[@]}"; do
        if [[ -f "$FRONTEND_DIR/$file" ]]; then
            echo "   ✅ 文件存在: $file"
            
            # 检查文件权限
            perms=$(stat -c "%a" "$FRONTEND_DIR/$file" 2>/dev/null || stat -f "%OLp" "$FRONTEND_DIR/$file" 2>/dev/null)
            owner=$(stat -c "%U:%G" "$FRONTEND_DIR/$file" 2>/dev/null || stat -f "%Su:%Sg" "$FRONTEND_DIR/$file" 2>/dev/null)
            echo "      权限: $perms, 所有者: $owner"
        else
            echo "   ❌ 文件不存在: $file"
        fi
    done
fi

echo ""
echo "3. 检查 PHP 语法错误..."
if [[ -f "$FRONTEND_DIR/index.php" ]]; then
    php_syntax=$(php -l "$FRONTEND_DIR/index.php" 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "   ✅ index.php 语法正确"
    else
        echo "   ❌ index.php 语法错误:"
        echo "   $php_syntax"
    fi
    
    # 检查其他关键文件
    key_files=("config/config.php" "config/database.php" "classes/Router.php")
    for file in "${key_files[@]}"; do
        if [[ -f "$FRONTEND_DIR/$file" ]]; then
            php_syntax=$(php -l "$FRONTEND_DIR/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                echo "   ✅ $file 语法正确"
            else
                echo "   ❌ $file 语法错误:"
                echo "   $php_syntax"
            fi
        fi
    done
fi

echo ""
echo "4. 检查配置文件..."
if [[ -f "$FRONTEND_DIR/config/config.php" ]]; then
    # 尝试解析配置
    php -r "
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    try {
        require_once '$FRONTEND_DIR/config/config.php';
        echo '   ✅ config.php 加载成功\n';
        echo '   APP_NAME: ' . (defined('APP_NAME') ? APP_NAME : '未定义') . '\n';
    } catch (Exception \$e) {
        echo '   ❌ config.php 加载失败: ' . \$e->getMessage() . '\n';
    }
    "
fi

if [[ -f "$FRONTEND_DIR/config/database.php" ]]; then
    php -r "
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    try {
        require_once '$FRONTEND_DIR/config/database.php';
        echo '   ✅ database.php 加载成功\n';
    } catch (Exception \$e) {
        echo '   ❌ database.php 加载失败: ' . \$e->getMessage() . '\n';
    }
    "
fi

echo ""
echo "5. 检查类文件..."
if [[ -f "$FRONTEND_DIR/classes/Router.php" ]]; then
    php -r "
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    try {
        require_once '$FRONTEND_DIR/classes/Router.php';
        if (class_exists('Router')) {
            echo '   ✅ Router 类可以加载\n';
        } else {
            echo '   ❌ Router 类无法加载\n';
        }
    } catch (Exception \$e) {
        echo '   ❌ Router.php 加载失败: ' . \$e->getMessage() . '\n';
    }
    "
fi

echo ""
echo "6. 检查 PHP-FPM 错误日志..."
php_log_files=(
    "/var/log/php*-fpm.log"
    "/var/log/php8.2-fpm.log"
    "/var/log/php8.1-fpm.log"
    "/var/log/php8.0-fpm.log"
    "$FRONTEND_DIR/logs/php_errors.log"
    "$FRONTEND_DIR/logs/error.log"
)

found_logs=false
for log_pattern in "${php_log_files[@]}"; do
    for log_file in $log_pattern; do
        if [[ -f "$log_file" && -r "$log_file" ]]; then
            found_logs=true
            echo "   检查日志: $log_file"
            recent_errors=$(tail -20 "$log_file" 2>/dev/null | grep -i "error\|fatal\|warning" | tail -5)
            if [[ -n "$recent_errors" ]]; then
                echo "   最近错误:"
                echo "$recent_errors" | sed 's/^/   /'
            else
                echo "   ✅ 无最近错误"
            fi
        fi
    done
done

if [[ "$found_logs" == "false" ]]; then
    echo "   ⚠️  未找到 PHP 错误日志"
fi

echo ""
echo "7. 检查 Nginx 错误日志..."
if [[ -f "$NGINX_ERROR_LOG" && -r "$NGINX_ERROR_LOG" ]]; then
    echo "   检查日志: $NGINX_ERROR_LOG"
    recent_errors=$(tail -20 "$NGINX_ERROR_LOG" 2>/dev/null | grep -i "500\|error\|fatal\|php" | tail -5)
    if [[ -n "$recent_errors" ]]; then
        echo "   最近错误:"
        echo "$recent_errors" | sed 's/^/   /'
    else
        echo "   ✅ 无最近错误"
    fi
else
    echo "   ⚠️  未找到 Nginx 错误日志"
fi

echo ""
echo "8. 测试 PHP 文件执行..."
if [[ -f "$FRONTEND_DIR/index.php" ]]; then
    echo "   尝试执行 index.php..."
    
    # 创建一个测试脚本
    test_script="/tmp/test_index.php"
    cat > "$test_script" << 'TESTEOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

// 模拟基本环境
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/';
$_SERVER['HTTP_HOST'] = 'localhost';
$_SERVER['SERVER_NAME'] = 'localhost';

// 设置路径
$frontend_dir = getenv('FRONTEND_DIR') ?: '/var/www/html';
chdir($frontend_dir);

try {
    // 只加载到路由之前
    if (file_exists('config/config.php')) {
        require_once 'config/config.php';
        echo "Config loaded\n";
    }
    
    // 测试类加载
    $classes = [
        'classes/Router.php',
        'classes/AuthJWT.php',
        'classes/SecurityEnhancer.php'
    ];
    
    foreach ($classes as $class_file) {
        if (file_exists($class_file)) {
            require_once $class_file;
            echo "Loaded: $class_file\n";
        } else {
            echo "Missing: $class_file\n";
        }
    }
    
} catch (Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . "\n";
    echo "Line: " . $e->getLine() . "\n";
    exit(1);
}
TESTEOF
    
    export FRONTEND_DIR="$FRONTEND_DIR"
    test_output=$(php "$test_script" 2>&1)
    test_exit=$?
    
    if [[ $test_exit -eq 0 ]]; then
        echo "   ✅ 基本测试通过"
        echo "$test_output" | sed 's/^/   /'
    else
        echo "   ❌ 测试失败:"
        echo "$test_output" | sed 's/^/   /'
    fi
    
    rm -f "$test_script"
fi

echo ""
echo "9. 检查文件权限..."
if [[ -d "$FRONTEND_DIR" ]]; then
    web_user=$(ps aux | grep -E "nginx|apache|www-data" | grep -v grep | head -1 | awk '{print $1}')
    if [[ -z "$web_user" ]]; then
        web_user="www-data"
    fi
    
    echo "   Web 用户: $web_user"
    echo "   目录权限:"
    ls -ld "$FRONTEND_DIR" | awk '{print "   " $1 " " $3 ":" $4 " " $9}'
    
    # 检查关键目录权限
    key_dirs=("config" "classes" "controllers" "views" "logs")
    for dir in "${key_dirs[@]}"; do
        if [[ -d "$FRONTEND_DIR/$dir" ]]; then
            dir_perms=$(stat -c "%a" "$FRONTEND_DIR/$dir" 2>/dev/null || stat -f "%OLp" "$FRONTEND_DIR/$dir" 2>/dev/null)
            dir_owner=$(stat -c "%U:%G" "$FRONTEND_DIR/$dir" 2>/dev/null || stat -f "%Su:%Sg" "$FRONTEND_DIR/$dir" 2>/dev/null)
            echo "   $dir/: $dir_perms ($dir_owner)"
        fi
    done
fi

echo ""
echo "10. 检查会话目录权限..."
session_save_path=$(php -r "echo session_save_path();" 2>/dev/null || echo "/var/lib/php/sessions")
if [[ -n "$session_save_path" && "$session_save_path" != "" ]]; then
    if [[ -d "$session_save_path" ]]; then
        session_perms=$(stat -c "%a" "$session_save_path" 2>/dev/null || stat -f "%OLp" "$session_save_path" 2>/dev/null)
        session_owner=$(stat -c "%U:%G" "$session_save_path" 2>/dev/null || stat -f "%Su:%Sg" "$session_save_path" 2>/dev/null)
        echo "   ✅ 会话目录: $session_save_path ($session_perms, $session_owner)"
        
        if [[ ! -w "$session_save_path" ]]; then
            echo "   ⚠️  会话目录不可写，可能导致 500 错误"
        fi
    else
        echo "   ⚠️  会话目录不存在: $session_save_path"
    fi
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "修复建议:"
echo ""
echo "1. 如果缺少 PHP 扩展:"
echo "   sudo apt-get install php8.1-{session,json,mbstring,curl,openssl,mysql}"
echo ""
echo "2. 如果文件权限问题:"
echo "   sudo chown -R www-data:www-data $FRONTEND_DIR"
echo "   sudo chmod -R 755 $FRONTEND_DIR"
echo "   sudo chmod -R 777 $FRONTEND_DIR/logs"
echo ""
echo "3. 如果会话目录权限问题:"
echo "   sudo chmod 1777 $session_save_path"
echo "   sudo chown www-data:www-data $session_save_path"
echo ""
echo "4. 启用 PHP 错误显示（临时调试）:"
echo "   在 $FRONTEND_DIR/config/config.php 中设置:"
echo "   define('APP_DEBUG', true);"
echo ""

