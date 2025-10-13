#!/bin/bash

echo "🔧 修复所有导入问题..."

# 停止服务
systemctl stop ipv6-wireguard-manager.service

# 进入应用目录
cd /opt/ipv6-wireguard-manager/backend

# 激活虚拟环境
source venv/bin/activate

# 设置环境变量
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ipv6wgm"
export REDIS_URL="redis://localhost:6379/0"
export SECRET_KEY="your-secret-key-change-this-in-production"

# 测试导入
echo "测试应用导入..."
python -c "
try:
    from app.main import app
    print('✅ 应用导入成功')
except Exception as e:
    print(f'❌ 应用导入失败: {e}')
    import traceback
    traceback.print_exc()
    exit(1)
"

# 如果导入成功，启动服务
if [ $? -eq 0 ]; then
    echo "启动服务..."
    systemctl start ipv6-wireguard-manager.service
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    systemctl status ipv6-wireguard-manager.service --no-pager
    
    # 测试API
    echo "测试API..."
    curl -f http://localhost:8000/health > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ API测试成功"
        echo "✅ 所有导入问题已修复"
    else
        echo "❌ API测试失败"
        echo "查看详细日志:"
        journalctl -u ipv6-wireguard-manager.service -n 10 --no-pager
    fi
else
    echo "导入失败，请检查错误信息"
fi

echo "修复完成！"
