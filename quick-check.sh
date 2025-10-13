#!/bin/bash

# 快速检查脚本 - 用于快速诊断前端空白问题

echo "=== IPv6 WireGuard Manager 快速检查 ==="
echo ""

# 检查服务状态
echo "1. 服务状态:"
echo "   Nginx: $(systemctl is-active nginx 2>/dev/null || echo '未安装')"
echo "   后端: $(systemctl is-active ipv6-wireguard-manager 2>/dev/null || echo '未安装')"
echo "   PostgreSQL: $(systemctl is-active postgresql 2>/dev/null || echo '未安装')"
echo ""

# 检查端口
echo "2. 端口监听:"
echo "   端口80: $(ss -tlnp | grep ':80 ' > /dev/null && echo '正常' || echo '未监听')"
echo "   端口8000: $(ss -tlnp | grep ':8000 ' > /dev/null && echo '正常' || echo '未监听')"
echo ""

# 检查API
echo "3. API连接:"
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "   本地API: 正常"
else
    echo "   本地API: 失败"
fi
echo ""

# 检查前端文件
echo "4. 前端文件:"
if [ -f "/opt/ipv6-wireguard-manager/frontend/dist/index.html" ]; then
    echo "   前端构建: 正常"
else
    echo "   前端构建: 缺失"
fi
echo ""

# 检查Nginx配置
echo "5. Nginx配置:"
if [ -f "/etc/nginx/sites-available/ipv6-wireguard-manager" ]; then
    echo "   配置文件: 存在"
    if nginx -t > /dev/null 2>&1; then
        echo "   配置语法: 正确"
    else
        echo "   配置语法: 错误"
    fi
else
    echo "   配置文件: 缺失"
fi
echo ""

# 获取访问地址
SERVER_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
echo "6. 访问地址:"
echo "   http://$SERVER_IP"
echo ""

echo "=== 检查完成 ==="
echo ""
echo "如果发现问题，请运行修复脚本:"
echo "  bash fix-frontend-blank.sh"
echo ""
echo "或运行详细诊断:"
echo "  bash diagnose-frontend-issue.sh"
echo ""
