#!/bin/bash

# 修复IP地址显示问题脚本
# 修复安装脚本中IP地址显示不正确的问题

set -e

echo "=========================================="
echo "🔧 修复IP地址显示问题脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 检查安装目录
INSTALL_DIR="/opt/ipv6-wireguard-manager"
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ 安装目录不存在: $INSTALL_DIR"
    exit 1
fi

echo "📁 安装目录: $INSTALL_DIR"

echo ""

# 1. 检查当前IP地址
echo "1. 检查当前IP地址..."
echo "   IPv4地址:"
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | sed 's/^/     /' || echo "     未找到IPv4地址"

echo "   IPv6地址:"
ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | grep -v '::1' | grep -v '^fe80:' | sed 's/^/     /' || echo "     未找到IPv6地址"

echo ""

# 2. 检查Nginx配置
echo "2. 检查Nginx配置..."
nginx_config="/etc/nginx/sites-enabled/ipv6-wireguard-manager"
if [ -f "$nginx_config" ]; then
    echo "   ✅ Nginx配置文件存在"
    echo "   配置内容:"
    cat "$nginx_config" | sed 's/^/     /'
else
    echo "   ❌ Nginx配置文件不存在"
fi

echo ""

# 3. 检查服务状态
echo "3. 检查服务状态..."
if systemctl is-active --quiet nginx; then
    echo "   ✅ Nginx服务运行正常"
else
    echo "   ❌ Nginx服务未运行"
fi

if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   ✅ IPv6 WireGuard Manager服务运行正常"
else
    echo "   ❌ IPv6 WireGuard Manager服务未运行"
fi

echo ""

# 4. 检查端口监听
echo "4. 检查端口监听..."
echo "   端口80监听状态:"
netstat -tlnp | grep :80 | sed 's/^/     /' || echo "     端口80未监听"

echo "   端口8000监听状态:"
netstat -tlnp | grep :8000 | sed 's/^/     /' || echo "     端口8000未监听"

echo ""

# 5. 测试连接
echo "5. 测试连接..."
echo "   测试本地连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 --connect-timeout 3; then
    echo "     ✅ 本地前端连接正常"
else
    echo "     ❌ 本地前端连接失败"
fi

if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health --connect-timeout 3; then
    echo "     ✅ 本地API连接正常"
else
    echo "     ❌ 本地API连接失败"
fi

echo ""

# 6. 显示正确的访问地址
echo "6. 显示正确的访问地址..."
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
}

get_ip_addresses

echo ""

# 7. 修复建议
echo "7. 修复建议..."
if [ ! -f "$nginx_config" ]; then
    echo "   ❌ 需要创建Nginx配置文件"
    echo "     运行: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_ipv6_access.sh | bash"
fi

if ! systemctl is-active --quiet nginx; then
    echo "   ❌ 需要启动Nginx服务"
    echo "     运行: systemctl start nginx"
fi

if ! systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   ❌ 需要启动IPv6 WireGuard Manager服务"
    echo "     运行: systemctl start ipv6-wireguard-manager"
fi

echo ""

echo "=========================================="
echo "🎉 IP地址显示问题诊断完成！"
echo "=========================================="
echo ""
echo "如果发现问题，请运行相应的修复脚本："
echo "1. 修复IPv6访问: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_ipv6_access.sh | bash"
echo "2. 显示访问地址: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/show_access_addresses.sh | bash"
echo "3. 修复安装问题: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_installation_issues.sh | bash"
