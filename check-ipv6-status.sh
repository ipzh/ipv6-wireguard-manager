#!/bin/bash

echo "🔍 检查IPv6服务状态..."
echo "================================"

# 获取IPv6地址
echo "🌐 检测IPv6地址..."
IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)

if [ -n "$IPV6_ADDRESS" ]; then
    echo "✅ 检测到IPv6地址: $IPV6_ADDRESS"
else
    echo "❌ 未检测到IPv6地址"
fi

# 检查服务状态
echo ""
echo "🔧 检查服务状态..."
echo "后端服务状态:"
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务未运行"
fi

echo "Nginx服务状态:"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx服务运行正常"
else
    echo "❌ Nginx服务未运行"
fi

# 检查端口监听
echo ""
echo "🔌 检查端口监听..."
echo "端口8000 (后端API):"
ss -tlnp | grep :8000

echo ""
echo "端口80 (Nginx):"
ss -tlnp | grep :80

# 测试API访问
echo ""
echo "🧪 测试API访问..."
echo "测试本地API:"
if curl -s http://127.0.0.1:8000/api/v1/status >/dev/null 2>&1; then
    echo "✅ 本地API访问正常"
    curl -s http://127.0.0.1:8000/api/v1/status
else
    echo "❌ 本地API访问失败"
fi

echo ""
echo "测试健康检查:"
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    echo "✅ 健康检查正常"
    curl -s http://127.0.0.1:8000/health
else
    echo "❌ 健康检查失败"
fi

# 测试IPv6访问
if [ -n "$IPV6_ADDRESS" ]; then
    echo ""
    echo "🌐 测试IPv6访问..."
    echo "测试IPv6 API:"
    if curl -6 -s http://[$IPV6_ADDRESS]/api/v1/status >/dev/null 2>&1; then
        echo "✅ IPv6 API访问正常"
        curl -6 -s http://[$IPV6_ADDRESS]/api/v1/status
    else
        echo "❌ IPv6 API访问失败"
    fi
    
    echo ""
    echo "测试IPv6前端:"
    if curl -6 -s http://[$IPV6_ADDRESS]/ >/dev/null 2>&1; then
        echo "✅ IPv6前端访问正常"
    else
        echo "❌ IPv6前端访问失败"
    fi
fi

# 测试Nginx代理
echo ""
echo "🌐 测试Nginx代理..."
echo "测试本地Nginx:"
if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    echo "✅ 本地Nginx代理正常"
    curl -s http://localhost/api/v1/status
else
    echo "❌ 本地Nginx代理失败"
fi

if [ -n "$IPV6_ADDRESS" ]; then
    echo ""
    echo "测试IPv6 Nginx:"
    if curl -6 -s http://[$IPV6_ADDRESS]/api/v1/status >/dev/null 2>&1; then
        echo "✅ IPv6 Nginx代理正常"
        curl -6 -s http://[$IPV6_ADDRESS]/api/v1/status
    else
        echo "❌ IPv6 Nginx代理失败"
    fi
fi

# 显示访问地址
echo ""
echo "========================================"
echo "🎯 访问地址总结:"
echo ""
echo "📱 本地访问:"
echo "   前端: http://localhost"
echo "   API:  http://localhost/api/v1/status"
echo "   健康: http://localhost/health"
echo ""

if [ -n "$IPV6_ADDRESS" ]; then
    echo "🌐 IPv6访问:"
    echo "   前端: http://[$IPV6_ADDRESS]"
    echo "   API:  http://[$IPV6_ADDRESS]/api/v1/status"
    echo "   健康: http://[$IPV6_ADDRESS]/health"
    echo ""
fi

echo "📊 服务状态:"
echo "   后端服务: $(systemctl is-active ipv6-wireguard-manager)"
echo "   Nginx服务: $(systemctl is-active nginx)"
echo "   IPv6地址: ${IPV6_ADDRESS:-未检测到}"

# 检查最近的访问日志
echo ""
echo "📋 最近的访问日志:"
echo "后端服务日志 (最近5条):"
sudo journalctl -u ipv6-wireguard-manager --no-pager -n 5

echo ""
echo "Nginx访问日志 (最近5条):"
sudo tail -5 /var/log/nginx/access.log 2>/dev/null || echo "Nginx访问日志不可用"
