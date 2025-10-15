#!/bin/bash

# 快速诊断IP地址获取问题

set -e

echo "🔍 快速诊断IP地址获取问题..."

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 需要root权限"
    exit 1
fi

echo "1. 检查网络接口..."
ip addr show | grep -E "(inet|inet6)" | head -10

echo ""
echo "2. 获取IPv4地址..."
ipv4_ips=()
while IFS= read -r line; do
    if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
        ipv4_ips+=("$line")
        echo "  ✅ IPv4: $line"
    fi
done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)

if [ ${#ipv4_ips[@]} -eq 0 ]; then
    echo "  ❌ 未发现IPv4地址"
    echo "  尝试使用ifconfig:"
    ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | sed 's/^/    /'
fi

echo ""
echo "3. 获取IPv6地址..."
ipv6_ips=()
while IFS= read -r line; do
    if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
        ipv6_ips+=("$line")
        echo "  ✅ IPv6: $line"
    fi
done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')

if [ ${#ipv6_ips[@]} -eq 0 ]; then
    echo "  ❌ 未发现IPv6地址"
    echo "  尝试使用ifconfig:"
    ifconfig 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | grep -v '::1' | grep -v '^fe80:' | sed 's/^/    /'
fi

echo ""
echo "4. 测试网络连接..."
echo "  IPv4连接测试:"
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "    ✅ IPv4连接正常"
else
    echo "    ❌ IPv4连接失败"
fi

echo "  IPv6连接测试:"
if ping -c 1 2001:4860:4860::8888 >/dev/null 2>&1; then
    echo "    ✅ IPv6连接正常"
else
    echo "    ❌ IPv6连接失败"
fi

echo ""
echo "5. 显示访问地址..."
echo "  📱 本地访问:"
echo "    前端界面: http://localhost:80"
echo "    API文档: http://localhost:80/api/v1/docs"
echo "    健康检查: http://localhost:8000/health"

if [ ${#ipv4_ips[@]} -gt 0 ]; then
    echo ""
    echo "  🌐 IPv4访问:"
    for ip in "${ipv4_ips[@]}"; do
        echo "    前端界面: http://$ip:80"
        echo "    API文档: http://$ip:80/api/v1/docs"
        echo "    健康检查: http://$ip:8000/health"
    done
fi

if [ ${#ipv6_ips[@]} -gt 0 ]; then
    echo ""
    echo "  🔗 IPv6访问:"
    for ip in "${ipv6_ips[@]}"; do
        echo "    前端界面: http://[$ip]:80"
        echo "    API文档: http://[$ip]:80/api/v1/docs"
        echo "    健康检查: http://[$ip]:8000/health"
    done
fi

echo ""
echo "📊 统计结果:"
echo "  IPv4地址数量: ${#ipv4_ips[@]}"
echo "  IPv6地址数量: ${#ipv6_ips[@]}"

if [ ${#ipv4_ips[@]} -eq 0 ] && [ ${#ipv6_ips[@]} -eq 0 ]; then
    echo ""
    echo "❌ 未发现任何IP地址！"
    echo "请检查网络配置或运行完整诊断脚本："
    echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_ip_detection.sh | bash"
fi
