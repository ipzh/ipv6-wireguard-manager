#!/bin/bash

# IPv6 WireGuard Manager 部署脚本
# 支持多环境部署和自动化配置

# =============================================================================
# 配置和变量
# =============================================================================

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)" || exit

# 部署配置
DEPLOY_ENV="${DEPLOY_ENV:-production}"
DEPLOY_TARGET="${DEPLOY_TARGET:-local}"
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"
ROLLBACK_ENABLED="${ROLLBACK_ENABLED:-true}"

# 引入统一公共函数库（包含颜色与日志函数）
if [[ -f "${PROJECT_DIR}/modules/common_functions.sh" ]]; then
    # shellcheck source=modules/common_functions.sh
    source "${PROJECT_DIR}/modules/common_functions.sh"
fi

# =============================================================================
# 日志函数
# =============================================================================

# 统一日志函数已在 common_functions.sh 中定义

# =============================================================================
# 部署前检查
# =============================================================================

pre_deploy_checks() {
    log_info "执行部署前检查..."
    
    # 检查必要文件
    local required_files=(
        "ipv6-wireguard-manager.sh"
        "install.sh"
        "uninstall.sh"
        "modules/common_functions.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_DIR/$file" ]]; then
            log_error "必要文件不存在: $file"
            return 1
        fi
    done
    
    # 检查权限
    if [[ $EUID -ne 0 ]]; then
        log_warn "建议使用root权限运行部署脚本"
    fi
    
    # 检查系统兼容性
    if command -v check_system_compatibility &> /dev/null; then
        if ! check_system_compatibility; then
            log_error "系统兼容性检查失败"
            return 1
        fi
    fi
    
    log_success "部署前检查通过"
    return 0
}

# =============================================================================
# 备份当前版本
# =============================================================================

backup_current_version() {
    if [[ "$BACKUP_ENABLED" != "true" ]]; then
        log_info "跳过备份 (BACKUP_ENABLED=false)"
        return 0
    fi
    
    log_info "备份当前版本..."
    
    local backup_dir
    backup_dir="/opt/ipv6-wireguard-manager/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份配置文件
    if [[ -d "/etc/ipv6-wireguard-manager" ]]; then
        cp -r /etc/ipv6-wireguard-manager "$backup_dir/config"
    fi
    
    # 备份日志文件
    if [[ -d "/var/log/ipv6-wireguard-manager" ]]; then
        cp -r /var/log/ipv6-wireguard-manager "$backup_dir/logs"
    fi
    
    # 备份当前安装
    if [[ -d "/opt/ipv6-wireguard-manager" ]]; then
        cp -r /opt/ipv6-wireguard-manager "$backup_dir/installation"
    fi
    
    log_success "备份完成: $backup_dir"
    echo "$backup_dir"
}

# =============================================================================
# 部署到本地
# =============================================================================

deploy_local() {
    log_info "部署到本地环境..."
    
    # 创建安装目录
    mkdir -p /opt/ipv6-wireguard-manager
    mkdir -p /etc/ipv6-wireguard-manager
    mkdir -p /var/log/ipv6-wireguard-manager
    
    # 复制文件
    cp ipv6-wireguard-manager.sh /opt/ipv6-wireguard-manager/
    cp install.sh /opt/ipv6-wireguard-manager/
    cp uninstall.sh /opt/ipv6-wireguard-manager/
    cp -r modules /opt/ipv6-wireguard-manager/
    cp -r tests /opt/ipv6-wireguard-manager/
    cp -r docs /opt/ipv6-wireguard-manager/
    cp README.md /opt/ipv6-wireguard-manager/
    
    # 设置权限
    chmod +x /opt/ipv6-wireguard-manager/*.sh
    chmod +x /opt/ipv6-wireguard-manager/modules/*.sh
    chmod +x /opt/ipv6-wireguard-manager/tests/*.sh
    
    # 创建符号链接
    ln -sf /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh /usr/local/bin/ipv6-wireguard-manager
    
    log_success "本地部署完成"
}

# =============================================================================
# 部署到远程服务器
# =============================================================================

deploy_remote() {
    local server="$1"
    local user="${2:-root}"
    local port="${3:-22}"
    
    log_info "部署到远程服务器: $server"
    
    # 检查SSH连接
    if ! ssh -p "$port" -o ConnectTimeout=10 "$user@$server" "echo 'SSH连接成功'" &> /dev/null; then
        log_error "无法连接到远程服务器: $server"
        return 1
    fi
    
    # 创建远程目录
    ssh -p "$port" "$user@$server" "mkdir -p /opt/ipv6-wireguard-manager"
    
    # 同步文件
    rsync -avz -e "ssh -p $port" \
        --exclude='.git' \
        --exclude='*.log' \
        --exclude='*.tmp' \
        "$PROJECT_DIR/" "$user@$server:/opt/ipv6-wireguard-manager/"
    
    # 设置权限
    ssh -p "$port" "$user@$server" "
        chmod +x /opt/ipv6-wireguard-manager/*.sh
        chmod +x /opt/ipv6-wireguard-manager/modules/*.sh
        chmod +x /opt/ipv6-wireguard-manager/tests/*.sh
        ln -sf /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh /usr/local/bin/ipv6-wireguard-manager
    "
    
    log_success "远程部署完成: $server"
}

# =============================================================================
# 部署后验证
# =============================================================================

post_deploy_verification() {
    log_info "执行部署后验证..."
    
    # 检查文件是否存在
    local required_files=(
        "/opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh"
        "/opt/ipv6-wireguard-manager/install.sh"
        "/opt/ipv6-wireguard-manager/modules/common_functions.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "部署后验证失败: 文件不存在 $file"
            return 1
        fi
    done
    
    # 检查符号链接
    if [[ ! -L "/usr/local/bin/ipv6-wireguard-manager" ]]; then
        log_error "部署后验证失败: 符号链接不存在"
        return 1
    fi
    
    # 测试脚本执行
    if ! /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh --help &> /dev/null; then
        log_error "部署后验证失败: 脚本无法执行"
        return 1
    fi
    
    log_success "部署后验证通过"
    return 0
}

# =============================================================================
# 回滚功能
# =============================================================================

rollback_deployment() {
    local backup_dir="$1"
    
    if [[ "$ROLLBACK_ENABLED" != "true" ]]; then
        log_error "回滚功能已禁用"
        return 1
    fi
    
    if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        log_error "无效的备份目录: $backup_dir"
        return 1
    fi
    
    log_info "回滚到备份版本: $backup_dir"
    
    # 停止服务
    systemctl stop ipv6-wireguard-manager 2>/dev/null || true
    
    # 恢复文件
    if [[ -d "$backup_dir/installation" ]]; then
        rm -rf /opt/ipv6-wireguard-manager
        cp -r "$backup_dir/installation" /opt/ipv6-wireguard-manager
    fi
    
    if [[ -d "$backup_dir/config" ]]; then
        rm -rf /etc/ipv6-wireguard-manager
        cp -r "$backup_dir/config" /etc/ipv6-wireguard-manager
    fi
    
    if [[ -d "$backup_dir/logs" ]]; then
        rm -rf /var/log/ipv6-wireguard-manager
        cp -r "$backup_dir/logs" /var/log/ipv6-wireguard-manager
    fi
    
    # 重新创建符号链接
    ln -sf /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh /usr/local/bin/ipv6-wireguard-manager
    
    # 重启服务
    systemctl start ipv6-wireguard-manager 2>/dev/null || true
    
    log_success "回滚完成"
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    local action="${1:-deploy}"
    local target="${2:-local}"
    local backup_dir="$3"
    
    case "$action" in
        "deploy")
            if ! pre_deploy_checks; then
                exit 1
            fi
            
            local backup_path=""
            if [[ "$BACKUP_ENABLED" == "true" ]]; then
                backup_path=$(backup_current_version "$@")
            fi
            
            case "$target" in
                "local")
                    deploy_local
                    ;;
                "remote")
                    local server="$3"
                    local user="$4"
                    local port="$5"
                    deploy_remote "$server" "$user" "$port"
                    ;;
                *)
                    log_error "不支持的部署目标: $target"
                    exit 1
                    ;;
            esac
            
            if ! post_deploy_verification; then
                log_error "部署验证失败，开始回滚..."
                if [[ -n "$backup_path" ]]; then
                    rollback_deployment "$backup_path"
                fi
                exit 1
            fi
            
            log_success "部署完成"
            ;;
        "rollback")
            rollback_deployment "$backup_dir"
            ;;
        *)
            echo "用法: $0 [deploy|rollback] [local|remote] [参数...]"
            echo ""
            echo "示例:"
            echo "  $0 deploy local                    # 本地部署"
            echo "  $0 deploy remote server user port  # 远程部署"
            echo "  $0 rollback /path/to/backup        # 回滚部署"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
