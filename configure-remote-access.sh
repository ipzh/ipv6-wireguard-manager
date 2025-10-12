#!/bin/bash

echo "🌐 配置远程访问端口..."
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检测防火墙类型
detect_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        echo "ufw"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "firewalld"
    elif command -v iptables >/dev/null 2>&1; then
        echo "iptables"
    else
        echo "none"
    fi
}

# 获取当前IP地址
get_ip_addresses() {
    echo "🔍 检测网络配置..."
    
    # IPv4地址
    IPV4_LOCAL=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    IPV4_PUBLIC=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
    
    # IPv6地址
    IPV6_LOCAL=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    IPV6_PUBLIC=$(curl -s -6 ifconfig.me 2>/dev/null || echo "")
    
    echo "IPv4地址:"
    echo "  本地: $IPV4_LOCAL"
    if [ -n "$IPV4_PUBLIC" ]; then
        echo "  公网: $IPV4_PUBLIC"
    else
        echo "  公网: 未检测到"
    fi
    
    echo "IPv6地址:"
    if [ -n "$IPV6_LOCAL" ]; then
        echo "  本地: $IPV6_LOCAL"
    else
        echo "  本地: 未检测到"
    fi
    if [ -n "$IPV6_PUBLIC" ]; then
        echo "  公网: $IPV6_PUBLIC"
    else
        echo "  公网: 未检测到"
    fi
    echo ""
}

# 检查端口状态
check_port_status() {
    echo "🔌 检查端口状态..."
    
    echo "端口80 (HTTP):"
    if ss -tlnp | grep -q :80; then
        echo -e "  ${GREEN}✅ 端口80正在监听${NC}"
        ss -tlnp | grep :80
    else
        echo -e "  ${RED}❌ 端口80未监听${NC}"
    fi
    
    echo ""
    echo "端口8000 (后端API):"
    if ss -tlnp | grep -q :8000; then
        echo -e "  ${GREEN}✅ 端口8000正在监听${NC}"
        ss -tlnp | grep :8000
    else
        echo -e "  ${RED}❌ 端口8000未监听${NC}"
    fi
    
    echo ""
    echo "端口443 (HTTPS):"
    if ss -tlnp | grep -q :443; then
        echo -e "  ${GREEN}✅ 端口443正在监听${NC}"
        ss -tlnp | grep :443
    else
        echo -e "  ${YELLOW}⚠️  端口443未监听 (HTTPS未配置)${NC}"
    fi
    echo ""
}

# 配置UFW防火墙
configure_ufw() {
    echo "🔥 配置UFW防火墙..."
    
    # 检查UFW状态
    if ! command -v ufw >/dev/null 2>&1; then
        echo -e "${RED}❌ UFW未安装${NC}"
        return 1
    fi
    
    echo "当前UFW状态:"
    sudo ufw status
    
    echo ""
    echo "开放必要端口..."
    
    # 开放SSH端口 (22)
    echo "开放SSH端口 (22)..."
    sudo ufw allow 22/tcp
    
    # 开放HTTP端口 (80)
    echo "开放HTTP端口 (80)..."
    sudo ufw allow 80/tcp
    
    # 开放HTTPS端口 (443)
    echo "开放HTTPS端口 (443)..."
    sudo ufw allow 443/tcp
    
    # 开放后端API端口 (8000) - 可选，通常不需要
    read -p "是否开放后端API端口8000? (y/N): " open_api_port
    if [[ $open_api_port == [yY] ]]; then
        echo "开放后端API端口 (8000)..."
        sudo ufw allow 8000/tcp
    fi
    
    # 启用防火墙
    echo "启用UFW防火墙..."
    sudo ufw --force enable
    
    echo ""
    echo "UFW配置完成:"
    sudo ufw status
}

# 配置Firewalld防火墙
configure_firewalld() {
    echo "🔥 配置Firewalld防火墙..."
    
    if ! command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "${RED}❌ Firewalld未安装${NC}"
        return 1
    fi
    
    echo "当前防火墙状态:"
    sudo firewall-cmd --state
    
    echo ""
    echo "开放必要端口..."
    
    # 开放HTTP端口
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-port=80/tcp
    
    # 开放HTTPS端口
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --permanent --add-port=443/tcp
    
    # 开放SSH端口
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --permanent --add-port=22/tcp
    
    # 询问是否开放API端口
    read -p "是否开放后端API端口8000? (y/N): " open_api_port
    if [[ $open_api_port == [yY] ]]; then
        sudo firewall-cmd --permanent --add-port=8000/tcp
    fi
    
    # 重新加载防火墙配置
    sudo firewall-cmd --reload
    
    echo ""
    echo "Firewalld配置完成:"
    sudo firewall-cmd --list-all
}

# 配置iptables防火墙
configure_iptables() {
    echo "🔥 配置iptables防火墙..."
    
    if ! command -v iptables >/dev/null 2>&1; then
        echo -e "${RED}❌ iptables未安装${NC}"
        return 1
    fi
    
    echo "当前iptables规则:"
    sudo iptables -L -n
    
    echo ""
    echo "添加防火墙规则..."
    
    # 允许SSH
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # 允许HTTP
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    
    # 允许HTTPS
    sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # 询问是否允许API端口
    read -p "是否开放后端API端口8000? (y/N): " open_api_port
    if [[ $open_api_port == [yY] ]]; then
        sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
    fi
    
    # 保存iptables规则
    if command -v iptables-save >/dev/null 2>&1; then
        sudo iptables-save > /etc/iptables/rules.v4 2>/dev/null || echo "无法保存iptables规则"
    fi
    
    echo ""
    echo "iptables配置完成:"
    sudo iptables -L -n
}

# 测试远程访问
test_remote_access() {
    echo "🧪 测试远程访问..."
    
    # 获取公网IP
    PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
    PUBLIC_IPV6=$(curl -s -6 ifconfig.me 2>/dev/null || echo "")
    
    if [ -n "$PUBLIC_IPV4" ]; then
        echo "测试IPv4远程访问..."
        echo "  测试HTTP访问:"
        if curl -s --connect-timeout 10 http://$PUBLIC_IPV4 >/dev/null 2>&1; then
            echo -e "    ${GREEN}✅ IPv4 HTTP访问正常${NC}"
        else
            echo -e "    ${RED}❌ IPv4 HTTP访问失败${NC}"
        fi
        
        echo "  测试API访问:"
        if curl -s --connect-timeout 10 http://$PUBLIC_IPV4/api/v1/status >/dev/null 2>&1; then
            echo -e "    ${GREEN}✅ IPv4 API访问正常${NC}"
        else
            echo -e "    ${RED}❌ IPv4 API访问失败${NC}"
        fi
    fi
    
    if [ -n "$PUBLIC_IPV6" ]; then
        echo "测试IPv6远程访问..."
        echo "  测试HTTP访问:"
        if curl -6 -s --connect-timeout 10 http://[$PUBLIC_IPV6] >/dev/null 2>&1; then
            echo -e "    ${GREEN}✅ IPv6 HTTP访问正常${NC}"
        else
            echo -e "    ${RED}❌ IPv6 HTTP访问失败${NC}"
        fi
        
        echo "  测试API访问:"
        if curl -6 -s --connect-timeout 10 http://[$PUBLIC_IPV6]/api/v1/status >/dev/null 2>&1; then
            echo -e "    ${GREEN}✅ IPv6 API访问正常${NC}"
        else
            echo -e "    ${RED}❌ IPv6 API访问失败${NC}"
        fi
    fi
    echo ""
}

# 显示访问信息
show_access_info() {
    echo "🌐 远程访问信息..."
    echo "========================================"
    
    # 获取IP地址
    PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
    PUBLIC_IPV6=$(curl -s -6 ifconfig.me 2>/dev/null || echo "")
    LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    LOCAL_IPV6=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    
    echo "📱 本地访问:"
    echo "   前端: http://localhost"
    echo "   API:  http://localhost/api/v1/status"
    echo ""
    
    if [ -n "$LOCAL_IPV4" ] && [ "$LOCAL_IPV4" != "localhost" ]; then
        echo "🌐 内网IPv4访问:"
        echo "   前端: http://$LOCAL_IPV4"
        echo "   API:  http://$LOCAL_IPV4/api/v1/status"
        echo ""
    fi
    
    if [ -n "$LOCAL_IPV6" ]; then
        echo "🌐 内网IPv6访问:"
        echo "   前端: http://[$LOCAL_IPV6]"
        echo "   API:  http://[$LOCAL_IPV6]/api/v1/status"
        echo ""
    fi
    
    if [ -n "$PUBLIC_IPV4" ]; then
        echo "🌍 公网IPv4访问:"
        echo "   前端: http://$PUBLIC_IPV4"
        echo "   API:  http://$PUBLIC_IPV4/api/v1/status"
        echo ""
    fi
    
    if [ -n "$PUBLIC_IPV6" ]; then
        echo "🌍 公网IPv6访问:"
        echo "   前端: http://[$PUBLIC_IPV6]"
        echo "   API:  http://[$PUBLIC_IPV6]/api/v1/status"
        echo ""
    fi
    
    echo "🔑 默认登录信息:"
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo ""
    
    echo "🔧 管理命令:"
    echo "   查看状态: sudo systemctl status ipv6-wireguard-manager nginx"
    echo "   查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
    echo "   重启服务: sudo systemctl restart ipv6-wireguard-manager nginx"
    echo ""
}

# 主函数
main() {
    echo "🌐 IPv6 WireGuard Manager 远程访问配置"
    echo "========================================"
    echo ""
    
    # 检测网络配置
    get_ip_addresses
    
    # 检查端口状态
    check_port_status
    
    # 检测防火墙类型
    FIREWALL_TYPE=$(detect_firewall)
    echo "检测到防火墙类型: $FIREWALL_TYPE"
    echo ""
    
    # 配置防火墙
    case $FIREWALL_TYPE in
        "ufw")
            configure_ufw
            ;;
        "firewalld")
            configure_firewalld
            ;;
        "iptables")
            configure_iptables
            ;;
        "none")
            echo -e "${YELLOW}⚠️  未检测到防火墙，建议安装并配置防火墙${NC}"
            echo "推荐安装UFW: sudo apt install ufw"
            ;;
    esac
    
    echo ""
    
    # 测试远程访问
    test_remote_access
    
    # 显示访问信息
    show_access_info
    
    echo "========================================"
    echo -e "${GREEN}🎉 远程访问配置完成！${NC}"
    echo ""
    echo "📋 重要提醒:"
    echo "1. 确保您的云服务商安全组已开放相应端口"
    echo "2. 建议更改默认密码以提高安全性"
    echo "3. 考虑配置HTTPS以加密传输"
    echo "4. 定期更新系统和应用"
    echo ""
    echo "🆘 如果无法访问，请检查:"
    echo "1. 云服务商安全组设置"
    echo "2. 防火墙规则"
    echo "3. 服务运行状态"
    echo "4. 网络连接"
}

# 运行主函数
main "$@"
