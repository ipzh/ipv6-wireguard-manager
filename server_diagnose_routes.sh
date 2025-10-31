#!/bin/bash
# 诊断 API 路由问题的脚本

echo "=========================================="
echo "API 路由诊断工具"
echo "=========================================="

cd /opt/ipv6-wireguard-manager || exit 1

echo ""
echo "1. 检查服务状态..."
sudo systemctl status ipv6-wireguard-manager --no-pager | head -20

echo ""
echo "2. 检查最近的服务日志（路由注册相关）..."
sudo journalctl -u ipv6-wireguard-manager --no-pager | grep -E "(注册路由|成功注册|模块导入|health|HealthCheck|路由注册|API路由)" | tail -30

echo ""
echo "3. 测试健康检查端点..."
echo "   测试 /health:"
curl -s http://localhost:8000/health || curl -s http://[::1]:8000/health
echo ""
echo "   测试 /api/v1/health:"
curl -s http://localhost:8000/api/v1/health || curl -s http://[::1]:8000/api/v1/health
echo ""
echo "   测试 /api/v1/health/alt:"
curl -s http://localhost:8000/api/v1/health/alt || curl -s http://[::1]:8000/api/v1/health/alt

echo ""
echo "4. 检查 Python 代码..."
echo "   检查 health endpoint 文件:"
if [ -f "backend/app/api/api_v1/endpoints/health.py" ]; then
    echo "   文件存在"
    grep -n "prefix" backend/app/api/api_v1/api.py | grep -i health
    echo "   前10行:"
    head -10 backend/app/api/api_v1/endpoints/health.py
else
    echo "   ❌ 文件不存在"
fi

echo ""
echo "5. 检查所有注册的路由..."
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager')
try:
    from backend.app.api.api_v1.api import api_router
    print("API Router 路由:")
    for route in api_router.routes:
        print(f"  {route.path} - {route.methods}")
except Exception as e:
    print(f"❌ 导入失败: {e}")
    import traceback
    traceback.print_exc()
EOF

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="

