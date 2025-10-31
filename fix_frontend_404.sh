#!/bin/bash
# 修复前端 404 问题的诊断和修复脚本

echo "=========================================="
echo "前端 404 问题诊断与修复工具"
echo "=========================================="

FRONTEND_DIR="/var/www/html"
NGINX_CONF="/etc/nginx/sites-available/ipv6-wireguard-manager"

# 检查 Nginx 配置是否存在
if [[ ! -f "$NGINX_CONF" ]]; then
    NGINX_CONF="/etc/nginx/conf.d/ipv6-wireguard-manager.conf"
fi

if [[ ! -f "$NGINX_CONF" ]]; then
    echo "❌ 未找到 Nginx 配置文件"
    echo "   尝试查找配置文件..."
    find /etc/nginx -name "*ipv6-wireguard*" -type f 2>/dev/null
    exit 1
fi

echo ""
echo "1. 检查前端目录..."
if [[ ! -d "$FRONTEND_DIR" ]]; then
    echo "   ❌ 前端目录不存在: $FRONTEND_DIR"
    echo "   尝试查找前端目录..."
    find /var/www /usr/share/nginx /opt -name "index.php" -path "*/php-frontend/*" 2>/dev/null | head -5
else
    echo "   ✅ 前端目录存在: $FRONTEND_DIR"
    if [[ -f "$FRONTEND_DIR/index.php" ]]; then
        echo "   ✅ index.php 文件存在"
    else
        echo "   ❌ index.php 文件不存在"
    fi
fi

echo ""
echo "2. 检查 Nginx 配置..."
echo "   配置文件: $NGINX_CONF"

# 检查 IPv6 监听
if grep -q "listen \[::\]" "$NGINX_CONF"; then
    echo "   ✅ IPv6 监听已配置"
else
    echo "   ⚠️  IPv6 监听未配置"
fi

# 检查 IPv4 监听
if grep -q "listen 80" "$NGINX_CONF"; then
    echo "   ✅ IPv4 监听已配置"
else
    echo "   ⚠️  IPv4 监听未配置"
fi

# 检查 root 目录
ROOT_DIR=$(grep "^[[:space:]]*root" "$NGINX_CONF" | head -1 | awk '{print $2}' | tr -d ';')
if [[ -n "$ROOT_DIR" ]]; then
    echo "   ✅ Root 目录: $ROOT_DIR"
    if [[ -f "$ROOT_DIR/index.php" ]]; then
        echo "   ✅ index.php 存在于 root 目录"
    else
        echo "   ❌ index.php 不存在于 root 目录"
    fi
else
    echo "   ❌ 未找到 root 配置"
fi

# 检查 location / 配置
echo ""
echo "3. 检查 location / 配置..."
if grep -A 2 "location / {" "$NGINX_CONF" | grep -q "try_files"; then
    echo "   ✅ location / 配置存在"
    echo "   当前配置:"
    grep -A 2 "location / {" "$NGINX_CONF" | grep "try_files"
    
    # 检查是否有问题
    if grep -A 2 "location / {" "$NGINX_CONF" | grep "try_files" | grep -q "/index.html"; then
        echo "   ⚠️  配置中包含了 /index.html 回退，如果文件不存在可能导致问题"
    fi
else
    echo "   ❌ location / 配置不存在或格式错误"
fi

# 检查 PHP 处理配置
echo ""
echo "4. 检查 PHP 处理配置..."
if grep -q "location ~ \\\.php\$" "$NGINX_CONF"; then
    echo "   ✅ PHP 处理配置存在"
    
    # 检查 fastcgi_pass
    PHP_BACKEND=$(grep -A 10 "location ~ \\\.php\$" "$NGINX_CONF" | grep "fastcgi_pass" | awk '{print $2}' | tr -d ';')
    if [[ -n "$PHP_BACKEND" ]]; then
        echo "   ✅ fastcgi_pass: $PHP_BACKEND"
        
        # 检查 upstream
        if echo "$PHP_BACKEND" | grep -q "php_backend"; then
            if grep -q "upstream php_backend" "$NGINX_CONF"; then
                echo "   ✅ php_backend upstream 已定义"
                PHP_SOCKET=$(grep -A 2 "upstream php_backend" "$NGINX_CONF" | grep "server unix:" | awk '{print $2}' | tr -d ';')
                if [[ -n "$PHP_SOCKET" ]]; then
                    echo "   ✅ PHP-FPM socket: $PHP_SOCKET"
                    if [[ -S "$PHP_SOCKET" ]]; then
                        echo "   ✅ Socket 文件存在"
                    else
                        echo "   ❌ Socket 文件不存在: $PHP_SOCKET"
                        echo "   尝试查找 PHP-FPM socket..."
                        find /var/run/php /run/php /tmp -name "*.sock" -type s 2>/dev/null | head -5
                    fi
                fi
            else
                echo "   ❌ php_backend upstream 未定义"
            fi
        fi
    else
        echo "   ❌ fastcgi_pass 未配置"
    fi
else
    echo "   ❌ PHP 处理配置不存在"
fi

# 检查 PHP-FPM 服务
echo ""
echo "5. 检查 PHP-FPM 服务..."
PHP_FPM_STATUS=$(systemctl is-active php*-fpm 2>/dev/null || systemctl is-active php-fpm 2>/dev/null || echo "unknown")
if [[ "$PHP_FPM_STATUS" != "unknown" ]]; then
    echo "   ✅ PHP-FPM 服务状态: $PHP_FPM_STATUS"
    if [[ "$PHP_FPM_STATUS" == "active" ]]; then
        echo "   ✅ PHP-FPM 正在运行"
    else
        echo "   ⚠️  PHP-FPM 未运行"
    fi
else
    echo "   ⚠️  无法检测 PHP-FPM 服务状态"
    echo "   尝试查找 PHP-FPM 服务..."
    systemctl list-unit-files | grep -i php | grep -i fpm
fi

# 检查 Nginx 服务
echo ""
echo "6. 检查 Nginx 服务..."
if systemctl is-active --quiet nginx; then
    echo "   ✅ Nginx 服务正在运行"
    
    # 检查配置测试
    if nginx -t 2>/dev/null; then
        echo "   ✅ Nginx 配置测试通过"
    else
        echo "   ❌ Nginx 配置测试失败"
        echo "   错误信息:"
        nginx -t 2>&1 | tail -5
    fi
else
    echo "   ❌ Nginx 服务未运行"
fi

# 检查文件权限
echo ""
echo "7. 检查文件权限..."
if [[ -d "$FRONTEND_DIR" ]]; then
    echo "   前端目录权限:"
    ls -ld "$FRONTEND_DIR" | awk '{print "   " $1 " " $3 ":" $4 " " $9}'
    
    if [[ -f "$FRONTEND_DIR/index.php" ]]; then
        echo "   index.php 权限:"
        ls -l "$FRONTEND_DIR/index.php" | awk '{print "   " $1 " " $3 ":" $4 " " $9}'
    fi
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "修复建议:"
echo ""
echo "1. 如果 location / 配置有问题，应该改为:"
echo "   location / {"
echo "       try_files \$uri \$uri/ /index.php\$is_args\$args;"
echo "   }"
echo ""
echo "2. 确保 PHP-FPM 服务正在运行:"
echo "   sudo systemctl start php*-fpm"
echo "   sudo systemctl enable php*-fpm"
echo ""
echo "3. 确保 Nginx 配置正确:"
echo "   sudo nginx -t"
echo "   sudo systemctl reload nginx"
echo ""
echo "4. 检查文件权限:"
echo "   sudo chown -R www-data:www-data $FRONTEND_DIR"
echo "   sudo chmod -R 755 $FRONTEND_DIR"
echo ""

