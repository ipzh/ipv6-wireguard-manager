#!/bin/bash

# 诊断后端IPv6支持问题

set -e

echo "=========================================="
echo "🔍 诊断后端IPv6支持问题"
echo "=========================================="
echo ""

echo "1. 检查后端服务状态..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   ✅ IPv6 WireGuard Manager服务运行正常"
else
    echo "   ❌ IPv6 WireGuard Manager服务未运行"
    exit 1
fi

echo ""

echo "2. 检查端口监听状态..."
echo "   检查端口8000监听状态:"
if command -v ss &> /dev/null; then
    # 使用ss命令检查端口监听
    echo "   使用ss命令检查:"
    ss -tuln | grep ":8000" || echo "   未发现端口8000监听"
    
    echo "   检查IPv6监听:"
    ss -tuln | grep "\[::\]:8000" || echo "   未发现IPv6端口8000监听"
    
    echo "   检查IPv4监听:"
    ss -tuln | grep "0.0.0.0:8000" || echo "   未发现IPv4端口8000监听"
else
    echo "   ss命令不可用，尝试使用netstat:"
    if command -v netstat &> /dev/null; then
        netstat -tuln | grep ":8000" || echo "   未发现端口8000监听"
    else
        echo "   netstat命令也不可用"
    fi
fi

echo ""

echo "3. 检查服务配置..."
echo "   检查systemd服务配置:"
if [ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]; then
    echo "   ✅ 服务配置文件存在"
    echo "   服务配置内容:"
    cat /etc/systemd/system/ipv6-wireguard-manager.service | grep -E "(ExecStart|After|User|Group)" | sed 's/^/     /'
else
    echo "   ❌ 服务配置文件不存在"
fi

echo ""

echo "4. 检查进程监听..."
echo "   检查uvicorn进程:"
if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
    echo "   ✅ uvicorn进程正在运行"
    echo "   进程详情:"
    ps aux | grep "uvicorn.*app.main:app" | grep -v grep | sed 's/^/     /'
else
    echo "   ❌ uvicorn进程未运行"
fi

echo ""

echo "5. 测试本地连接..."
echo "   测试IPv4本地连接:"
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/health --connect-timeout 5; then
    echo "     ✅ IPv4本地连接正常"
else
    echo "     ❌ IPv4本地连接失败"
fi

echo "   测试IPv6本地连接:"
if curl -s -o /dev/null -w "%{http_code}" http://[::1]:8000/health --connect-timeout 5; then
    echo "     ✅ IPv6本地连接正常"
else
    echo "     ❌ IPv6本地连接失败"
fi

echo ""

echo "6. 测试外部IPv6连接..."
ipv6_ip="2605:6400:8a61:100::117"
echo "   测试外部IPv6连接 ($ipv6_ip):"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_ip]:8000/health" --connect-timeout 5; then
    echo "     ✅ 外部IPv6连接正常"
else
    echo "     ❌ 外部IPv6连接失败"
fi

echo ""

echo "7. 检查防火墙状态..."
if command -v ufw &> /dev/null; then
    echo "   检查UFW防火墙状态:"
    ufw status | sed 's/^/     /'
elif command -v iptables &> /dev/null; then
    echo "   检查iptables防火墙状态:"
    iptables -L INPUT | grep -E "(8000|ACCEPT|DROP)" | sed 's/^/     /' || echo "    未发现相关规则"
else
    echo "   未发现防火墙工具"
fi

echo ""

echo "8. 检查系统IPv6支持..."
echo "   检查IPv6模块:"
if [ -f "/proc/net/if_inet6" ]; then
    echo "     ✅ 系统支持IPv6"
    echo "    IPv6接口数量: $(wc -l < /proc/net/if_inet6)"
else
    echo "     ❌ 系统不支持IPv6"
fi

echo "   检查IPv6地址:"
if command -v ip &> /dev/null; then
    ip -6 addr show | grep -E "(inet6|UP)" | sed 's/^/     /'
else
    echo "     ip命令不可用"
fi

echo ""

echo "9. 检查服务日志..."
echo "   最近的服务日志:"
journalctl -u ipv6-wireguard-manager --no-pager -n 10 | sed 's/^/     /'

echo ""

echo "10. 检查网络连接..."
echo "   检查到后端的网络连接:"
if command -v telnet &> /dev/null; then
    echo "   测试IPv4连接:"
    timeout 3 telnet 127.0.0.1 8000 2>/dev/null && echo "     ✅ IPv4连接成功" || echo "     ❌ IPv4连接失败"
    
    echo "   测试IPv6连接:"
    timeout 3 telnet ::1 8000 2>/dev/null && echo "     ✅ IPv6连接成功" || echo "     ❌ IPv6连接失败"
else
    echo "   telnet命令不可用"
fi

echo ""

echo "=========================================="
echo "🎯 诊断完成"
echo "=========================================="
echo ""
echo "如果发现IPv6连接问题，可能的原因："
echo "1. 后端服务未正确监听IPv6接口"
echo "2. 防火墙阻止了IPv6连接"
echo "3. 系统IPv6配置问题"
echo "4. 网络路由问题"
echo ""
echo "建议的修复步骤："
echo "1. 检查服务配置中的host参数"
echo "2. 检查防火墙规则"
echo "3. 重启后端服务"
echo "4. 检查系统IPv6支持"
