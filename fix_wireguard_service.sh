#!/bin/bash

# WireGuard 服务诊断和修复脚本
# 版本: 1.0.5
# 用于诊断和修复 WireGuard 服务启动失败问题

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
    echo -e "${WHITE}║              WireGuard 服务诊断和修复工具                ║${NC}"
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
    
    # 检查 WireGuard 模块
    if lsmod | grep -q wireguard; then
        log "INFO" "WireGuard 内核模块已加载"
    else
        log "WARN" "WireGuard 内核模块未加载"
    fi
}

# 诊断 WireGuard 服务状态
diagnose_wireguard_service() {
    log "INFO" "诊断 WireGuard 服务状态..."
    
    echo -e "${CYAN}=== WireGuard 服务状态诊断 ===${NC}"
    
    # 检查服务状态
    if systemctl is-active --quiet wg-quick@wg0; then
        log "INFO" "WireGuard 服务正在运行"
        systemctl status wg-quick@wg0 --no-pager -l
    else
        log "ERROR" "WireGuard 服务未运行"
        
        # 显示详细错误信息
        echo -e "${YELLOW}详细错误信息:${NC}"
        systemctl status wg-quick@wg0 --no-pager -l || true
        
        echo -e "${YELLOW}系统日志:${NC}"
        journalctl -xeu wg-quick@wg0.service --no-pager -l | tail -20 || true
    fi
    
    echo
}

# 检查 WireGuard 配置
check_wireguard_config() {
    log "INFO" "检查 WireGuard 配置..."
    
    echo -e "${CYAN}=== WireGuard 配置检查 ===${NC}"
    
    local config_file="/etc/wireguard/wg0.conf"
    
    if [[ -f "$config_file" ]]; then
        log "INFO" "配置文件存在: $config_file"
        
        # 检查文件权限
        local file_perms=$(stat -c "%a" "$config_file")
        local file_owner=$(stat -c "%U:%G" "$config_file")
        log "INFO" "文件权限: $file_perms, 所有者: $file_owner"
        
        if [[ "$file_perms" != "600" ]]; then
            log "WARN" "配置文件权限不正确，应该是 600"
        fi
        
        if [[ "$file_owner" != "root:root" ]]; then
            log "WARN" "配置文件所有者不正确，应该是 root:root"
        fi
        
        # 检查配置文件语法
        echo -e "${YELLOW}配置文件内容:${NC}"
        cat "$config_file"
        echo
        
        # 使用 wg-quick strip 检查语法
        if wg-quick strip wg0 >/dev/null 2>&1; then
            log "INFO" "配置文件语法正确"
        else
            log "ERROR" "配置文件语法错误"
            echo -e "${YELLOW}语法检查结果:${NC}"
            wg-quick strip wg0 2>&1 || true
        fi
    else
        log "ERROR" "配置文件不存在: $config_file"
    fi
    
    echo
}

# 检查网络接口
check_network_interfaces() {
    log "INFO" "检查网络接口..."
    
    echo -e "${CYAN}=== 网络接口检查 ===${NC}"
    
    # 检查 wg0 接口
    if ip link show wg0 >/dev/null 2>&1; then
        log "INFO" "wg0 接口存在"
        ip link show wg0
    else
        log "WARN" "wg0 接口不存在"
    fi
    
    # 检查所有网络接口
    echo -e "${YELLOW}所有网络接口:${NC}"
    ip link show
    
    echo
}

# 检查端口占用
check_port_usage() {
    log "INFO" "检查端口占用..."
    
    echo -e "${CYAN}=== 端口占用检查 ===${NC}"
    
    local wg_port="51820"
    
    # 检查 WireGuard 端口
    if netstat -tulpn 2>/dev/null | grep -q ":$wg_port "; then
        log "WARN" "端口 $wg_port 已被占用"
        netstat -tulpn | grep ":$wg_port "
    else
        log "INFO" "端口 $wg_port 可用"
    fi
    
    echo
}

# 检查 IPv6 配置
check_ipv6_config() {
    log "INFO" "检查 IPv6 配置..."
    
    echo -e "${CYAN}=== IPv6 配置检查 ===${NC}"
    
    # 检查 IPv6 是否启用
    if [[ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]]; then
        local ipv6_disabled=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
        if [[ "$ipv6_disabled" == "1" ]]; then
            log "ERROR" "IPv6 已禁用"
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
    
    # 检查 IPv6 地址
    echo -e "${YELLOW}IPv6 地址:${NC}"
    ip -6 addr show 2>/dev/null || log "WARN" "无法显示 IPv6 地址"
    
    echo
}

# 检查防火墙配置
check_firewall_config() {
    log "INFO" "检查防火墙配置..."
    
    echo -e "${CYAN}=== 防火墙配置检查 ===${NC}"
    
    # 检查 UFW
    if command -v ufw >/dev/null 2>&1; then
        log "INFO" "检测到 UFW 防火墙"
        ufw status verbose
    fi
    
    # 检查 Firewalld
    if command -v firewall-cmd >/dev/null 2>&1; then
        log "INFO" "检测到 Firewalld 防火墙"
        firewall-cmd --list-all
    fi
    
    # 检查 iptables
    if command -v iptables >/dev/null 2>&1; then
        log "INFO" "检测到 iptables"
        echo -e "${YELLOW}IPv4 规则:${NC}"
        iptables -L -n -v
        echo -e "${YELLOW}IPv6 规则:${NC}"
        ip6tables -L -n -v 2>/dev/null || log "WARN" "无法显示 IPv6 规则"
    fi
    
    echo
}

# 修复 WireGuard 配置
fix_wireguard_config() {
    log "INFO" "修复 WireGuard 配置..."
    
    echo -e "${CYAN}=== 修复 WireGuard 配置 ===${NC}"
    
    local config_file="/etc/wireguard/wg0.conf"
    
    # 停止服务
    systemctl stop wg-quick@wg0 2>/dev/null || true
    
    # 修复文件权限
    if [[ -f "$config_file" ]]; then
        chmod 600 "$config_file"
        chown root:root "$config_file"
        log "INFO" "已修复配置文件权限"
    fi
    
    # 重新生成配置（如果需要）
    if [[ ! -f "$config_file" ]] || ! wg-quick strip wg0 >/dev/null 2>&1; then
        log "INFO" "重新生成 WireGuard 配置..."
        
        # 生成新的密钥
        local server_private_key=$(wg genkey)
        local server_public_key=$(echo "$server_private_key" | wg pubkey)
        
        # 创建基本配置
        cat > "$config_file" << EOF
[Interface]
PrivateKey = $server_private_key
Address = 10.0.0.1/24, 2001:db8::1/64
ListenPort = 51820
SaveConfig = true

# 启用 IPv6 转发
PostUp = echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
PostUp = echo 1 > /proc/sys/net/ipv6/conf/%i/forwarding
PostDown = echo 0 > /proc/sys/net/ipv6/conf/all/forwarding
PostDown = echo 0 > /proc/sys/net/ipv6/conf/%i/forwarding

# 防火墙规则
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT
PostUp = ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT
PostDown = ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT

# 客户端配置将在这里添加
EOF
        
        chmod 600 "$config_file"
        chown root:root "$config_file"
        
        log "INFO" "已重新生成 WireGuard 配置"
        log "INFO" "服务器公钥: $server_public_key"
    fi
    
    echo
}

# 修复 IPv6 配置
fix_ipv6_config() {
    log "INFO" "修复 IPv6 配置..."
    
    echo -e "${CYAN}=== 修复 IPv6 配置 ===${NC}"
    
    # 启用 IPv6
    echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    log "INFO" "已启用 IPv6"
    
    # 启用 IPv6 转发
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
    log "INFO" "已启用 IPv6 转发"
    
    # 加载 WireGuard 模块
    modprobe wireguard 2>/dev/null || log "WARN" "无法加载 WireGuard 模块"
    
    # 设置持久化配置
    cat > /etc/sysctl.d/99-wireguard-ipv6.conf << EOF
# WireGuard IPv6 配置
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
EOF
    
    log "INFO" "已创建持久化 IPv6 配置"
    
    echo
}

# 修复防火墙配置
fix_firewall_config() {
    log "INFO" "修复防火墙配置..."
    
    echo -e "${CYAN}=== 修复防火墙配置 ===${NC}"
    
    # 修复 UFW
    if command -v ufw >/dev/null 2>&1; then
        ufw --force enable
        ufw allow 51820/udp
        ufw allow ssh
        ufw reload
        log "INFO" "已配置 UFW 防火墙"
    fi
    
    # 修复 Firewalld
    if command -v firewall-cmd >/dev/null 2>&1; then
        systemctl enable firewalld
        systemctl start firewalld
        firewall-cmd --permanent --add-port=51820/udp
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --reload
        log "INFO" "已配置 Firewalld 防火墙"
    fi
    
    # 修复 iptables
    if command -v iptables >/dev/null 2>&1; then
        # 基本 IPv4 规则
        iptables -A INPUT -p udp --dport 51820 -j ACCEPT
        iptables -A FORWARD -i wg0 -j ACCEPT
        iptables -A FORWARD -o wg0 -j ACCEPT
        
        # 基本 IPv6 规则
        ip6tables -A INPUT -p udp --dport 51820 -j ACCEPT 2>/dev/null || true
        ip6tables -A FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
        ip6tables -A FORWARD -o wg0 -j ACCEPT 2>/dev/null || true
        
        log "INFO" "已配置 iptables 规则"
    fi
    
    echo
}

# 启动 WireGuard 服务
start_wireguard_service() {
    log "INFO" "启动 WireGuard 服务..."
    
    echo -e "${CYAN}=== 启动 WireGuard 服务 ===${NC}"
    
    # 启用服务
    systemctl enable wg-quick@wg0
    
    # 启动服务
    if systemctl start wg-quick@wg0; then
        log "INFO" "WireGuard 服务启动成功"
        
        # 检查状态
        systemctl status wg-quick@wg0 --no-pager -l
        
        # 显示接口信息
        echo -e "${YELLOW}WireGuard 接口信息:${NC}"
        wg show
    else
        log "ERROR" "WireGuard 服务启动失败"
        
        # 显示错误信息
        systemctl status wg-quick@wg0 --no-pager -l
        journalctl -xeu wg-quick@wg0.service --no-pager -l | tail -10
        
        return 1
    fi
    
    echo
}

# 显示修复总结
show_fix_summary() {
    echo -e "${CYAN}=== 修复总结 ===${NC}"
    
    echo -e "${GREEN}✓${NC} 已检查系统要求"
    echo -e "${GREEN}✓${NC} 已诊断 WireGuard 服务状态"
    echo -e "${GREEN}✓${NC} 已检查 WireGuard 配置"
    echo -e "${GREEN}✓${NC} 已检查网络接口"
    echo -e "${GREEN}✓${NC} 已检查端口占用"
    echo -e "${GREEN}✓${NC} 已检查 IPv6 配置"
    echo -e "${GREEN}✓${NC} 已检查防火墙配置"
    echo -e "${GREEN}✓${NC} 已修复 WireGuard 配置"
    echo -e "${GREEN}✓${NC} 已修复 IPv6 配置"
    echo -e "${GREEN}✓${NC} 已修复防火墙配置"
    echo -e "${GREEN}✓${NC} 已启动 WireGuard 服务"
    
    echo
    echo -e "${WHITE}WireGuard 服务修复完成！${NC}"
    echo -e "${CYAN}如果仍有问题，请检查系统日志:${NC}"
    echo -e "  ${YELLOW}journalctl -xeu wg-quick@wg0.service${NC}"
    echo -e "  ${YELLOW}systemctl status wg-quick@wg0.service${NC}"
}

# 主函数
main() {
    show_title
    
    # 检查系统要求
    check_system_requirements
    
    # 诊断问题
    diagnose_wireguard_service
    check_wireguard_config
    check_network_interfaces
    check_port_usage
    check_ipv6_config
    check_firewall_config
    
    # 修复问题
    fix_wireguard_config
    fix_ipv6_config
    fix_firewall_config
    
    # 启动服务
    if start_wireguard_service; then
        show_fix_summary
    else
        log "ERROR" "修复失败，请手动检查问题"
        exit 1
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
