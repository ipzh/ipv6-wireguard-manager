#!/bin/bash

# IPv6 WireGuard Manager 更新脚本
# 用于更新管理器到最新版本

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
PROJECT_ROOT="$SCRIPT_DIR"

# 导入公共函数
if [[ -f "$PROJECT_ROOT/modules/common_functions.sh" ]]; then
    source "$PROJECT_ROOT/modules/common_functions.sh"
else
    echo "错误: 无法找到公共函数模块" >&2
    exit 1
fi

# 导入版本控制模块
if [[ -f "$PROJECT_ROOT/modules/version_control.sh" ]]; then
    source "$PROJECT_ROOT/modules/version_control.sh"
else
    echo "错误: 无法找到版本控制模块" >&2
    exit 1
fi

# 更新配置
UPDATE_BACKUP_DIR="/tmp/ipv6wgm_update_backup_$(date +%s)"
UPDATE_TEMP_DIR="/tmp/ipv6wgm_update_temp_$(date +%s)"

# 显示更新信息
show_update_info() {
    echo "IPv6 WireGuard Manager 更新工具"
    echo "================================="
    echo "当前版本: $(get_current_version)"
    echo "项目目录: $PROJECT_ROOT"
    echo
}

# 检查更新
check_for_updates() {
    log_info "检查更新..."
    
    local latest_version
    latest_version=$(get_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        log_error "无法获取最新版本信息"
        return 1
    fi
    
    local current_version
    current_version=$(get_current_version)
    
    log_info "当前版本: $current_version"
    log_info "最新版本: $latest_version"
    
    if [[ "$current_version" == "$latest_version" ]]; then
        log_success "已是最新版本"
        return 0
    else
        log_info "发现新版本: $latest_version"
        return 1
    fi
}

# 备份当前版本
backup_current_version() {
    log_info "备份当前版本..."
    
    mkdir -p "$UPDATE_BACKUP_DIR"
    
    # 备份配置文件
    if [[ -d "$PROJECT_ROOT/config" ]]; then
        cp -r "$PROJECT_ROOT/config" "$UPDATE_BACKUP_DIR/"
        log_info "配置文件已备份"
    fi
    
    # 备份日志文件
    if [[ -d "$PROJECT_ROOT/logs" ]]; then
        cp -r "$PROJECT_ROOT/logs" "$UPDATE_BACKUP_DIR/"
        log_info "日志文件已备份"
    fi
    
    # 备份客户端配置
    if [[ -d "$PROJECT_ROOT/clients" ]]; then
        cp -r "$PROJECT_ROOT/clients" "$UPDATE_BACKUP_DIR/"
        log_info "客户端配置已备份"
    fi
    
    log_success "备份完成: $UPDATE_BACKUP_DIR"
}

# 下载最新版本
download_latest_version() {
    log_info "下载最新版本..."
    
    mkdir -p "$UPDATE_TEMP_DIR"
    cd "$UPDATE_TEMP_DIR" || exit
    
    local download_url
    download_url=$(get_download_url)
    
    if [[ -z "$download_url" ]]; then
        log_error "无法获取下载链接"
        return 1
    fi
    
    log_info "下载地址: $download_url"
    
    if command -v curl &> /dev/null; then
        if curl -L -o "latest.tar.gz" "$download_url"; then
            log_success "下载完成"
        else
            log_error "下载失败"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if wget -O "latest.tar.gz" "$download_url"; then
            log_success "下载完成"
        else
            log_error "下载失败"
            return 1
        fi
    else
        log_error "需要curl或wget来下载更新"
        return 1
    fi
    
    # 解压文件
    if tar -xzf "latest.tar.gz"; then
        log_success "解压完成"
    else
        log_error "解压失败"
        return 1
    fi
}

# 安装更新
install_update() {
    log_info "安装更新..."
    
    local extracted_dir
    extracted_dir=$(find "$UPDATE_TEMP_DIR" -maxdepth 1 -type d -name "ipv6-wireguard-manager*" | head -1)
    
    if [[ -z "$extracted_dir" ]]; then
        log_error "无法找到解压目录"
        return 1
    fi
    
    # 停止服务
    log_info "停止服务..."
    if [[ -f "$PROJECT_ROOT/ipv6-wireguard-manager.sh" ]]; then
        bash "$PROJECT_ROOT/ipv6-wireguard-manager.sh" stop 2>/dev/null || true
    fi
    
    # 备份当前文件
    backup_current_version
    
    # 复制新文件
    log_info "复制新文件..."
    cp -r "$extracted_dir"/* "$PROJECT_ROOT/"
    
    # 恢复配置文件
    if [[ -d "$UPDATE_BACKUP_DIR/config" ]]; then
        cp -r "$UPDATE_BACKUP_DIR/config"/* "$PROJECT_ROOT/config/" 2>/dev/null || true
        log_info "配置文件已恢复"
    fi
    
    # 恢复客户端配置
    if [[ -d "$UPDATE_BACKUP_DIR/clients" ]]; then
        cp -r "$UPDATE_BACKUP_DIR/clients"/* "$PROJECT_ROOT/clients/" 2>/dev/null || true
        log_info "客户端配置已恢复"
    fi
    
    # 设置执行权限
    find "$PROJECT_ROOT" -name "*.sh" -exec chmod +x {} \;
    
    log_success "更新安装完成"
}

# 清理临时文件
cleanup() {
    log_info "清理临时文件..."
    
    if [[ -d "$UPDATE_TEMP_DIR" ]]; then
        rm -rf "$UPDATE_TEMP_DIR"
        log_info "临时文件已清理"
    fi
    
    if [[ -d "$UPDATE_BACKUP_DIR" ]]; then
        log_info "备份文件保留在: $UPDATE_BACKUP_DIR"
    fi
}

# 验证更新
verify_update() {
    log_info "验证更新..."
    
    # 检查主要文件
    local required_files=(
        "ipv6-wireguard-manager.sh"
        "modules/common_functions.sh"
        "modules/version_control.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "文件存在: $file"
        else
            log_error "文件缺失: $file"
            return 1
        fi
    done
    
    # 测试脚本执行
    if bash "$PROJECT_ROOT/ipv6-wireguard-manager.sh" --version; then
        log_success "脚本执行正常"
    else
        log_error "脚本执行失败"
        return 1
    fi
    
    log_success "更新验证通过"
}

# 主更新函数
update_manager() {
    log_info "开始更新IPv6 WireGuard Manager..."
    
    # 检查更新
    if check_for_updates; then
        log_info "无需更新"
        return 0
    fi
    
    # 确认更新
    echo
    read -rp "是否继续更新? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "更新已取消"
        return 0
    fi
    
    # 执行更新
    if download_latest_version && install_update && verify_update; then
        log_success "更新完成!"
        log_info "新版本: $(get_current_version)"
        
        # 启动服务
        log_info "启动服务..."
        bash "$PROJECT_ROOT/ipv6-wireguard-manager.sh" start 2>/dev/null || true
        
    else
        log_error "更新失败"
        
        # 恢复备份
        if [[ -d "$UPDATE_BACKUP_DIR" ]]; then
            log_info "尝试恢复备份..."
            # 这里可以添加恢复逻辑
        fi
        
        return 1
    fi
    
    # 清理
    cleanup
}

# 主函数
main() {
    show_update_info
    
    case "${1:-update}" in
        "check")
            check_for_updates
            ;;
        "update")
            update_manager
            ;;
        "backup")
            backup_current_version
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            echo "用法: $0 [check|update|backup|cleanup]"
            echo "  check   - 检查更新"
            echo "  update  - 执行更新"
            echo "  backup  - 备份当前版本"
            echo "  cleanup - 清理临时文件"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"

