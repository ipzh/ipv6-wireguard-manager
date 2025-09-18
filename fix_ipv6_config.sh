#!/bin/bash

# IPv6 配置检查和修复脚本
# 版本: 1.0.5
# 用于检查和修复 IPv6 相关配置问题

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [WARN] $message${NC}"
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [INFO] $message${NC}"
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] [DEBUG] $message${NC}"
            ;;
        *)
            echo -e "[$timestamp] [$level] $message"
            ;;
    esac
}

# 显示标题
show_title() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                IPv6 配置检查和修复工具                ║${NC}"
    echo -e "${WHITE}║                        版本 1.0.5                        ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# 检查系统要求
check_system_requirements() {
    log "INFO" "检查系统要求..."
    
    # 检查是否为 root 用户
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "此脚本需要 root 权限运行"
        log "INFO" "请使用: sudo $0"
        exit 1
    fi
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log "INFO" "操作系统: $PRETTY_NAME"
    else
        log "WARN" "无法确定操作系统版本"
    fi
    
    # 检查内核版本
    local kernel_version=$(uname -r)
    log "INFO" "内核版本: $kernel_version"
    
    # 检查 IPv6 支持
    if [[ -f /proc/net/if_inet6 ]]; then
        log "INFO" "系统支持 IPv6"
    else
        log "WARN" "系统可能不支持 IPv6"
    fi
}

# 检查 IPv6 基本配置
check_ipv6_basic_config() {
    log "INFO" "检查 IPv6 基本配置..."
    
    echo -e "${CYAN}=== IPv6 基本配置检查 ===${NC}"
    
    # 检查 IPv6 是否启用
    if [[ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]]; then
        local ipv6_disabled=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
        if [[ "$ipv6_disabled" == "1" ]]; then
            log "ERROR" "IPv6 已禁用"
            return 1
        else
            log "INFO" "IPv6 已启用"
        fi
    else
        log "WARN" "无法检查 IPv6 状态"
    fi
    
    # 检查 IPv6 转发
    if [[ -f /proc/sys/net/ipv6/conf/all/forwarding ]]; then
        local ipv6_forwarding=$(cat /proc/sys/net/ipv6/conf/all/forwarding)
        if [[ "$ipv6_forwarding" == "1" ]]; then
            log "INFO" "IPv6 转发已启用"
        else
            log "WARN" "IPv6 转发未启用"
        fi
    else
        log "WARN" "无法检查 IPv6 转发状态"
    fi
    
    # 检查默认接口的 IPv6 转发
    if [[ -f /proc/sys/net/ipv6/conf/default/forwarding ]]; then
        local default_forwarding=$(cat /proc/sys/net/ipv6/conf/default/forwarding)
        if [[ "$default_forwarding" == "1" ]]; then
            log "INFO" "默认接口 IPv6 转发已启用"
        else
            log "WARN" "默认接口 IPv6 转发未启用"
        fi
    fi
    
    echo
}

# 检查 IPv6 地址配置
check_ipv6_addresses() {
    log "INFO" "检查 IPv6 地址配置..."
    
    echo -e "${CYAN}=== IPv6 地址配置检查 ===${NC}"
    
    # 显示所有 IPv6 地址
    echo -e "${YELLOW}系统 IPv6 地址:${NC}"
    ip -6 addr show 2>/dev/null || log "WARN" "无法显示 IPv6 地址"
    
    # 检查是否有全局 IPv6 地址
    local global_addrs=$(ip -6 addr show | grep "scope global" | wc -l)
    if [[ "$global_addrs" -gt 0 ]]; then
        log "INFO" "发现 $global_addrs 个全局 IPv6 地址"
    else
        log "WARN" "未发现全局 IPv6 地址"
    fi
    
    # 检查是否有链路本地地址
    local link_local_addrs=$(ip -6 addr show | grep "scope link" | wc -l)
    if [[ "$link_local_addrs" -gt 0 ]]; then
        log "INFO" "发现 $link_local_addrs 个链路本地 IPv6 地址"
    else
        log "WARN" "未发现链路本地 IPv6 地址"
    fi
    
    echo
}

# 检查 IPv6 路由配置
check_ipv6_routing() {
    log "INFO" "检查 IPv6 路由配置..."
    
    echo -e "${CYAN}=== IPv6 路由配置检查 ===${NC}"
    
    # 显示 IPv6 路由表
    echo -e "${YELLOW}IPv6 路由表:${NC}"
    ip -6 route show 2>/dev/null || log "WARN" "无法显示 IPv6 路由"
    
    # 检查默认路由
    local default_route=$(ip -6 route show | grep "default" | wc -l)
    if [[ "$default_route" -gt 0 ]]; then
        log "INFO" "发现 $default_route 个默认 IPv6 路由"
    else
        log "WARN" "未发现默认 IPv6 路由"
    fi
    
    echo
}

# 检查 IPv6 防火墙配置
check_ipv6_firewall() {
    log "INFO" "检查 IPv6 防火墙配置..."
    
    echo -e "${CYAN}=== IPv6 防火墙配置检查 ===${NC}"
    
    # 检查 ip6tables
    if command -v ip6tables >/dev/null 2>&1; then
        log "INFO" "ip6tables 已安装"
        
        # 显示 IPv6 规则
        echo -e "${YELLOW}IPv6 防火墙规则:${NC}"
        ip6tables -L -n -v 2>/dev/null || log "WARN" "无法显示 IPv6 防火墙规则"
    else
        log "WARN" "ip6tables 未安装"
    fi
    
    # 检查 UFW IPv6 支持
    if command -v ufw >/dev/null 2>&1; then
        local ufw_status=$(ufw status | grep "IPv6" || echo "IPv6 not configured")
        log "INFO" "UFW IPv6 状态: $ufw_status"
    fi
    
    # 检查 Firewalld IPv6 支持
    if command -v firewall-cmd >/dev/null 2>&1; then
        local firewalld_ipv6=$(firewall-cmd --get-ipset-types | grep -i ipv6 || echo "No IPv6 support")
        log "INFO" "Firewalld IPv6 支持: $firewalld_ipv6"
    fi
    
    echo
}

# 检查 WireGuard IPv6 配置
check_wireguard_ipv6_config() {
    log "INFO" "检查 WireGuard IPv6 配置..."
    
    echo -e "${CYAN}=== WireGuard IPv6 配置检查 ===${NC}"
    
    local config_file="/etc/wireguard/wg0.conf"
    
    if [[ -f "$config_file" ]]; then
        log "INFO" "WireGuard 配置文件存在: $config_file"
        
        # 检查配置文件中的 IPv6 地址
        local ipv6_addresses=$(grep -E "Address.*:" "$config_file" | grep -oE "[0-9a-fA-F:]+/[0-9]+" | grep ":" | wc -l)
        if [[ "$ipv6_addresses" -gt 0 ]]; then
            log "INFO" "发现 $ipv6_addresses 个 IPv6 地址配置"
            grep -E "Address.*:" "$config_file" | grep ":" || true
        else
            log "WARN" "未发现 IPv6 地址配置"
        fi
        
        # 检查 IPv6 转发配置
        if grep -q "ipv6.*forwarding" "$config_file"; then
            log "INFO" "发现 IPv6 转发配置"
        else
            log "WARN" "未发现 IPv6 转发配置"
        fi
        
        # 检查 ip6tables 规则
        if grep -q "ip6tables" "$config_file"; then
            log "INFO" "发现 ip6tables 规则配置"
        else
            log "WARN" "未发现 ip6tables 规则配置"
        fi
    else
        log "WARN" "WireGuard 配置文件不存在: $config_file"
    fi
    
    echo
}

# 修复 IPv6 基本配置
fix_ipv6_basic_config() {
    log "INFO" "修复 IPv6 基本配置..."
    
    echo -e "${CYAN}=== 修复 IPv6 基本配置 ===${NC}"
    
    # 启用 IPv6
    if [[ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]]; then
        echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
        log "INFO" "已启用 IPv6"
    fi
    
    # 启用 IPv6 转发
    if [[ -f /proc/sys/net/ipv6/conf/all/forwarding ]]; then
        echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
        log "INFO" "已启用 IPv6 转发"
    fi
    
    # 启用默认接口 IPv6 转发
    if [[ -f /proc/sys/net/ipv6/conf/default/forwarding ]]; then
        echo 1 > /proc/sys/net/ipv6/conf/default/forwarding
        log "INFO" "已启用默认接口 IPv6 转发"
    fi
    
    # 创建持久化配置
    cat > /etc/sysctl.d/99-ipv6-wireguard.conf << EOF
# IPv6 WireGuard 配置
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1

# 启用 IPv6 自动配置
net.ipv6.conf.all.autoconf = 1
net.ipv6.conf.all.accept_ra = 1
net.ipv6.conf.default.autoconf = 1
net.ipv6.conf.default.accept_ra = 1

# 启用 IPv6 邻居发现
net.ipv6.conf.all.accept_redirects = 1
net.ipv6.conf.default.accept_redirects = 1
EOF
    
    log "INFO" "已创建持久化 IPv6 配置: /etc/sysctl.d/99-ipv6-wireguard.conf"
    
    # 应用配置
    sysctl -p /etc/sysctl.d/99-ipv6-wireguard.conf
    
    echo
}

# 修复 IPv6 防火墙配置
fix_ipv6_firewall() {
    log "INFO" "修复 IPv6 防火墙配置..."
    
    echo -e "${CYAN}=== 修复 IPv6 防火墙配置 ===${NC}"
    
    # 修复 ip6tables 规则
    if command -v ip6tables >/dev/null 2>&1; then
        # 基本 IPv6 规则
        ip6tables -P INPUT ACCEPT
        ip6tables -P FORWARD ACCEPT
        ip6tables -P OUTPUT ACCEPT
        
        # 允许回环接口
        ip6tables -A INPUT -i lo -j ACCEPT
        ip6tables -A OUTPUT -o lo -j ACCEPT
        
        # 允许已建立的连接
        ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
        
        # 允许 WireGuard
        ip6tables -A INPUT -p udp --dport 51820 -j ACCEPT
        
        # 允许 ICMPv6
        ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
        
        # WireGuard 转发规则
        ip6tables -A FORWARD -i wg0 -j ACCEPT
        ip6tables -A FORWARD -o wg0 -j ACCEPT
        
        log "INFO" "已配置基本 IPv6 防火墙规则"
    fi
    
    # 修复 UFW IPv6 支持
    if command -v ufw >/dev/null 2>&1; then
        # 启用 IPv6
        ufw --force enable
        ufw allow 51820/udp
        ufw allow ssh
        ufw reload
        log "INFO" "已配置 UFW IPv6 支持"
    fi
    
    # 修复 Firewalld IPv6 支持
    if command -v firewall-cmd >/dev/null 2>&1; then
        systemctl enable firewalld
        systemctl start firewalld
        firewall-cmd --permanent --add-port=51820/udp
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --reload
        log "INFO" "已配置 Firewalld IPv6 支持"
    fi
    
    echo
}

# 修复 WireGuard IPv6 配置
fix_wireguard_ipv6_config() {
    log "INFO" "修复 WireGuard IPv6 配置..."
    
    echo -e "${CYAN}=== 修复 WireGuard IPv6 配置 ===${NC}"
    
    local config_file="/etc/wireguard/wg0.conf"
    
    if [[ -f "$config_file" ]]; then
        # 备份原配置
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log "INFO" "已备份原配置文件"
        
        # 检查并添加 IPv6 转发配置
        if ! grep -q "ipv6.*forwarding" "$config_file"; then
            # 在 PostUp 部分添加 IPv6 转发
            sed -i '/PostUp.*iptables/a PostUp = echo 1 > /proc/sys/net/ipv6/conf/all/forwarding\nPostUp = echo 1 > /proc/sys/net/ipv6/conf/%i/forwarding' "$config_file"
            sed -i '/PostDown.*iptables/a PostDown = echo 0 > /proc/sys/net/ipv6/conf/all/forwarding\nPostDown = echo 0 > /proc/sys/net/ipv6/conf/%i/forwarding' "$config_file"
            log "INFO" "已添加 IPv6 转发配置"
        fi
        
        # 检查并添加 ip6tables 规则
        if ! grep -q "ip6tables" "$config_file"; then
            # 在 PostUp 部分添加 ip6tables 规则
            sed -i '/PostUp.*iptables/a PostUp = ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT' "$config_file"
            sed -i '/PostDown.*iptables/a PostDown = ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT' "$config_file"
            log "INFO" "已添加 ip6tables 规则"
        fi
        
        # 检查并添加 SaveConfig
        if ! grep -q "SaveConfig" "$config_file"; then
            sed -i '/ListenPort/a SaveConfig = true' "$config_file"
            log "INFO" "已添加 SaveConfig 选项"
        fi
        
        log "INFO" "WireGuard IPv6 配置已修复"
    else
        log "WARN" "WireGuard 配置文件不存在，跳过修复"
    fi
    
    echo
}

# 测试 IPv6 连接
test_ipv6_connectivity() {
    log "INFO" "测试 IPv6 连接..."
    
    echo -e "${CYAN}=== IPv6 连接测试 ===${NC}"
    
    # 测试本地 IPv6 连接
    if ping6 -c 3 ::1 >/dev/null 2>&1; then
        log "INFO" "本地 IPv6 连接正常"
    else
        log "WARN" "本地 IPv6 连接失败"
    fi
    
    # 测试外部 IPv6 连接
    if ping6 -c 3 2001:4860:4860::8888 >/dev/null 2>&1; then
        log "INFO" "外部 IPv6 连接正常"
    else
        log "WARN" "外部 IPv6 连接失败"
    fi
    
    # 测试 IPv6 DNS 解析
    if nslookup ipv6.google.com >/dev/null 2>&1; then
        log "INFO" "IPv6 DNS 解析正常"
    else
        log "WARN" "IPv6 DNS 解析失败"
    fi
    
    echo
}

# 显示修复总结
show_fix_summary() {
    echo -e "${CYAN}=== 修复总结 ===${NC}"
    
    echo -e "${GREEN}✓${NC} 已检查 IPv6 基本配置"
    echo -e "${GREEN}✓${NC} 已检查 IPv6 地址配置"
    echo -e "${GREEN}✓${NC} 已检查 IPv6 路由配置"
    echo -e "${GREEN}✓${NC} 已检查 IPv6 防火墙配置"
    echo -e "${GREEN}✓${NC} 已检查 WireGuard IPv6 配置"
    echo -e "${GREEN}✓${NC} 已修复 IPv6 基本配置"
    echo -e "${GREEN}✓${NC} 已修复 IPv6 防火墙配置"
    echo -e "${GREEN}✓${NC} 已修复 WireGuard IPv6 配置"
    echo -e "${GREEN}✓${NC} 已测试 IPv6 连接"
    
    echo
    echo -e "${WHITE}IPv6 配置修复完成！${NC}"
    echo -e "${CYAN}建议重启系统以确保所有配置生效:${NC}"
    echo -e "  ${YELLOW}sudo reboot${NC}"
}

# 主函数
main() {
    show_title
    
    # 检查系统要求
    check_system_requirements
    
    # 检查配置
    check_ipv6_basic_config
    check_ipv6_addresses
    check_ipv6_routing
    check_ipv6_firewall
    check_wireguard_ipv6_config
    
    # 修复配置
    fix_ipv6_basic_config
    fix_ipv6_firewall
    fix_wireguard_ipv6_config
    
    # 测试连接
    test_ipv6_connectivity
    
    # 显示总结
    show_fix_summary
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
