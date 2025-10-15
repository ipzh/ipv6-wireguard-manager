#!/bin/bash

# IPv6访问诊断脚本
# 诊断IPv6访问前端的问题

set -e

echo "=========================================="
echo "🔍 IPv6访问诊断脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

echo "1. 检查IPv6网络配置..."
echo "   IPv6地址列表:"
ip -6 addr show | grep -E "inet6.*global" | sed 's/^/     /' || echo "    未找到全局IPv6地址"

echo ""

echo "2. 检查Nginx配置..."
if [ -f "/etc/nginx/sites-enabled/ipv6-wireguard-manager" ]; then
    echo "   Nginx配置文件存在"
    echo "   配置内容:"
    cat /etc/nginx/sites-enabled/ipv6-wireguard-manager | sed 's/^/     /'
else
    echo "   ❌ Nginx配置文件不存在"
fi

echo ""

echo "3. 检查Nginx监听端口..."
echo "   Nginx监听状态:"
netstat -tlnp | grep nginx | sed 's/^/     /' || echo "    未找到Nginx监听端口"

echo ""

echo "4. 检查防火墙状态..."
if command -v ufw &> /dev/null; then
    echo "   UFW防火墙状态:"
    ufw status | sed 's/^/     /'
elif command -v iptables &> /dev/null; then
    echo "   iptables防火墙状态:"
    iptables -L -n | grep -E "(80|8000)" | sed 's/^/     /' || echo "    未找到相关规则"
else
    echo "   ⚠️  未检测到防火墙"
fi

echo ""

echo "5. 检查服务状态..."
echo "   Nginx服务状态:"
systemctl status nginx --no-pager -l | head -10 | sed 's/^/     /'

echo ""
echo "   IPv6 WireGuard Manager服务状态:"
systemctl status ipv6-wireguard-manager --no-pager -l | head -10 | sed 's/^/     /'

echo ""

echo "6. 测试本地连接..."
echo "   测试IPv4连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80; then
    echo "     ✅ IPv4前端连接正常"
else
    echo "     ❌ IPv4前端连接失败"
fi

echo "   测试IPv6连接:"
if curl -s -o /dev/null -w "%{http_code}" http://[::1]:80; then
    echo "     ✅ IPv6前端连接正常"
else
    echo "     ❌ IPv6前端连接失败"
fi

echo ""

echo "7. 测试外部IPv6连接..."
# 获取IPv6地址
ipv6_addr=$(ip -6 addr show | grep -E "inet6.*global" | head -1 | awk '{print $2}' | cut -d'/' -f1)
if [ -n "$ipv6_addr" ]; then
    echo "   使用IPv6地址: $ipv6_addr"
    echo "   测试外部IPv6连接:"
    if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_addr]:80" --connect-timeout 5; then
        echo "     ✅ 外部IPv6前端连接正常"
    else
        echo "     ❌ 外部IPv6前端连接失败"
    fi
else
    echo "   ❌ 未找到IPv6地址"
fi

echo ""

echo "8. 检查Nginx错误日志..."
echo "   Nginx错误日志 (最近10行):"
if [ -f "/var/log/nginx/error.log" ]; then
    tail -10 /var/log/nginx/error.log | sed 's/^/     /'
else
    echo "     Nginx错误日志文件不存在"
fi

echo ""

echo "9. 检查系统IPv6支持..."
echo "   IPv6模块状态:"
if lsmod | grep ipv6 > /dev/null; then
    echo "     ✅ IPv6模块已加载"
else
    echo "     ❌ IPv6模块未加载"
fi

echo "   IPv6转发状态:"
if [ -f "/proc/sys/net/ipv6/conf/all/forwarding" ]; then
    forwarding=$(cat /proc/sys/net/ipv6/conf/all/forwarding)
    if [ "$forwarding" = "1" ]; then
        echo "     ✅ IPv6转发已启用"
    else
        echo "     ⚠️  IPv6转发已禁用"
    fi
else
    echo "     ❌ 无法检查IPv6转发状态"
fi

echo ""

echo "=========================================="
echo "🔧 修复建议"
echo "=========================================="
echo ""

# 检查Nginx配置
if [ -f "/etc/nginx/sites-enabled/ipv6-wireguard-manager" ]; then
    if grep -q "listen \[::\]:80" /etc/nginx/sites-enabled/ipv6-wireguard-manager; then
        echo "✅ Nginx已配置IPv6监听"
    else
        echo "❌ Nginx未配置IPv6监听"
        echo "   建议修复Nginx配置"
    fi
else
    echo "❌ Nginx配置文件不存在"
    echo "   建议重新配置Nginx"
fi

echo ""

# 检查防火墙
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "80/tcp"; then
        echo "✅ UFW已开放80端口"
    else
        echo "❌ UFW未开放80端口"
        echo "   建议运行: ufw allow 80/tcp"
    fi
fi

echo ""

echo "💡 常见解决方案:"
echo "1. 确保Nginx配置了IPv6监听: listen [::]:80;"
echo "2. 检查防火墙是否开放了80端口"
echo "3. 确保系统支持IPv6"
echo "4. 检查网络路由配置"
echo "5. 验证IPv6地址是否正确"

echo ""
echo "🔧 快速修复命令:"
echo "sudo ufw allow 80/tcp"
echo "sudo systemctl restart nginx"
echo "sudo systemctl restart ipv6-wireguard-manager"
