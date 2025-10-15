#!/bin/bash

# 修复后端IPv6支持问题

set -e

echo "=========================================="
echo "🔧 修复后端IPv6支持问题"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

echo "1. 检查当前服务配置..."
if [ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]; then
    echo "   ✅ 服务配置文件存在"
    echo "   当前配置:"
    grep "ExecStart" /etc/systemd/system/ipv6-wireguard-manager.service | sed 's/^/     /'
else
    echo "   ❌ 服务配置文件不存在"
    exit 1
fi

echo ""

echo "2. 修复服务配置以支持IPv6..."
# 备份原配置
cp /etc/systemd/system/ipv6-wireguard-manager.service /etc/systemd/system/ipv6-wireguard-manager.service.backup

# 修复host参数从0.0.0.0改为::
sed -i 's/--host 0\.0\.0\.0/--host ::/g' /etc/systemd/system/ipv6-wireguard-manager.service

echo "   ✅ 服务配置已修复"
echo "   修复后的配置:"
grep "ExecStart" /etc/systemd/system/ipv6-wireguard-manager.service | sed 's/^/     /'

echo ""

echo "3. 重新加载systemd配置..."
systemctl daemon-reload
echo "   ✅ systemd配置已重新加载"

echo ""

echo "4. 重启后端服务..."
if systemctl restart ipv6-wireguard-manager; then
    echo "   ✅ 后端服务重启成功"
else
    echo "   ❌ 后端服务重启失败"
    exit 1
fi

echo ""

echo "5. 等待服务启动..."
sleep 5

echo ""

echo "6. 检查服务状态..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   ✅ 后端服务运行正常"
else
    echo "   ❌ 后端服务未运行"
    echo "   查看服务日志:"
    journalctl -u ipv6-wireguard-manager --no-pager -n 10 | sed 's/^/     /'
    exit 1
fi

echo ""

echo "7. 检查端口监听状态..."
echo "   检查IPv6端口监听:"
if command -v ss &> /dev/null; then
    if ss -tuln | grep "\[::\]:8000" > /dev/null; then
        echo "     ✅ IPv6端口8000监听正常"
        ss -tuln | grep "\[::\]:8000" | sed 's/^/       /'
    else
        echo "     ❌ IPv6端口8000未监听"
    fi
    
    echo "   检查IPv4端口监听:"
    if ss -tuln | grep "0.0.0.0:8000" > /dev/null; then
        echo "     ✅ IPv4端口8000监听正常"
        ss -tuln | grep "0.0.0.0:8000" | sed 's/^/       /'
    else
        echo "     ❌ IPv4端口8000未监听"
    fi
else
    echo "   ss命令不可用，使用netstat:"
    netstat -tuln | grep ":8000" | sed 's/^/     /'
fi

echo ""

echo "8. 测试连接..."
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

echo "9. 测试外部IPv6连接..."
ipv6_ip="2605:6400:8a61:100::117"
echo "   测试外部IPv6连接 ($ipv6_ip):"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_ip]:8000/health" --connect-timeout 5; then
    echo "     ✅ 外部IPv6连接正常"
else
    echo "     ❌ 外部IPv6连接失败"
fi

echo ""

echo "10. 检查防火墙状态..."
if command -v ufw &> /dev/null; then
    echo "   检查UFW防火墙状态:"
    ufw status | sed 's/^/     /'
    
    echo "   确保端口8000开放:"
    ufw allow 8000/tcp
    echo "     ✅ 端口8000已开放"
elif command -v iptables &> /dev/null; then
    echo "   检查iptables防火墙状态:"
    iptables -L INPUT | grep -E "(8000|ACCEPT|DROP)" | sed 's/^/     /' || echo "    未发现相关规则"
    
    echo "   添加端口8000规则:"
    iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
    echo "     ✅ 端口8000规则已添加"
else
    echo "   未发现防火墙工具"
fi

echo ""

echo "11. 显示访问地址..."
get_ip_addresses() {
    local ipv4_ips=()
    local ipv6_ips=()
    
    # 获取IPv4地址
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
            ipv4_ips+=("$line")
        fi
    done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
    
    # 获取IPv6地址
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
            ipv6_ips+=("$line")
        fi
    done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')
    
    echo "  📱 本地访问:"
    echo "    API文档: http://localhost:8000/docs"
    echo "    健康检查: http://localhost:8000/health"
    echo ""
    
    if [ ${#ipv4_ips[@]} -gt 0 ]; then
        echo "  🌐 IPv4访问:"
        for ip in "${ipv4_ips[@]}"; do
            echo "    API文档: http://$ip:8000/docs"
            echo "    健康检查: http://$ip:8000/health"
        done
        echo ""
    fi
    
    if [ ${#ipv6_ips[@]} -gt 0 ]; then
        echo "  🔗 IPv6访问:"
        for ip in "${ipv6_ips[@]}"; do
            echo "    API文档: http://[$ip]:8000/docs"
            echo "    健康检查: http://[$ip]:8000/health"
        done
        echo ""
    fi
}

get_ip_addresses

echo ""

echo "=========================================="
echo "🎉 IPv6支持修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "  ✅ 修复了后端服务配置，从--host 0.0.0.0改为--host ::"
echo "  ✅ 重新加载了systemd配置"
echo "  ✅ 重启了后端服务"
echo "  ✅ 检查了端口监听状态"
echo "  ✅ 测试了IPv4和IPv6连接"
echo "  ✅ 配置了防火墙规则"
echo ""
echo "现在后端应该支持IPv6访问了！"
echo ""
echo "如果问题仍然存在，请查看日志："
echo "  journalctl -u ipv6-wireguard-manager -f"
