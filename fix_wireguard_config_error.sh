#!/bin/bash

# WireGuard配置错误修复脚本
# 用于修复 "Servname not supported for ai_socktype" 错误

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $message"
}

# 检查WireGuard配置文件
check_wireguard_config() {
    local config_file="/etc/wireguard/wg0.conf"
    
    if [[ ! -f "$config_file" ]]; then
        log "ERROR" "WireGuard配置文件不存在: $config_file"
        return 1
    fi
    
    log "INFO" "检查WireGuard配置文件: $config_file"
    
    # 检查配置文件内容
    while IFS= read -r line; do
        # 跳过空行和注释
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 检查ListenPort行
        if [[ "$line" =~ ^ListenPort[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            local port="${BASH_REMATCH[1]}"
            log "INFO" "找到ListenPort配置: $port"
            
            # 验证端口号
            if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
                log "ERROR" "无效的端口号: $port"
                log "ERROR" "端口号必须是1-65535之间的数字"
                return 1
            else
                log "INFO" "端口号验证通过: $port"
            fi
        fi
        
        # 检查是否有中文字符
        if [[ "$line" =~ [一-龯] ]]; then
            log "ERROR" "配置文件中发现中文字符: $line"
            return 1
        fi
    done < "$config_file"
    
    log "INFO" "WireGuard配置文件检查完成"
    return 0
}

# 修复WireGuard配置
fix_wireguard_config() {
    local config_file="/etc/wireguard/wg0.conf"
    local backup_file="/etc/wireguard/wg0.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    log "INFO" "开始修复WireGuard配置"
    
    # 备份原配置文件
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "$backup_file"
        log "INFO" "已备份原配置文件到: $backup_file"
    fi
    
    # 生成新的配置文件
    local default_port="51820"
    local port=""
    
    echo -e "${CYAN}WireGuard端口配置修复${NC}"
    echo "当前默认端口: $default_port"
    read -p "请输入WireGuard端口 (默认: $default_port): " input_port
    
    if [[ -z "$input_port" ]]; then
        port="$default_port"
    else
        # 清理输入，移除任何非数字字符
        input_port=$(echo "$input_port" | tr -d '[:alpha:][:punct:][:space:]')
        
        if [[ "$input_port" =~ ^[0-9]+$ ]] && [[ "$input_port" -ge 1 ]] && [[ "$input_port" -le 65535 ]]; then
            port="$input_port"
        else
            log "ERROR" "输入的内容: '$input_port' 不是有效的端口号"
            log "ERROR" "使用默认端口: $default_port"
            port="$default_port"
        fi
    fi
    
    log "INFO" "使用端口: $port"
    
    # 生成服务器密钥
    local server_private_key=$(wg genkey)
    local server_public_key=$(echo "$server_private_key" | wg pubkey)
    
    # 创建新的配置文件
    cat > "$config_file" << EOF
[Interface]
PrivateKey = $server_private_key
Address = 10.0.0.1/24, 2001:db8::1/64
ListenPort = $port
SaveConfig = true

# 启用IPv6转发
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
    
    # 设置权限
    chmod 600 "$config_file"
    
    log "INFO" "WireGuard配置文件已修复: $config_file"
    log "INFO" "服务器公钥: $server_public_key"
}

# 重启WireGuard服务
restart_wireguard_service() {
    log "INFO" "重启WireGuard服务"
    
    # 停止服务
    systemctl stop wg-quick@wg0.service 2>/dev/null || true
    
    # 等待一下
    sleep 2
    
    # 启动服务
    if systemctl start wg-quick@wg0.service; then
        log "INFO" "WireGuard服务启动成功"
        
        # 检查服务状态
        if systemctl is-active --quiet wg-quick@wg0.service; then
            log "INFO" "WireGuard服务运行正常"
        else
            log "WARN" "WireGuard服务状态异常"
        fi
    else
        log "ERROR" "WireGuard服务启动失败"
        return 1
    fi
}

# 主函数
main() {
    echo -e "${CYAN}WireGuard配置错误修复工具${NC}"
    echo "=================================="
    
    # 检查是否以root权限运行
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "此脚本需要root权限运行"
        log "INFO" "请使用: sudo $0"
        exit 1
    fi
    
    # 检查WireGuard是否安装
    if ! command -v wg >/dev/null 2>&1; then
        log "ERROR" "WireGuard未安装"
        log "INFO" "请先安装WireGuard: apt install wireguard"
        exit 1
    fi
    
    # 检查配置文件
    if check_wireguard_config; then
        log "INFO" "WireGuard配置文件正常"
    else
        log "WARN" "WireGuard配置文件存在问题，开始修复"
        fix_wireguard_config
    fi
    
    # 重启服务
    restart_wireguard_service
    
    echo -e "${GREEN}修复完成！${NC}"
    echo "=================================="
    echo "WireGuard服务状态:"
    systemctl status wg-quick@wg0.service --no-pager -l
}

# 运行主函数
main "$@"
