#!/bin/bash

# 诊断空白页面和API错误问题脚本

set -e

echo "=========================================="
echo "🔍 诊断空白页面和API错误问题脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

echo "1. 检查服务状态..."
echo "   Nginx服务:"
if systemctl is-active --quiet nginx; then
    echo "     ✅ Nginx服务运行正常"
else
    echo "     ❌ Nginx服务未运行"
fi

echo "   IPv6 WireGuard Manager服务:"
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "     ✅ IPv6 WireGuard Manager服务运行正常"
else
    echo "     ❌ IPv6 WireGuard Manager服务未运行"
fi

echo ""

echo "2. 检查端口监听..."
echo "   端口80监听状态:"
netstat -tlnp | grep :80 | sed 's/^/     /' || echo "     端口80未监听"

echo "   端口8000监听状态:"
netstat -tlnp | grep :8000 | sed 's/^/     /' || echo "     端口8000未监听"

echo ""

echo "3. 检查Nginx配置..."
nginx_config="/etc/nginx/sites-enabled/ipv6-wireguard-manager"
if [ -f "$nginx_config" ]; then
    echo "   ✅ 项目配置文件存在"
    echo "   配置内容:"
    cat "$nginx_config" | sed 's/^/     /'
else
    echo "   ❌ 项目配置文件不存在"
fi

echo ""

echo "4. 检查前端文件..."
frontend_dir="/opt/ipv6-wireguard-manager/frontend/dist"
if [ -d "$frontend_dir" ]; then
    echo "   ✅ 前端目录存在: $frontend_dir"
    echo "   目录内容:"
    ls -la "$frontend_dir" | sed 's/^/     /'
    
    if [ -f "$frontend_dir/index.html" ]; then
        echo "   ✅ index.html文件存在"
        echo "   文件大小: $(du -h "$frontend_dir/index.html" | cut -f1)"
        echo "   文件内容预览:"
        head -20 "$frontend_dir/index.html" | sed 's/^/     /'
    else
        echo "   ❌ index.html文件不存在"
    fi
else
    echo "   ❌ 前端目录不存在: $frontend_dir"
fi

echo ""

echo "5. 测试本地连接..."
echo "   测试本地前端连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 --connect-timeout 5; then
    echo "     ✅ 本地前端连接正常"
else
    echo "     ❌ 本地前端连接失败"
fi

echo "   测试本地API连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health --connect-timeout 5; then
    echo "     ✅ 本地API连接正常"
else
    echo "     ❌ 本地API连接失败"
fi

echo "   测试本地API文档连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/docs --connect-timeout 5; then
    echo "     ✅ 本地API文档连接正常"
else
    echo "     ❌ 本地API文档连接失败"
fi

echo ""

echo "6. 测试IPv6连接..."
ipv6_ip="2605:6400:8a61:100::117"
echo "   测试IPv6前端连接:"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_ip]:80" --connect-timeout 5; then
    echo "     ✅ IPv6前端连接正常"
else
    echo "     ❌ IPv6前端连接失败"
fi

echo "   测试IPv6 API连接:"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_ip]:8000/health" --connect-timeout 5; then
    echo "     ✅ IPv6 API连接正常"
else
    echo "     ❌ IPv6 API连接失败"
fi

echo "   测试IPv6 API文档连接:"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_ip]:8000/docs" --connect-timeout 5; then
    echo "     ✅ IPv6 API文档连接正常"
else
    echo "     ❌ IPv6 API文档连接失败"
fi

echo ""

echo "7. 检查服务日志..."
echo "   Nginx错误日志 (最近10行):"
if [ -f "/var/log/nginx/error.log" ]; then
    tail -10 /var/log/nginx/error.log | sed 's/^/     /'
else
    echo "     Nginx错误日志不存在"
fi

echo "   IPv6 WireGuard Manager服务日志 (最近10行):"
journalctl -u ipv6-wireguard-manager --no-pager -n 10 | sed 's/^/     /'

echo ""

echo "8. 检查前端页面内容..."
echo "   获取前端页面内容:"
response=$(curl -s "http://[$ipv6_ip]:80" --connect-timeout 5)
if [ -n "$response" ]; then
    echo "     ✅ 前端页面有内容"
    echo "     内容长度: ${#response} 字符"
    echo "     内容预览:"
    echo "$response" | head -10 | sed 's/^/       /'
    
    if echo "$response" | grep -q "IPv6 WireGuard Manager"; then
        echo "     ✅ 页面包含正确标题"
    else
        echo "     ❌ 页面不包含正确标题"
    fi
    
    if echo "$response" | grep -q "root"; then
        echo "     ✅ 页面包含React根元素"
    else
        echo "     ❌ 页面不包含React根元素"
    fi
else
    echo "     ❌ 前端页面无内容"
fi

echo ""

echo "9. 检查API错误..."
echo "   获取API文档错误信息:"
api_response=$(curl -s "http://[$ipv6_ip]:8000/docs" --connect-timeout 5)
if [ -n "$api_response" ]; then
    echo "     ✅ API文档有响应"
    echo "     响应长度: ${#api_response} 字符"
    if echo "$api_response" | grep -q "Internal Server Error"; then
        echo "     ❌ API返回内部服务器错误"
        echo "     错误内容:"
        echo "$api_response" | sed 's/^/       /'
    else
        echo "     ✅ API文档正常"
    fi
else
    echo "     ❌ API文档无响应"
fi

echo ""

echo "10. 检查数据库连接..."
echo "   检查MySQL服务状态:"
if systemctl is-active --quiet mysql; then
    echo "     ✅ MySQL服务运行正常"
elif systemctl is-active --quiet mariadb; then
    echo "     ✅ MariaDB服务运行正常"
else
    echo "     ❌ MySQL/MariaDB服务未运行"
fi

echo "   测试数据库连接:"
cd /opt/ipv6-wireguard-manager/backend || {
    echo "     ❌ 无法进入后端目录"
    exit 1
}

if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    if python scripts/check_environment.py; then
        echo "     ✅ 数据库连接正常"
    else
        echo "     ❌ 数据库连接失败"
    fi
else
    echo "     ❌ 虚拟环境不存在"
fi

echo ""

echo "11. 检查网络配置..."
echo "   IPv6地址配置:"
ip -6 addr show | grep -A 2 "2605:6400:8a61:100::117" | sed 's/^/     /' || echo "     未找到指定IPv6地址"

echo "   路由配置:"
ip -6 route show | grep "2605:6400:8a61:100::117" | sed 's/^/     /' || echo "     未找到相关路由"

echo ""

echo "12. 生成诊断报告..."
echo "   系统信息:"
echo "     操作系统: $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)"
echo "     内核版本: $(uname -r)"
echo "     架构: $(uname -m)"

echo "   服务信息:"
echo "     Nginx版本: $(nginx -v 2>&1 | cut -d' ' -f3)"
echo "     Python版本: $(python3 --version 2>/dev/null || echo '未安装')"

echo ""

echo "=========================================="
echo "🎉 诊断完成！"
echo "=========================================="
echo ""
echo "如果发现问题，请运行相应的修复脚本："
echo "1. 修复前端空白页面: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_blank_page.sh | bash"
echo "2. 修复API错误: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_api_error.sh | bash"
echo "3. 修复Nginx配置: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_nginx_frontend.sh | bash"
