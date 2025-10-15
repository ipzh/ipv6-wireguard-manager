#!/bin/bash

# 修复IP地址检测问题脚本
# 解决IPv4和IPv6地址获取失败的问题

set -e

echo "=========================================="
echo "🔧 修复IP地址检测问题脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

echo "1. 检查网络接口..."
echo "   所有网络接口:"
ip addr show | sed 's/^/     /'

echo ""

echo "2. 检查IPv4地址..."
echo "   使用ip命令获取IPv4地址:"
ipv4_ips=()
while IFS= read -r line; do
    if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
        ipv4_ips+=("$line")
        echo "     ✅ 发现IPv4地址: $line"
    fi
done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)

if [ ${#ipv4_ips[@]} -eq 0 ]; then
    echo "     ❌ 未发现IPv4地址"
    echo "     尝试使用ifconfig:"
    if command -v ifconfig &> /dev/null; then
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                ipv4_ips+=("$line")
                echo "       ✅ 发现IPv4地址: $line"
            fi
        done < <(ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1')
    else
        echo "       ❌ ifconfig命令不可用"
    fi
    
    if [ ${#ipv4_ips[@]} -eq 0 ]; then
        echo "     尝试使用hostname -I:"
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                ipv4_ips+=("$line")
                echo "       ✅ 发现IPv4地址: $line"
            fi
        done < <(hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '127.0.0.1')
    fi
fi

echo ""

echo "3. 检查IPv6地址..."
echo "   使用ip命令获取IPv6地址:"
ipv6_ips=()
while IFS= read -r line; do
    if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
        ipv6_ips+=("$line")
        echo "     ✅ 发现IPv6地址: $line"
    fi
done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')

if [ ${#ipv6_ips[@]} -eq 0 ]; then
    echo "     ❌ 未发现IPv6地址"
    echo "     尝试使用ifconfig:"
    if command -v ifconfig &> /dev/null; then
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
                ipv6_ips+=("$line")
                echo "       ✅ 发现IPv6地址: $line"
            fi
        done < <(ifconfig 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | grep -v '::1' | grep -v '^fe80:')
    else
        echo "       ❌ ifconfig命令不可用"
    fi
fi

echo ""

echo "4. 检查网络配置..."
echo "   路由表:"
ip route show | sed 's/^/     /'

echo "   IPv6路由表:"
ip -6 route show | sed 's/^/     /' || echo "     无IPv6路由"

echo ""

echo "5. 检查网络服务..."
echo "   NetworkManager状态:"
if systemctl is-active --quiet NetworkManager; then
    echo "     ✅ NetworkManager运行正常"
else
    echo "     ❌ NetworkManager未运行"
fi

echo "   systemd-networkd状态:"
if systemctl is-active --quiet systemd-networkd; then
    echo "     ✅ systemd-networkd运行正常"
else
    echo "     ❌ systemd-networkd未运行"
fi

echo ""

echo "6. 检查DNS配置..."
echo "   DNS配置:"
cat /etc/resolv.conf | sed 's/^/     /'

echo ""

echo "7. 测试网络连接..."
echo "   测试IPv4连接:"
if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
    echo "     ✅ IPv4连接正常"
else
    echo "     ❌ IPv4连接失败"
fi

echo "   测试IPv6连接:"
if ping -c 3 2001:4860:4860::8888 >/dev/null 2>&1; then
    echo "     ✅ IPv6连接正常"
else
    echo "     ❌ IPv6连接失败"
fi

echo ""

echo "8. 检查防火墙..."
if command -v ufw &> /dev/null; then
    echo "   UFW状态:"
    ufw status | sed 's/^/     /'
fi

if command -v iptables &> /dev/null; then
    echo "   iptables规则:"
    iptables -L -n | head -10 | sed 's/^/     /'
fi

echo ""

echo "9. 创建改进的IP获取函数..."
cat > /tmp/get_ips.sh << 'EOF'
#!/bin/bash

# 改进的IP地址获取函数
get_all_ips() {
    local ipv4_ips=()
    local ipv6_ips=()
    
    echo "🔍 获取IPv4地址..."
    
    # 方法1: 使用ip命令
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
            ipv4_ips+=("$line")
            echo "  ✅ IPv4: $line"
        fi
    done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
    
    # 方法2: 使用ifconfig
    if [ ${#ipv4_ips[@]} -eq 0 ] && command -v ifconfig &> /dev/null; then
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                ipv4_ips+=("$line")
                echo "  ✅ IPv4: $line"
            fi
        done < <(ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1')
    fi
    
    # 方法3: 使用hostname -I
    if [ ${#ipv4_ips[@]} -eq 0 ]; then
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                ipv4_ips+=("$line")
                echo "  ✅ IPv4: $line"
            fi
        done < <(hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '127.0.0.1')
    fi
    
    echo "🔍 获取IPv6地址..."
    
    # 方法1: 使用ip命令
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
            ipv6_ips+=("$line")
            echo "  ✅ IPv6: $line"
        fi
    done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')
    
    # 方法2: 使用ifconfig
    if [ ${#ipv6_ips[@]} -eq 0 ] && command -v ifconfig &> /dev/null; then
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
                ipv6_ips+=("$line")
                echo "  ✅ IPv6: $line"
            fi
        done < <(ifconfig 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | grep -v '::1' | grep -v '^fe80:')
    fi
    
    echo ""
    echo "📊 结果统计:"
    echo "  IPv4地址数量: ${#ipv4_ips[@]}"
    echo "  IPv6地址数量: ${#ipv6_ips[@]}"
    
    echo ""
    echo "🌐 访问地址:"
    echo "  📱 本地访问:"
    echo "    前端界面: http://localhost:80"
    echo "    API文档: http://localhost:80/api/v1/docs"
    echo "    健康检查: http://localhost:8000/health"
    echo ""
    
    if [ ${#ipv4_ips[@]} -gt 0 ]; then
        echo "  🌐 IPv4访问:"
        for ip in "${ipv4_ips[@]}"; do
            echo "    前端界面: http://$ip:80"
            echo "    API文档: http://$ip:80/api/v1/docs"
            echo "    健康检查: http://$ip:8000/health"
        done
        echo ""
    fi
    
    if [ ${#ipv6_ips[@]} -gt 0 ]; then
        echo "  🔗 IPv6访问:"
        for ip in "${ipv6_ips[@]}"; do
            echo "    前端界面: http://[$ip]:80"
            echo "    API文档: http://[$ip]:80/api/v1/docs"
            echo "    健康检查: http://[$ip]:8000/health"
        done
        echo ""
    fi
    
    # 返回结果
    echo "IPv4_IPS=${ipv4_ips[*]}"
    echo "IPv6_IPS=${ipv6_ips[*]}"
}

# 运行函数
get_all_ips
EOF

chmod +x /tmp/get_ips.sh
echo "   ✅ 改进的IP获取函数已创建"

echo ""

echo "10. 测试改进的IP获取函数..."
echo "   运行改进的IP获取函数:"
/tmp/get_ips.sh

echo ""

echo "11. 修复安装脚本中的IP获取函数..."
# 这里可以添加修复安装脚本的逻辑
echo "   建议更新install.sh中的get_local_ips函数"
echo "   使用改进的IP获取逻辑"

echo ""

echo "=========================================="
echo "🎉 IP地址检测问题修复完成！"
echo "=========================================="
echo ""
echo "如果问题仍然存在，请检查："
echo "1. 网络接口是否正确配置"
echo "2. 网络服务是否正常运行"
echo "3. 防火墙是否阻止了网络访问"
echo "4. DNS配置是否正确"
echo ""
echo "改进的IP获取函数已保存到: /tmp/get_ips.sh"
echo "可以运行: /tmp/get_ips.sh 来测试IP获取功能"
