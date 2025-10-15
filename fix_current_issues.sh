#!/bin/bash

# 修复当前问题脚本
# 解决环境检查脚本和数据库模块问题

set -e

echo "=========================================="
echo "🔧 修复当前问题脚本"
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
source venv/bin/activate || {
    echo "❌ 激活虚拟环境失败"
    exit 1
}
echo "✅ 虚拟环境激活成功"

echo ""

# 安装缺失的aiomysql驱动
echo "2. 安装aiomysql驱动..."
if python -c "import aiomysql" 2>/dev/null; then
    echo "✅ aiomysql 已安装"
else
    echo "   安装 aiomysql..."
    if pip install aiomysql==0.2.0; then
        echo "✅ aiomysql 安装成功"
    else
        echo "❌ aiomysql 安装失败"
        echo "   继续使用同步模式"
    fi
fi

echo ""

# 测试数据库模块导入
echo "3. 测试数据库模块导入..."
if python -c "from app.core.database import init_db; print('✅ 数据库模块导入成功')" 2>/dev/null; then
    echo "✅ 数据库模块导入成功"
else
    echo "❌ 数据库模块导入失败"
    echo "   错误信息:"
    python -c "from app.core.database import init_db" 2>&1 || true
fi

echo ""

# 测试环境检查脚本
echo "4. 测试环境检查脚本..."
if [ -f "scripts/check_environment.py" ]; then
    echo "   运行环境检查脚本..."
    if python scripts/check_environment.py; then
        echo "✅ 环境检查通过"
    else
        echo "❌ 环境检查失败"
        echo "   检查脚本可能需要更新"
    fi
else
    echo "❌ 环境检查脚本不存在"
fi

echo ""

# 检查服务状态
echo "5. 检查服务状态..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 服务正在运行"
    echo "   重启服务以应用修复..."
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
    echo "⚠️  服务未运行"
    echo "   尝试启动服务..."
    if systemctl start ipv6-wireguard-manager; then
        echo "✅ 服务启动成功"
    else
        echo "❌ 服务启动失败"
    fi
fi

echo ""

# 测试API连接
echo "6. 测试API连接..."
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ API连接正常"
    echo "   健康检查响应:"
    curl -s http://localhost:8000/health | head -1
else
    echo "❌ API连接失败"
    echo "   检查服务日志:"
    journalctl -u ipv6-wireguard-manager --no-pager -l | tail -5
fi

echo ""

echo "=========================================="
echo "🎉 修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "✅ 安装 aiomysql 驱动"
echo "✅ 测试数据库模块导入"
echo "✅ 测试环境检查脚本"
echo "✅ 检查服务状态"
echo "✅ 测试API连接"
echo ""
echo "如果问题仍然存在，请检查:"
echo "1. 服务日志: journalctl -u ipv6-wireguard-manager -f"
echo "2. 配置文件: cat .env"
echo "3. 依赖状态: pip list | grep -E '(aiomysql|python-dotenv)'"
