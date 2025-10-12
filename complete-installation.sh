#!/bin/bash

echo "🚀 完成安装过程..."
echo "===================="

# 检查当前状态
echo "📁 检查当前状态..."
echo "   当前目录: $(pwd)"

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

# 检查系统目录
APP_HOME="/opt/ipv6-wireguard-manager"
if [ ! -d "$APP_HOME" ]; then
    echo "📁 创建系统目录..."
    sudo mkdir -p "$APP_HOME"
fi

# 复制所有项目文件
echo ""
echo "📁 复制项目文件到系统目录..."
echo "   复制后端文件..."
if [ -d "backend" ]; then
    sudo cp -r backend "$APP_HOME/"
    echo "✅ 后端目录复制完成"
else
    echo "❌ 后端目录不存在"
    exit 1
fi

echo "   复制前端文件..."
if [ -d "frontend" ]; then
    sudo cp -r frontend "$APP_HOME/"
    echo "✅ 前端目录复制完成"
else
    echo "❌ 前端目录不存在"
    exit 1
fi

echo "   复制其他重要文件..."
for file in requirements.txt docker-compose.yml README.md; do
    if [ -f "$file" ]; then
        sudo cp "$file" "$APP_HOME/"
        echo "✅ 复制 $file"
    fi
done

# 设置权限
echo ""
echo "🔐 设置权限..."
sudo chown -R ipv6wgm:ipv6wgm "$APP_HOME"
sudo chmod -R 755 "$APP_HOME"

# 验证文件结构
echo ""
echo "🔍 验证文件结构..."
echo "📁 系统目录内容:"
ls -la "$APP_HOME/"

if [ -d "$APP_HOME/backend" ]; then
    echo "✅ 后端目录存在"
    echo "📁 后端目录内容:"
    ls -la "$APP_HOME/backend/"
else
    echo "❌ 后端目录不存在"
    exit 1
fi

if [ -d "$APP_HOME/frontend" ]; then
    echo "✅ 前端目录存在"
    echo "📁 前端目录内容:"
    ls -la "$APP_HOME/frontend/"
else
    echo "❌ 前端目录不存在"
    exit 1
fi

# 初始化数据库
echo ""
echo "🗄️  初始化数据库..."
cd "$APP_HOME/backend"

if [ ! -d "venv" ]; then
    echo "❌ 虚拟环境不存在，跳过数据库初始化"
    echo "💡 请先运行后端安装:"
    echo "   cd $APP_HOME/backend"
    echo "   python3 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt"
    exit 1
fi

source venv/bin/activate

echo "🔧 创建数据库表..."
python -c "
from app.core.database import engine
from app.models import Base
Base.metadata.create_all(bind=engine)
print('数据库表创建完成')
" || echo "⚠️  数据库表创建失败"

echo "🔧 初始化默认数据..."
python -c "
from app.core.init_db import init_db
init_db()
print('默认数据初始化完成')
" || echo "⚠️  默认数据初始化失败"

# 启动服务
echo ""
echo "🚀 启动服务..."
sudo systemctl daemon-reload
sudo systemctl start ipv6-wireguard-manager
sudo systemctl enable ipv6-wireguard-manager

# 检查服务状态
echo ""
echo "🔍 检查服务状态..."
sudo systemctl status ipv6-wireguard-manager --no-pager

echo ""
echo "🎯 安装完成！"
echo "🌐 访问地址:"
echo "   - IPv4: http://localhost:3000"
echo "   - IPv6: http://[::1]:3000"
echo ""
echo "📋 服务管理命令:"
echo "   sudo systemctl status ipv6-wireguard-manager"
echo "   sudo systemctl restart ipv6-wireguard-manager"
echo "   sudo systemctl stop ipv6-wireguard-manager"
