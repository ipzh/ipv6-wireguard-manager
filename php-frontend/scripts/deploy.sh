#!/bin/bash

# IPv6 WireGuard Manager PHP前端部署脚本
# 支持PHP 8.1+ 和 Nginx

set -e

echo "🚀 开始部署IPv6 WireGuard Manager PHP前端..."

# 检查PHP版本
if ! command -v php &> /dev/null; then
    echo "❌ PHP未安装，请先安装PHP 8.1+"
    exit 1
fi

PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
REQUIRED_VERSION="8.1"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PHP_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ PHP版本过低，需要8.1+，当前版本: $PHP_VERSION"
    exit 1
fi

echo "✅ PHP版本检查通过: $PHP_VERSION"

# 检查必需扩展
echo "🔍 检查PHP扩展..."
REQUIRED_EXTENSIONS=("session" "json" "mbstring" "filter" "pdo" "pdo_mysql" "curl" "openssl")
MISSING_EXTENSIONS=()

for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if ! php -m | grep -q "^$ext$"; then
        MISSING_EXTENSIONS+=("$ext")
    fi
done

if [ ${#MISSING_EXTENSIONS[@]} -ne 0 ]; then
    echo "❌ 缺少必需的PHP扩展: ${MISSING_EXTENSIONS[*]}"
    echo "请安装缺少的扩展后重试"
    exit 1
fi

echo "✅ PHP扩展检查通过"

# 检查Composer（可选）
if command -v composer &> /dev/null; then
    echo "✅ Composer已安装: $(composer --version | head -n1)"
else
    echo "⚠️ Composer未安装，跳过依赖管理"
fi

# 设置权限
echo "🔧 设置文件权限..."
chmod -R 755 .
chmod -R 777 logs/ 2>/dev/null || true
chmod -R 777 uploads/ 2>/dev/null || true

# 检查配置文件
echo "📋 检查配置文件..."
if [ ! -f "config/config.php" ]; then
    echo "⚠️ 配置文件不存在，请复制 env.example 到 config/config.php 并配置"
fi

# 检查Nginx配置
echo "🌐 检查Nginx配置..."
if [ -f "nginx.conf" ]; then
    echo "✅ Nginx配置文件存在"
else
    echo "⚠️ Nginx配置文件不存在，请配置Nginx"
fi

# 检查Docker配置
echo "🐳 检查Docker配置..."
if [ -f "Dockerfile" ]; then
    echo "✅ Dockerfile存在"
else
    echo "⚠️ Dockerfile不存在"
fi

if [ -f "docker/nginx.conf" ]; then
    echo "✅ Docker Nginx配置存在"
else
    echo "⚠️ Docker Nginx配置不存在"
fi

# 创建必要的目录
echo "📁 创建必要目录..."
mkdir -p logs
mkdir -p uploads
mkdir -p cache
mkdir -p temp

# 设置目录权限
chmod 755 logs uploads cache temp

echo "🎉 PHP前端部署准备完成！"
echo ""
echo "📋 部署检查清单:"
echo "✅ PHP版本: $PHP_VERSION"
echo "✅ PHP扩展: 已检查"
echo "✅ 文件权限: 已设置"
echo "✅ 目录结构: 已创建"
echo ""
echo "🚀 下一步:"
echo "1. 配置 config/config.php"
echo "2. 配置Nginx虚拟主机"
echo "3. 启动PHP-FPM服务"
echo "4. 启动Nginx服务"
echo ""
echo "🐳 或使用Docker部署:"
echo "docker build -t ipv6-wireguard-frontend ."
echo "docker run -d -p 80:80 ipv6-wireguard-frontend"
