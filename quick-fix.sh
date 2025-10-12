#!/bin/bash

echo "🔧 快速修复后端文件缺失问题"
echo "================================"

# 从当前目录（frontend）回到项目根目录
echo "📁 定位项目根目录..."
cd /root/ipv6-wireguard-manager/ipv6-wireguard-manager
echo "   当前目录: $(pwd)"

# 检查项目结构
echo "📁 项目结构:"
ls -la

# 复制后端文件到系统目录
echo ""
echo "📁 复制后端文件..."
if [ -d "backend" ]; then
    sudo cp -r backend /opt/ipv6-wireguard-manager/
    echo "✅ 后端文件复制完成"
else
    echo "❌ 后端目录不存在"
    exit 1
fi

# 设置权限
echo "🔐 设置权限..."
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager/backend

# 验证修复
echo ""
echo "🔍 验证修复..."
if [ -d "/opt/ipv6-wireguard-manager/backend" ]; then
    echo "✅ 后端目录现在存在"
    echo "📁 后端目录内容:"
    ls -la /opt/ipv6-wireguard-manager/backend/
else
    echo "❌ 后端目录仍然不存在"
    exit 1
fi

echo ""
echo "🎯 修复完成！现在可以继续数据库初始化..."
echo ""
echo "💡 接下来可以运行:"
echo "   cd /opt/ipv6-wireguard-manager/backend"
echo "   source venv/bin/activate"
echo "   python -c \"from app.core.database import engine; from app.models import Base; Base.metadata.create_all(bind=engine)\""
