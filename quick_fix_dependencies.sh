#!/bin/bash

# 快速修复依赖脚本
# 专门解决python-dotenv缺失问题

set -e

echo "=========================================="
echo "⚡ 快速修复依赖脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 检查安装目录
INSTALL_DIR="/opt/ipv6-wireguard-manager"
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ 安装目录不存在: $INSTALL_DIR"
    exit 1
fi

echo "📁 安装目录: $INSTALL_DIR"
cd "$INSTALL_DIR/backend" || {
    echo "❌ 无法进入后端目录"
    exit 1
}

echo ""

# 激活虚拟环境
echo "1. 激活虚拟环境..."
if [ ! -f "venv/bin/activate" ]; then
    echo "❌ 虚拟环境不存在"
    exit 1
fi

source venv/bin/activate || {
    echo "❌ 激活虚拟环境失败"
    exit 1
}
echo "✅ 虚拟环境激活成功"

echo ""

# 安装缺失的依赖
echo "2. 安装缺失的依赖..."
echo "   安装 python-dotenv..."

if pip install python-dotenv==1.0.0; then
    echo "✅ python-dotenv 安装成功"
else
    echo "❌ python-dotenv 安装失败"
    echo "   尝试安装最新版本..."
    if pip install python-dotenv; then
        echo "✅ python-dotenv 最新版本安装成功"
    else
        echo "❌ python-dotenv 安装失败"
        exit 1
    fi
fi

echo ""

# 验证安装
echo "3. 验证依赖安装..."
if python -c "import dotenv; print('python-dotenv 导入成功')" 2>/dev/null; then
    echo "✅ python-dotenv 验证通过"
else
    echo "❌ python-dotenv 验证失败"
    exit 1
fi

echo ""

# 运行环境检查
echo "4. 运行环境检查..."
if [ -f "scripts/check_environment.py" ]; then
    if python scripts/check_environment.py; then
        echo "✅ 环境检查通过"
    else
        echo "⚠️  环境检查仍有问题，但python-dotenv已修复"
    fi
else
    echo "⚠️  环境检查脚本不存在"
fi

echo ""

# 重启服务
echo "5. 重启服务..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   服务正在运行，重启服务..."
    if systemctl restart ipv6-wireguard-manager; then
        echo "✅ 服务重启成功"
        sleep 2
        if systemctl is-active --quiet ipv6-wireguard-manager; then
            echo "✅ 服务运行正常"
        else
            echo "❌ 服务重启后未正常运行"
        fi
    else
        echo "❌ 服务重启失败"
    fi
else
    echo "   服务未运行，启动服务..."
    if systemctl start ipv6-wireguard-manager; then
        echo "✅ 服务启动成功"
    else
        echo "❌ 服务启动失败"
    fi
fi

echo ""

echo "=========================================="
echo "🎉 快速修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "✅ 安装 python-dotenv 依赖"
echo "✅ 验证依赖安装"
echo "✅ 运行环境检查"
echo "✅ 重启服务"
echo ""
echo "现在可以测试服务:"
echo "curl http://localhost:8000/health"
echo ""
echo "或查看服务状态:"
echo "systemctl status ipv6-wireguard-manager"
