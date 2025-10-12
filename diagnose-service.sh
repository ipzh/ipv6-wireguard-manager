#!/bin/bash

echo "🔍 诊断服务启动问题..."
echo "================================"

# 检查服务状态
echo "📋 检查服务状态..."
sudo systemctl status ipv6-wireguard-manager --no-pager

echo ""
echo "📁 检查文件结构..."
echo "   系统目录: /opt/ipv6-wireguard-manager"
if [ -d "/opt/ipv6-wireguard-manager" ]; then
    echo "✅ 系统目录存在"
    ls -la /opt/ipv6-wireguard-manager/
else
    echo "❌ 系统目录不存在"
    exit 1
fi

echo ""
echo "📁 检查后端目录..."
if [ -d "/opt/ipv6-wireguard-manager/backend" ]; then
    echo "✅ 后端目录存在"
    ls -la /opt/ipv6-wireguard-manager/backend/
else
    echo "❌ 后端目录不存在"
    exit 1
fi

echo ""
echo "📁 检查虚拟环境..."
if [ -d "/opt/ipv6-wireguard-manager/backend/venv" ]; then
    echo "✅ 虚拟环境存在"
    ls -la /opt/ipv6-wireguard-manager/backend/venv/bin/
else
    echo "❌ 虚拟环境不存在"
    exit 1
fi

echo ""
echo "🔍 检查uvicorn..."
UVICORN_PATH="/opt/ipv6-wireguard-manager/backend/venv/bin/uvicorn"
if [ -f "$UVICORN_PATH" ]; then
    echo "✅ uvicorn存在: $UVICORN_PATH"
    ls -la "$UVICORN_PATH"
else
    echo "❌ uvicorn不存在: $UVICORN_PATH"
    echo "📁 检查bin目录内容:"
    ls -la /opt/ipv6-wireguard-manager/backend/venv/bin/ | grep uvicorn || echo "   未找到uvicorn"
fi

echo ""
echo "🔍 检查app.main模块..."
cd /opt/ipv6-wireguard-manager/backend
if [ -f "app/main.py" ]; then
    echo "✅ app/main.py存在"
    ls -la app/main.py
else
    echo "❌ app/main.py不存在"
    echo "📁 检查app目录:"
    ls -la app/ 2>/dev/null || echo "   app目录不存在"
fi

echo ""
echo "🔍 检查权限..."
echo "   后端目录权限:"
ls -ld /opt/ipv6-wireguard-manager/backend/
echo "   uvicorn权限:"
ls -l "$UVICORN_PATH" 2>/dev/null || echo "   uvicorn不存在"

echo ""
echo "🔍 测试手动启动..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate
echo "   当前目录: $(pwd)"
echo "   Python版本: $(python --version)"
echo "   测试uvicorn导入:"
python -c "import uvicorn; print('✅ uvicorn导入成功')" || echo "❌ uvicorn导入失败"

echo ""
echo "🔍 测试app导入..."
python -c "from app.main import app; print('✅ app导入成功')" || echo "❌ app导入失败"

echo ""
echo "🎯 诊断完成！"
