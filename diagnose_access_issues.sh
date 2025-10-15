#!/bin/bash

# 诊断访问问题脚本
# 检查IPv6访问和API连接问题

set -e

echo "=========================================="
echo "🔍 诊断访问问题脚本"
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
    echo "   ✅ Nginx配置文件存在"
    echo "   配置内容:"
    cat "$nginx_config" | sed 's/^/     /'
else
    echo "   ❌ Nginx配置文件不存在"
fi

echo ""

echo "4. 检查前端文件..."
frontend_dir="/opt/ipv6-wireguard-manager/frontend/dist"
if [ -d "$frontend_dir" ]; then
    echo "   ✅ 前端目录存在: $frontend_dir"
    echo "   文件列表:"
    ls -la "$frontend_dir" | sed 's/^/     /'
    
    if [ -f "$frontend_dir/index.html" ]; then
        echo "   ✅ index.html文件存在"
        echo "   文件大小: $(du -h "$frontend_dir/index.html" | cut -f1)"
    else
        echo "   ❌ index.html文件不存在"
    fi
else
    echo "   ❌ 前端目录不存在: $frontend_dir"
fi

echo ""

echo "5. 测试本地连接..."
echo "   测试本地前端连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 --connect-timeout 3; then
    echo "     ✅ 本地前端连接正常"
else
    echo "     ❌ 本地前端连接失败"
fi

echo "   测试本地API连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health --connect-timeout 3; then
    echo "     ✅ 本地API连接正常"
else
    echo "     ❌ 本地API连接失败"
fi

echo ""

echo "6. 测试IPv6连接..."
# 获取IPv6地址
ipv6_ips=()
while IFS= read -r line; do
    if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
        ipv6_ips+=("$line")
    fi
done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')

if [ ${#ipv6_ips[@]} -gt 0 ]; then
    echo "   发现IPv6地址:"
    for ip in "${ipv6_ips[@]}"; do
        echo "     IPv6: $ip"
        
        echo "     测试IPv6前端连接:"
        if curl -s -o /dev/null -w "%{http_code}" "http://[$ip]:80" --connect-timeout 3; then
            echo "       ✅ IPv6前端连接正常"
        else
            echo "       ❌ IPv6前端连接失败"
        fi
        
        echo "     测试IPv6 API连接:"
        if curl -s -o /dev/null -w "%{http_code}" "http://[$ip]:8000/health" --connect-timeout 3; then
            echo "       ✅ IPv6 API连接正常"
        else
            echo "       ❌ IPv6 API连接失败"
        fi
    done
else
    echo "   ⚠️  未发现IPv6地址"
fi

echo ""

echo "7. 检查防火墙..."
if command -v ufw &> /dev/null; then
    echo "   UFW状态:"
    ufw status | sed 's/^/     /'
else
    echo "   UFW未安装"
fi

if command -v iptables &> /dev/null; then
    echo "   iptables规则:"
    iptables -L -n | grep -E "(80|8000)" | sed 's/^/     /' || echo "     未找到相关规则"
fi

echo ""

echo "8. 检查服务日志..."
echo "   Nginx错误日志 (最近5行):"
if [ -f "/var/log/nginx/error.log" ]; then
    tail -5 /var/log/nginx/error.log | sed 's/^/     /'
else
    echo "     Nginx错误日志不存在"
fi

echo "   IPv6 WireGuard Manager服务日志 (最近5行):"
journalctl -u ipv6-wireguard-manager --no-pager -n 5 | sed 's/^/     /'

echo ""

echo "9. 检查网络接口..."
echo "   所有网络接口:"
ip addr show | grep -E "(inet|inet6)" | sed 's/^/     /'

echo ""

echo "10. 生成诊断报告..."
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
echo "1. 修复IPv6访问: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_ipv6_access.sh | bash"
echo "2. 修复安装问题: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_installation_issues.sh | bash"
echo "3. 修复MySQL驱动: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_mysql_driver.sh | bash"
