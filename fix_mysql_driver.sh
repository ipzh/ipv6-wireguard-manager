#!/bin/bash

# 修复MySQL驱动问题脚本
# 解决ModuleNotFoundError: No module named 'MySQLdb'问题

set -e

echo "=========================================="
echo "🔧 修复MySQL驱动问题脚本"
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

echo ""

# 1. 检查当前Python环境
echo "1. 检查Python环境..."
cd "$INSTALL_DIR/backend" || {
    echo "❌ 无法进入后端目录: $INSTALL_DIR/backend"
    exit 1
}

if [ -f "venv/bin/activate" ]; then
    echo "   ✅ 虚拟环境存在"
    source venv/bin/activate
    echo "   ✅ 虚拟环境已激活"
else
    echo "   ❌ 虚拟环境不存在"
    exit 1
fi

echo "   Python版本: $(python --version)"
echo "   pip版本: $(pip --version)"

echo ""

# 2. 检查MySQL驱动安装状态
echo "2. 检查MySQL驱动安装状态..."
echo "   检查pymysql:"
if python -c "import pymysql; print('✅ pymysql已安装，版本:', pymysql.__version__)" 2>/dev/null; then
    echo "   ✅ pymysql驱动正常"
else
    echo "   ❌ pymysql驱动未安装或有问题"
fi

echo "   检查aiomysql:"
if python -c "import aiomysql; print('✅ aiomysql已安装，版本:', aiomysql.__version__)" 2>/dev/null; then
    echo "   ✅ aiomysql驱动正常"
else
    echo "   ❌ aiomysql驱动未安装或有问题"
fi

echo ""

# 3. 重新安装MySQL驱动
echo "3. 重新安装MySQL驱动..."
echo "   安装pymysql..."
if pip install --upgrade pymysql==1.1.0; then
    echo "   ✅ pymysql安装成功"
else
    echo "   ❌ pymysql安装失败"
    exit 1
fi

echo "   安装aiomysql..."
if pip install --upgrade aiomysql==0.2.0; then
    echo "   ✅ aiomysql安装成功"
else
    echo "   ❌ aiomysql安装失败"
    exit 1
fi

echo ""

# 4. 验证驱动安装
echo "4. 验证驱动安装..."
echo "   测试pymysql连接:"
if python -c "
import pymysql
try:
    conn = pymysql.connect(
        host='localhost',
        user='ipv6wgm',
        password='password',
        database='ipv6wgm',
        charset='utf8mb4'
    )
    print('✅ pymysql连接测试成功')
    conn.close()
except Exception as e:
    print('❌ pymysql连接测试失败:', str(e))
"; then
    echo "   ✅ pymysql连接测试通过"
else
    echo "   ❌ pymysql连接测试失败"
fi

echo ""

# 5. 检查数据库配置
echo "5. 检查数据库配置..."
if [ -f ".env" ]; then
    echo "   ✅ 环境配置文件存在"
    echo "   数据库配置:"
    grep "DATABASE_URL" .env | sed 's/^/     /' || echo "     未找到DATABASE_URL配置"
else
    echo "   ❌ 环境配置文件不存在"
fi

echo ""

# 6. 测试数据库连接
echo "6. 测试数据库连接..."
echo "   运行环境检查脚本..."
if python scripts/check_environment.py; then
    echo "   ✅ 环境检查通过"
else
    echo "   ❌ 环境检查失败"
fi

echo ""

# 7. 重启服务
echo "7. 重启服务..."
echo "   停止服务..."
if systemctl stop ipv6-wireguard-manager; then
    echo "   ✅ 服务停止成功"
else
    echo "   ⚠️  服务停止失败或未运行"
fi

echo "   启动服务..."
if systemctl start ipv6-wireguard-manager; then
    echo "   ✅ 服务启动成功"
else
    echo "   ❌ 服务启动失败"
    echo "   查看服务日志:"
    journalctl -u ipv6-wireguard-manager --no-pager -n 10
    exit 1
fi

echo ""

# 8. 检查服务状态
echo "8. 检查服务状态..."
sleep 3
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   ✅ 服务运行正常"
else
    echo "   ❌ 服务未正常运行"
    echo "   查看服务状态:"
    systemctl status ipv6-wireguard-manager --no-pager
    echo "   查看服务日志:"
    journalctl -u ipv6-wireguard-manager --no-pager -n 20
    exit 1
fi

echo ""

# 9. 测试API连接
echo "9. 测试API连接..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health --connect-timeout 5; then
    echo "   ✅ API连接正常"
else
    echo "   ❌ API连接失败"
fi

echo ""

echo "=========================================="
echo "🎉 MySQL驱动问题修复完成！"
echo "=========================================="
echo ""
echo "服务状态:"
echo "  - 服务名称: ipv6-wireguard-manager"
echo "  - 服务状态: $(systemctl is-active ipv6-wireguard-manager)"
echo "  - 服务端口: 8000"
echo ""
echo "管理命令:"
echo "  查看状态: systemctl status ipv6-wireguard-manager"
echo "  查看日志: journalctl -u ipv6-wireguard-manager -f"
echo "  重启服务: systemctl restart ipv6-wireguard-manager"
echo ""
echo "访问地址:"
echo "  API文档: http://localhost:8000/docs"
echo "  健康检查: http://localhost:8000/health"
