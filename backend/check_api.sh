#!/bin/bash
# 快速诊断API服务

echo "=== IPv6 WireGuard Manager API 诊断 ==="
echo ""

# 1. 检查Python
if command -v python3 &> /dev/null; then
    echo "✅ Python3: $(python3 --version)"
else
    echo "❌ Python3未安装"
    exit 1
fi

# 2. 检查依赖
cd /opt/ipv6-wireguard-manager/backend || exit
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "✅ 虚拟环境已激活"
else
    echo "⚠️  虚拟环境未找到，使用系统Python"
fi

# 3. 检查API进程
if pgrep -f "uvicorn.*app.main" > /dev/null; then
    echo "✅ API服务正在运行"
    echo "   PID: $(pgrep -f 'uvicorn.*app.main')"
else
    echo "❌ API服务未运行"
fi

# 4. 检查端口
if netstat -tuln | grep -q ":8000 "; then
    echo "✅ 端口8000正在监听"
else
    echo "❌ 端口8000未监听"
fi

# 5. 检查数据库
if systemctl is-active --quiet mysql; then
    echo "✅ MySQL服务运行中"
else
    echo "❌ MySQL服务未运行"
fi

# 6. 测试健康检查
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ 健康检查端点响应正常"
else
    echo "❌ 健康检查端点无响应"
fi

echo ""
echo "=== 诊断完成 ==="

