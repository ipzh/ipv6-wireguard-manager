#!/bin/bash

# 修复WireGuard安装卡住问题

echo "=== 修复WireGuard安装卡住问题 ==="

# 引入统一公共函数库（包含颜色与日志函数）
if [[ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/modules/common_functions.sh" ]]; then
    # shellcheck source=modules/common_functions.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/modules/common_functions.sh"
fi

# 统一日志函数已在 common_functions.sh 中定义

# 检查当前状态
check_current_status() {
    log_info "检查当前WireGuard安装状态..."
    
    # 检查WireGuard包是否已安装
    if dpkg -l | grep -q wireguard; then
        log_info "WireGuard包已安装"
        dpkg -l | grep wireguard
    else
        log_warn "WireGuard包未完全安装"
    fi
    
    # 检查systemd服务状态
    if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
        log_info "WireGuard服务正在运行"
    else
        log_info "WireGuard服务未运行"
    fi
    
    # 检查网络接口
    if ip link show wg0 >/dev/null 2>&1; then
        log_info "WireGuard接口wg0已存在"
    else
        log_info "WireGuard接口wg0不存在"
    fi
}

# 修复WireGuard安装问题
fix_wireguard_install() {
    log_info "开始修复WireGuard安装问题..."
    
    # 1. 停止可能卡住的服务
    log_info "停止WireGuard相关服务..."
    systemctl stop wg-quick@wg0 2>/dev/null || true
    systemctl stop wg-quick.target 2>/dev/null || true
    
    # 2. 禁用自动启动（避免卡住）
    log_info "禁用WireGuard自动启动..."
    systemctl disable wg-quick@wg0 2>/dev/null || true
    systemctl disable wg-quick.target 2>/dev/null || true
    
    # 3. 重新加载systemd配置
    log_info "重新加载systemd配置..."
    systemctl daemon-reload
    
    # 4. 重置systemd状态
    log_info "重置systemd状态..."
    systemctl reset-failed wg-quick@wg0 2>/dev/null || true
    systemctl reset-failed wg-quick.target 2>/dev/null || true
    
    # 5. 清理可能的问题配置
    log_info "清理可能的问题配置..."
    rm -f /etc/wireguard/wg0.conf 2>/dev/null || true
    
    # 6. 重新配置WireGuard
    log_info "重新配置WireGuard..."
    dpkg --configure -a
    
    # 7. 验证安装
    log_info "验证WireGuard安装..."
    if command -v wg >/dev/null 2>&1; then
        log_success "WireGuard工具已安装"
        wg --version
    else
        log_error "WireGuard工具未安装"
    fi
    
    if command -v wg-quick >/dev/null 2>&1; then
        log_success "wg-quick工具已安装"
    else
        log_error "wg-quick工具未安装"
    fi
}

# 创建安全的WireGuard配置
create_safe_wireguard_config() {
    log_info "创建安全的WireGuard配置..."
    
    # 创建配置目录
    mkdir -p /etc/wireguard
    
    # 创建基本配置（不自动启动）
    cat > /etc/wireguard/wg0.conf << 'EOF'
# WireGuard配置示例
# 注意：此配置仅用于测试，不会自动启动

[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.0.0.1/24
ListenPort = 51820

# 客户端配置示例
# [Peer]
# PublicKey = CLIENT_PUBLIC_KEY_HERE
# AllowedIPs = 10.0.0.2/32
EOF
    
    log_info "WireGuard配置文件已创建: /etc/wireguard/wg0.conf"
    log_warn "请手动编辑配置文件并添加正确的密钥"
}

# 提供使用指导
provide_usage_guidance() {
    log_info "提供WireGuard使用指导..."
    
    echo
    echo -e "${GREEN}WireGuard安装修复完成！${NC}"
    echo
    echo -e "${YELLOW}使用指导：${NC}"
    echo "1. 生成密钥对："
    echo "   wg genkey | tee privatekey | wg pubkey > publickey"
    echo
    echo "2. 编辑配置文件："
    echo "   nano /etc/wireguard/wg0.conf"
    echo
    echo "3. 启动WireGuard："
    echo "   wg-quick up wg0"
    echo
    echo "4. 停止WireGuard："
    echo "   wg-quick down wg0"
    echo
    echo "5. 查看状态："
    echo "   wg show"
    echo
    echo -e "${YELLOW}注意：${NC}"
    echo "- WireGuard不会自动启动，需要手动启动"
    echo "- 请确保配置文件中的密钥是正确的"
    echo "- 建议在生产环境中使用更复杂的配置"
}

# 主函数
main() {
    log_info "开始修复WireGuard安装卡住问题..."
    
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        log_error "需要root权限来修复WireGuard安装"
        log_info "请使用: sudo $0"
        exit 1
    fi
    
    # 检查当前状态
    check_current_status
    
    # 修复安装问题
    fix_wireguard_install
    
    # 创建安全配置
    create_safe_wireguard_config
    
    # 提供使用指导
    provide_usage_guidance
    
    log_success "WireGuard安装修复完成！"
}

# 执行主函数
main "$@"
