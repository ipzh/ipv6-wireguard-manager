#!/bin/bash

# IPv6 WireGuard Manager 版本控制模块
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

# 版本信息
VERSION="1.0.0"
BUILD_DATE="$(date '+%Y-%m-%d')"
GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"

# 兼容性配置
MIN_BASH_VERSION="4.0"
MIN_SYSTEM_MEMORY="512"  # MB
MIN_DISK_SPACE="1024"    # MB
SUPPORTED_OS=("ubuntu" "debian" "centos" "rhel" "rocky" "almalinux" "fedora" "arch" "opensuse")

# 版本检查
check_version_compatibility() {
    log_info "检查版本兼容性..."
    
    local compatibility_issues=0
    
    # 检查Bash版本
    if ! check_bash_version; then
        ((compatibility_issues++))
    fi
    
    # 检查系统内存
    if ! check_system_memory; then
        ((compatibility_issues++))
    fi
    
    # 检查磁盘空间
    if ! check_disk_space; then
        ((compatibility_issues++))
    fi
    
    # 检查操作系统
    if ! check_operating_system; then
        ((compatibility_issues++))
    fi
    
    if [[ $compatibility_issues -eq 0 ]]; then
        log_success "版本兼容性检查通过"
        return 0
    else
        log_error "发现 $compatibility_issues 个兼容性问题"
        return 1
    fi
}

# 检查Bash版本
check_bash_version() {
    local current_version=$(bash --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
    local required_version="$MIN_BASH_VERSION"
    
    if [[ $(echo "$current_version >= $required_version" | bc -l 2>/dev/null || echo "1") == "1" ]]; then
        log_success "Bash版本兼容: $current_version >= $required_version"
        return 0
    else
        log_error "Bash版本过低: $current_version < $required_version"
        return 1
    fi
}

# 检查系统内存
check_system_memory() {
    local total_mem=$(free -m | awk 'NR==2{print $2}')
    local required_mem="$MIN_SYSTEM_MEMORY"
    
    if [[ $total_mem -ge $required_mem ]]; then
        log_success "内存充足: ${total_mem}MB >= ${required_mem}MB"
        return 0
    else
        log_error "内存不足: ${total_mem}MB < ${required_mem}MB"
        return 1
    fi
}

# 检查磁盘空间
check_disk_space() {
    local available_space=$(df / | tail -1 | awk '{print $4}')
    local required_space="$MIN_DISK_SPACE"
    
    if [[ $available_space -ge $required_space ]]; then
        log_success "磁盘空间充足: ${available_space}MB >= ${required_space}MB"
        return 0
    else
        log_error "磁盘空间不足: ${available_space}MB < ${required_space}MB"
        return 1
    fi
}

# 检查操作系统
check_operating_system() {
    local os_id=""
    
    if [[ -f /etc/os-release ]]; then
        os_id=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    else
        log_error "无法检测操作系统"
        return 1
    fi
    
    for supported_os in "${SUPPORTED_OS[@]}"; do
        if [[ "$os_id" == "$supported_os" ]]; then
            log_success "操作系统支持: $os_id"
            return 0
        fi
    done
    
    log_warn "操作系统可能不支持: $os_id"
    log_info "支持的操作系统: ${SUPPORTED_OS[*]}"
    return 1
}

# 获取版本信息
get_version_info() {
    cat << EOF
IPv6 WireGuard Manager 版本信息
================================
版本号: $VERSION
构建日期: $BUILD_DATE
Git提交: $GIT_COMMIT
Git分支: $GIT_BRANCH
作者: IPv6 WireGuard Manager Team
许可证: MIT
项目地址: https://github.com/ipzh/ipv6-wireguard-manager
EOF
}

# 检查更新
check_for_updates() {
    log_info "检查更新..."
    
    local update_url="https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases/latest"
    local latest_version=""
    local download_url=""
    
    if command -v curl &> /dev/null; then
        local response=$(curl -s "$update_url" 2>/dev/null)
        if [[ -n "$response" ]]; then
            latest_version=$(echo "$response" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
            download_url=$(echo "$response" | grep -o '"tarball_url": "[^"]*"' | cut -d'"' -f4)
        fi
    elif command -v wget &> /dev/null; then
        local response=$(wget -qO- "$update_url" 2>/dev/null)
        if [[ -n "$response" ]]; then
            latest_version=$(echo "$response" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
            download_url=$(echo "$response" | grep -o '"tarball_url": "[^"]*"' | cut -d'"' -f4)
        fi
    else
        log_error "需要curl或wget来检查更新"
        return 1
    fi
    
    if [[ -z "$latest_version" ]]; then
        log_warn "无法获取最新版本信息"
        return 1
    fi
    
    # 比较版本
    if [[ "$latest_version" != "v$VERSION" ]]; then
        log_info "发现新版本: $latest_version"
        log_info "当前版本: v$VERSION"
        log_info "下载地址: $download_url"
        
        if confirm "是否下载并安装新版本？"; then
            download_and_install_update "$download_url" "$latest_version"
        fi
    else
        log_success "已是最新版本: $VERSION"
    fi
}

# 下载并安装更新
download_and_install_update() {
    local download_url="$1"
    local version="$2"
    local temp_dir="/tmp/ipv6-wireguard-manager-update"
    
    log_info "下载更新: $version"
    
    # 创建临时目录
    execute_command "mkdir -p '$temp_dir'" "创建临时更新目录" "true"
    cd "$temp_dir"
    
    # 下载更新包
    if command -v curl &> /dev/null; then
        execute_command "curl -L -o update.tar.gz '$download_url'" "下载更新包" "true"
    elif command -v wget &> /dev/null; then
        execute_command "wget -O update.tar.gz '$download_url'" "下载更新包" "true"
    else
        log_error "需要curl或wget来下载更新"
        return 1
    fi
    
    # 解压更新包
    execute_command "tar -xzf update.tar.gz" "解压更新包" "true"
    
    # 查找解压后的目录
    local extracted_dir=$(find . -maxdepth 1 -type d -name "ipv6-wireguard-manager-*" | head -1)
    if [[ -n "$extracted_dir" ]]; then
        cd "$extracted_dir"
        
        # 运行更新安装
        if [[ -f "install.sh" ]]; then
            execute_command "chmod +x install.sh" "设置安装脚本权限" "true"
            execute_command "./install.sh --update" "运行更新安装" "true"
            log_success "更新安装完成"
        else
            log_error "更新包中未找到安装脚本"
            return 1
        fi
    else
        log_error "无法找到解压后的目录"
        return 1
    fi
    
    # 清理临时文件
    execute_command "rm -rf '$temp_dir'" "清理临时文件" "true"
}

# 版本回滚
rollback_version() {
    local target_version="$1"
    
    if [[ -z "$target_version" ]]; then
        log_error "请指定要回滚的版本"
        return 1
    fi
    
    log_info "回滚到版本: $target_version"
    
    # 检查版本是否存在
    local rollback_url="https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases/tags/$target_version"
    local download_url=""
    
    if command -v curl &> /dev/null; then
        local response=$(curl -s "$rollback_url" 2>/dev/null)
        if [[ -n "$response" ]]; then
            download_url=$(echo "$response" | grep -o '"tarball_url": "[^"]*"' | cut -d'"' -f4)
        fi
    fi
    
    if [[ -z "$download_url" ]]; then
        log_error "无法获取版本 $target_version 的下载地址"
        return 1
    fi
    
    if confirm "确定要回滚到版本 $target_version 吗？这将覆盖当前安装。"; then
        download_and_install_update "$download_url" "$target_version"
    fi
}

# 显示版本历史
show_version_history() {
    log_info "版本历史..."
    
    local history_url="https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases"
    
    if command -v curl &> /dev/null; then
        local response=$(curl -s "$history_url" 2>/dev/null)
        if [[ -n "$response" ]]; then
            echo "$response" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4 | head -10
        fi
    else
        log_warn "需要curl来获取版本历史"
    fi
}

# 导出版本控制函数
export -f check_version_compatibility get_version_info check_for_updates
export -f download_and_install_update rollback_version show_version_history
