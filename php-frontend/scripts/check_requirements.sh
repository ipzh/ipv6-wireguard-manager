#!/bin/bash

# IPv6 WireGuard Manager PHP前端环境检查脚本

set -e

echo "🔍 检查IPv6 WireGuard Manager PHP前端环境要求..."

# 检查PHP
echo ""
echo "=== PHP环境检查 ==="
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2)
    echo "✅ PHP已安装: $PHP_VERSION"
    
    # 检查版本
    PHP_MAJOR=$(echo $PHP_VERSION | cut -d'.' -f1)
    PHP_MINOR=$(echo $PHP_VERSION | cut -d'.' -f2)
    if [ "$PHP_MAJOR" -gt 8 ] || ([ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -ge 1 ]); then
        echo "✅ PHP版本符合要求 (8.1+)"
    else
        echo "❌ PHP版本过低，需要8.1+，当前版本: $PHP_VERSION"
        exit 1
    fi
else
    echo "❌ PHP未安装"
    exit 1
fi

# 检查PHP扩展
echo ""
echo "=== PHP扩展检查 ==="
REQUIRED_EXTENSIONS=(
    "session:会话管理"
    "json:JSON处理"
    "mbstring:多字节字符串处理"
    "filter:数据过滤"
    "pdo:数据库连接"
    "pdo_mysql:MySQL数据库支持"
    "curl:HTTP客户端"
    "openssl:加密支持"
    "fileinfo:文件信息"
    "gd:图像处理"
)

ALL_EXTENSIONS_OK=true
for ext_info in "${REQUIRED_EXTENSIONS[@]}"; do
    ext=$(echo $ext_info | cut -d':' -f1)
    desc=$(echo $ext_info | cut -d':' -f2)
    
    if php -m | grep -q "^$ext$"; then
        echo "✅ $ext - $desc"
    else
        echo "❌ $ext - $desc (未安装)"
        ALL_EXTENSIONS_OK=false
    fi
done

if [ "$ALL_EXTENSIONS_OK" = false ]; then
    echo ""
    echo "❌ 缺少必需的PHP扩展，请安装后重试"
    exit 1
fi

# 检查Composer
echo ""
echo "=== Composer检查 ==="
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version | head -n1)
    echo "✅ Composer已安装: $COMPOSER_VERSION"
else
    echo "⚠️ Composer未安装 (可选，用于依赖管理)"
fi

# 检查Nginx
echo ""
echo "=== Nginx检查 ==="
if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1 | cut -d' ' -f3)
    echo "✅ Nginx已安装: $NGINX_VERSION"
else
    echo "⚠️ Nginx未安装 (需要用于Web服务器)"
fi

# 检查MySQL
echo ""
echo "=== MySQL检查 ==="
if command -v mysql &> /dev/null; then
    MYSQL_VERSION=$(mysql --version | cut -d' ' -f3)
    echo "✅ MySQL客户端已安装: $MYSQL_VERSION"
else
    echo "⚠️ MySQL客户端未安装 (需要用于数据库连接)"
fi

# 检查Docker
echo ""
echo "=== Docker检查 ==="
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo "✅ Docker已安装: $DOCKER_VERSION"
    
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        echo "✅ Docker Compose已安装: $COMPOSE_VERSION"
    else
        echo "⚠️ Docker Compose未安装 (需要用于容器编排)"
    fi
else
    echo "⚠️ Docker未安装 (可选，用于容器化部署)"
fi

# 检查文件权限
echo ""
echo "=== 文件权限检查 ==="
if [ -w "." ]; then
    echo "✅ 当前目录可写"
else
    echo "❌ 当前目录不可写"
    exit 1
fi

# 检查配置文件
echo ""
echo "=== 配置文件检查 ==="
if [ -f "config/config.php" ]; then
    echo "✅ 主配置文件存在"
else
    echo "⚠️ 主配置文件不存在，请复制 env.example 到 config/config.php"
fi

if [ -f "config/database.php" ]; then
    echo "✅ 数据库配置文件存在"
else
    echo "⚠️ 数据库配置文件不存在"
fi

# 检查目录结构
echo ""
echo "=== 目录结构检查 ==="
REQUIRED_DIRS=("classes" "controllers" "views" "config" "includes" "assets")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/ 目录存在"
    else
        echo "❌ $dir/ 目录不存在"
        exit 1
    fi
done

# 创建必要目录
echo ""
echo "=== 创建必要目录 ==="
mkdir -p logs uploads cache temp
echo "✅ 创建必要目录完成"

# 设置权限
chmod 755 logs uploads cache temp
echo "✅ 设置目录权限完成"

echo ""
echo "🎉 环境检查完成！"
echo ""
echo "📋 检查结果总结:"
echo "✅ PHP环境: 符合要求"
echo "✅ PHP扩展: 已检查"
echo "✅ 文件权限: 已设置"
echo "✅ 目录结构: 完整"
echo ""
echo "🚀 可以开始部署了！"
echo "运行: ./scripts/deploy.sh"
