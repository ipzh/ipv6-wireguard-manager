#!/bin/bash

# 快速修复MySQL驱动问题
# 解决ModuleNotFoundError: No module named 'MySQLdb'

set -e

echo "🔧 快速修复MySQL驱动问题..."

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 需要root权限"
    exit 1
fi

# 进入后端目录
cd /opt/ipv6-wireguard-manager/backend || {
    echo "❌ 无法进入后端目录"
    exit 1
}

# 激活虚拟环境
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "✅ 虚拟环境已激活"
else
    echo "❌ 虚拟环境不存在"
    exit 1
fi

# 重新安装MySQL驱动
echo "📦 重新安装MySQL驱动..."
pip install --upgrade pymysql==1.1.0 aiomysql==0.2.0

# 停止服务
echo "🛑 停止服务..."
systemctl stop ipv6-wireguard-manager || true

# 启动服务
echo "🚀 启动服务..."
systemctl start ipv6-wireguard-manager

# 等待服务启动
sleep 3

# 检查服务状态
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 服务启动成功！"
    echo "🌐 访问地址:"
    echo "  API文档: http://localhost:8000/docs"
    echo "  健康检查: http://localhost:8000/health"
else
    echo "❌ 服务启动失败"
    echo "📋 查看日志:"
    journalctl -u ipv6-wireguard-manager --no-pager -n 10
fi
