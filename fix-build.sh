#!/bin/bash

# 修复Docker构建问题

echo "🔧 修复Docker构建问题..."

# 进入项目目录
if [ -d "ipv6-wireguard-manager" ]; then
    cd ipv6-wireguard-manager
    echo "📁 进入项目目录: $(pwd)"
else
    echo "❌ 项目目录不存在"
    exit 1
fi

# 检查Docker Compose命令
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose 未找到"
    exit 1
fi

echo "   使用命令: $COMPOSE_CMD"

# 停止现有服务
echo "🛑 停止现有服务..."
$COMPOSE_CMD down

# 清理Docker缓存
echo "🧹 清理Docker缓存..."
docker system prune -f

# 清理构建缓存
echo "🧹 清理构建缓存..."
docker builder prune -f

# 重新构建镜像
echo "🔨 重新构建镜像..."
$COMPOSE_CMD build --no-cache --pull

# 启动服务
echo "🚀 启动服务..."
$COMPOSE_CMD up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "🔍 检查服务状态..."
$COMPOSE_CMD ps

# 检查服务日志
echo "📋 检查服务日志..."
echo "=== 后端日志 ==="
$COMPOSE_CMD logs backend | tail -20

echo "=== 前端日志 ==="
$COMPOSE_CMD logs frontend | tail -20

# 检测服务器IP地址
get_server_ip() {
    echo "🌐 检测服务器IP地址..."
    
    # 检测IPv4地址
    PUBLIC_IPV4=""
    LOCAL_IPV4=""
    
    # 使用curl获取公网IPv4
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV4=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv4.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api.ipify.org 2>/dev/null)
    fi
    
    # 获取本地IPv4地址
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    elif command -v hostname >/dev/null 2>&1; then
        LOCAL_IPV4=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    # 检测IPv6地址
    PUBLIC_IPV6=""
    LOCAL_IPV6=""
    
    # 使用curl获取公网IPv6
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV6=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv6.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api64.ipify.org 2>/dev/null)
    fi
    
    # 获取本地IPv6地址
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV6=$(ip -6 route get 2001:4860:4860::8888 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi
    
    # 设置IP地址
    if [ -n "$PUBLIC_IPV4" ]; then
        SERVER_IPV4="$PUBLIC_IPV4"
    elif [ -n "$LOCAL_IPV4" ]; then
        SERVER_IPV4="$LOCAL_IPV4"
    else
        SERVER_IPV4="localhost"
    fi
    
    if [ -n "$PUBLIC_IPV6" ]; then
        SERVER_IPV6="$PUBLIC_IPV6"
    elif [ -n "$LOCAL_IPV6" ]; then
        SERVER_IPV6="$LOCAL_IPV6"
    fi
}

# 检测IP地址
get_server_ip

echo ""
echo "🎉 修复完成！"
echo ""
echo "📋 访问信息："
echo "   IPv4访问地址："
if [ -n "$SERVER_IPV4" ] && [ "$SERVER_IPV4" != "localhost" ]; then
    echo "     - 前端界面: http://$SERVER_IPV4:3000"
    echo "     - 后端API: http://$SERVER_IPV4:8000"
    echo "     - API文档: http://$SERVER_IPV4:8000/docs"
else
    echo "     - 前端界面: http://localhost:3000"
    echo "     - 后端API: http://localhost:8000"
    echo "     - API文档: http://localhost:8000/docs"
fi

if [ -n "$SERVER_IPV6" ]; then
    echo "   IPv6访问地址："
    echo "     - 前端界面: http://[$SERVER_IPV6]:3000"
    echo "     - 后端API: http://[$SERVER_IPV6]:8000"
    echo "     - API文档: http://[$SERVER_IPV6]:8000/docs"
fi
echo ""
echo "🔑 默认登录信息："
echo "   用户名: admin"
echo "   密码: admin123"
echo ""
