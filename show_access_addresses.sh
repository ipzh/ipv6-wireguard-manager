#!/bin/bash

# 显示访问地址脚本
# 正确显示IPv4和IPv6访问地址

set -e

echo "=========================================="
echo "🌐 IPv6 WireGuard Manager 访问地址"
echo "=========================================="
echo ""

# 获取端口配置
WEB_PORT=80
API_PORT=8000

# 获取IP地址的函数
get_ip_addresses() {
    local ipv4_ips=()
    local ipv6_ips=()
    
    echo "🔍 正在获取网络地址..."
    echo ""
    
    # 获取IPv4地址
    echo "📡 获取IPv4地址:"
    if command -v ip &> /dev/null; then
        # 使用ip命令
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                ipv4_ips+=("$line")
                echo "   ✅ 发现IPv4地址: $line"
            fi
        done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
    fi
    
    # 如果ip命令失败，尝试ifconfig
    if [ ${#ipv4_ips[@]} -eq 0 ] && command -v ifconfig &> /dev/null; then
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                ipv4_ips+=("$line")
                echo "   ✅ 发现IPv4地址: $line"
            fi
        done < <(ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1')
    fi
    
    # 如果还是失败，尝试hostname -I
    if [ ${#ipv4_ips[@]} -eq 0 ]; then
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
                ipv4_ips+=("$line")
                echo "   ✅ 发现IPv4地址: $line"
            fi
        done < <(hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '127.0.0.1')
    fi
    
    if [ ${#ipv4_ips[@]} -eq 0 ]; then
        echo "   ⚠️  未找到IPv4地址"
    fi
    
    echo ""
    
    # 获取IPv6地址
    echo "📡 获取IPv6地址:"
    if command -v ip &> /dev/null; then
        # 使用ip命令
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
                ipv6_ips+=("$line")
                echo "   ✅ 发现IPv6地址: $line"
            fi
        done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')
    fi
    
    # 如果ip命令失败，尝试ifconfig
    if [ ${#ipv6_ips[@]} -eq 0 ] && command -v ifconfig &> /dev/null; then
        while IFS= read -r line; do
            if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
                ipv6_ips+=("$line")
                echo "   ✅ 发现IPv6地址: $line"
            fi
        done < <(ifconfig 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | grep -v '::1' | grep -v '^fe80:')
    fi
    
    if [ ${#ipv6_ips[@]} -eq 0 ]; then
        echo "   ⚠️  未找到IPv6地址"
    fi
    
    echo ""
    
    # 显示访问地址
    echo "🌐 访问地址:"
    echo ""
    
    # 本地访问
    echo "  📱 本地访问:"
    echo "    前端界面: http://localhost:$WEB_PORT"
    echo "    API文档: http://localhost:$WEB_PORT/api/v1/docs"
    echo "    健康检查: http://localhost:$API_PORT/health"
    echo ""
    
    # IPv4访问
    if [ ${#ipv4_ips[@]} -gt 0 ]; then
        echo "  🌐 IPv4访问:"
        for ip in "${ipv4_ips[@]}"; do
            echo "    前端界面: http://$ip:$WEB_PORT"
            echo "    API文档: http://$ip:$WEB_PORT/api/v1/docs"
            echo "    健康检查: http://$ip:$API_PORT/health"
        done
        echo ""
    fi
    
    # IPv6访问
    if [ ${#ipv6_ips[@]} -gt 0 ]; then
        echo "  🔗 IPv6访问:"
        for ip in "${ipv6_ips[@]}"; do
            echo "    前端界面: http://[$ip]:$WEB_PORT"
            echo "    API文档: http://[$ip]:$WEB_PORT/api/v1/docs"
            echo "    健康检查: http://[$ip]:$API_PORT/health"
        done
        echo ""
    fi
    
    # 检查服务状态
    echo "🔧 服务状态:"
    if systemctl is-active --quiet nginx; then
        echo "  ✅ Nginx服务运行正常"
    else
        echo "  ❌ Nginx服务未运行"
    fi
    
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        echo "  ✅ IPv6 WireGuard Manager服务运行正常"
    else
        echo "  ❌ IPv6 WireGuard Manager服务未运行"
    fi
    echo ""
    
    # 测试连接
    echo "🧪 连接测试:"
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$WEB_PORT --connect-timeout 3; then
        echo "  ✅ 前端连接正常"
    else
        echo "  ❌ 前端连接失败"
    fi
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$API_PORT/health --connect-timeout 3; then
        echo "  ✅ API连接正常"
    else
        echo "  ❌ API连接失败"
    fi
    echo ""
    
    # 显示管理命令
    echo "🛠️  管理命令:"
    echo "  启动服务: systemctl start ipv6-wireguard-manager"
    echo "  停止服务: systemctl stop ipv6-wireguard-manager"
    echo "  重启服务: systemctl restart ipv6-wireguard-manager"
    echo "  查看状态: systemctl status ipv6-wireguard-manager"
    echo "  查看日志: journalctl -u ipv6-wireguard-manager -f"
    echo ""
    
    # 显示默认登录信息
    echo "🔐 默认登录信息:"
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo ""
    
    # 显示项目信息
    echo "📚 项目信息:"
    echo "  项目地址: https://github.com/ipzh/ipv6-wireguard-manager"
    echo "  问题反馈: https://github.com/ipzh/ipv6-wireguard-manager/issues"
    echo ""
}

# 运行主函数
get_ip_addresses

echo "=========================================="
echo "🎉 访问地址显示完成！"
echo "=========================================="
