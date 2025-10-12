#!/bin/bash

# 修复后端服务启动问题
echo "🔧 修复后端服务启动问题..."

# 检查服务状态
echo "📊 检查当前服务状态..."
systemctl status ipv6-wireguard-manager --no-pager

# 查看服务日志
echo "📋 查看服务日志..."
journalctl -u ipv6-wireguard-manager --no-pager -n 20

# 停止服务
echo "⏹️ 停止服务..."
systemctl stop ipv6-wireguard-manager

# 重新创建服务配置
echo "🔧 重新创建服务配置..."
cat > /etc/systemd/system/ipv6-wireguard-manager.service << 'EOF'
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target postgresql.service redis.service
Requires=postgresql.service redis.service

[Service]
Type=simple
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=/opt/ipv6-wireguard-manager/backend
Environment=PATH=/opt/ipv6-wireguard-manager/backend/venv/bin
Environment=PYTHONPATH=/opt/ipv6-wireguard-manager/backend
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 重载systemd
echo "🔄 重载systemd配置..."
systemctl daemon-reload

# 检查Python环境
echo "🐍 检查Python环境..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate
python --version
which python

# 测试应用启动
echo "🧪 测试应用启动..."
timeout 10 python -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager/backend')
try:
    from app.main import app
    print('✅ 应用导入成功')
    
    # 测试API路由
    from app.api.api_v1.api import api_router
    print('✅ API路由导入成功')
    
    # 测试数据库连接
    from app.core.database import async_engine
    print('✅ 数据库引擎导入成功')
    
except Exception as e:
    print(f'❌ 应用导入失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"

# 启动服务
echo "🚀 启动服务..."
systemctl start ipv6-wireguard-manager

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
echo "📊 检查服务状态..."
systemctl status ipv6-wireguard-manager --no-pager

# 检查端口监听
echo "🔍 检查端口监听..."
netstat -tlnp | grep :8000 || echo "端口8000未监听"

# 测试API
echo "🌐 测试API..."
curl -s http://127.0.0.1:8000/health || echo "API无响应"

echo "✅ 修复完成！"
