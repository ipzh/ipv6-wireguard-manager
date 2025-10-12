#!/bin/bash

echo "🔧 修复缺失的后端文件..."
echo "================================"

# 检查当前状态
echo "📁 检查当前状态..."
echo "   系统目录: /opt/ipv6-wireguard-manager"
echo "   项目目录: $(pwd)"

# 检查系统目录
if [ -d "/opt/ipv6-wireguard-manager" ]; then
    echo "✅ 系统目录存在"
    echo "📁 系统目录内容:"
    ls -la /opt/ipv6-wireguard-manager/
else
    echo "❌ 系统目录不存在"
    exit 1
fi

# 检查项目根目录
PROJECT_ROOT=""
if [ -d "backend" ] && [ -d "frontend" ]; then
    PROJECT_ROOT=$(pwd)
elif [ -d "../backend" ] && [ -d "../frontend" ]; then
    PROJECT_ROOT=$(realpath ..)
elif [ -d "../../backend" ] && [ -d "../../frontend" ]; then
    PROJECT_ROOT=$(realpath ../..)
else
    echo "❌ 无法找到项目根目录"
    echo "📁 当前目录: $(pwd)"
    echo "📁 目录内容:"
    ls -la
    exit 1
fi

echo "   项目根目录: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# 复制缺失的后端文件
echo ""
echo "📁 复制缺失的后端文件..."
if [ -d "backend" ]; then
    echo "   复制后端目录..."
    sudo cp -r backend /opt/ipv6-wireguard-manager/
    echo "✅ 后端目录复制完成"
else
    echo "❌ 后端目录不存在"
    exit 1
fi

# 复制其他重要文件
echo "   复制其他重要文件..."
for file in requirements.txt docker-compose.yml README.md; do
    if [ -f "$file" ]; then
        sudo cp "$file" /opt/ipv6-wireguard-manager/
        echo "✅ 复制 $file"
    fi
done

# 设置权限
echo ""
echo "🔐 设置权限..."
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager

# 验证修复
echo ""
echo "🔍 验证修复..."
if [ -d "/opt/ipv6-wireguard-manager/backend" ]; then
    echo "✅ 后端目录存在"
    echo "📁 后端目录内容:"
    ls -la /opt/ipv6-wireguard-manager/backend/
else
    echo "❌ 后端目录仍然不存在"
    exit 1
fi

echo ""
echo "🎯 修复完成！现在可以继续数据库初始化..."
echo ""
echo "💡 建议运行以下命令完成安装:"
echo "   cd /opt/ipv6-wireguard-manager/backend"
echo "   source venv/bin/activate"
echo "   python -c \"from app.core.database import engine; from app.models import Base; Base.metadata.create_all(bind=engine)\""
echo "   sudo systemctl start ipv6-wireguard-manager"
echo "   sudo systemctl status ipv6-wireguard-manager"
