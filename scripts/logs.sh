#!/bin/bash

# IPv6 WireGuard Manager 日志查看脚本

echo "📖 查看 IPv6 WireGuard Manager 日志..."

# 检查参数
if [ $# -eq 0 ]; then
    echo "显示所有服务日志..."
    docker-compose logs -f
else
    case $1 in
        "backend")
            echo "显示后端日志..."
            docker-compose logs -f backend
            ;;
        "frontend")
            echo "显示前端日志..."
            docker-compose logs -f frontend
            ;;
        "db")
            echo "显示数据库日志..."
            docker-compose logs -f db
            ;;
        "redis")
            echo "显示Redis日志..."
            docker-compose logs -f redis
            ;;
        *)
            echo "显示 $1 服务日志..."
            docker-compose logs -f $1
            ;;
    esac
fi
