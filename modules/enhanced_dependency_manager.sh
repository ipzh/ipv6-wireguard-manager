#!/bin/bash

# 增强的依赖管理器模块
# 提供完整的依赖项验证、安装和回滚机制

# 导入公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# =============================================================================
# 依赖项配置
# =============================================================================

# 必需工具列表
declare -A IPV6WGM_REQUIRED_TOOLS=(
    ["bash"]="4.0"
    ["grep"]="2.0"
    ["sed"]="4.0"
    ["awk"]="3.0"
    ["cut"]="2.0"
    ["sort"]="2.0"
    ["uniq"]="2.0"
    ["curl"]="7.0"
    ["wget"]="1.0"
)

# 可选工具列表
declare -A IPV6WGM_OPTIONAL_TOOLS=(
    ["yq"]="4.0"
    ["jq"]="1.6"
    ["ip"]="2.0"
    ["wg"]="1.0"
    ["bird"]="2.0"
    ["systemctl"]="1.0"
    ["docker"]="20.0"
)

# 系统包管理器配置
declare -A IPV6WGM_PACKAGE_MANAGERS=(
    ["apt"]="apt-get"
    ["yum"]="yum"
    ["dnf"]="dnf"
    ["pacman"]="pacman"
    ["zypper"]="zypper"
    ["apk"]="apk"
)

# 依赖项状态
declare -A IPV6WGM_DEPENDENCY_STATUS=()
declare -A IPV6WGM_INSTALLATION_LOG=()

# =============================================================================
# 依赖项检测函数
# =============================================================================

# 检测系统包管理器
detect_package_manager() {
    local package_manager=""
    
    if command -v apt-get &> /dev/null; then
        package_manager="apt"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v dnf &> /dev/null; then
        package_manager="dnf"
    elif command -v pacman &> /dev/null; then
        package_manager="pacman"
    elif command -v zypper &> /dev/null; then
        package_manager="zypper"
    elif command -v apk &> /dev/null; then
        package_manager="apk"
    fi
    
    echo "$package_manager"
}

# 检测工具版本
detect_tool_version() {
    local tool="$1"
    local version=""
    
    case "$tool" in
        "bash")
            version=$(bash --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
            ;;
        "grep")
            version=$(grep --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
            ;;
        "sed")
            version=$(sed --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
            ;;
        "awk")
            version=$(awk --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1 || echo "3.0")
            ;;
        "curl")
            version=$(curl --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
            ;;
        "wget")
            version=$(wget --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
            ;;
        "yq")
            version=$(yq --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -n1 || echo "")
            ;;
        "jq")
            version=$(jq --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -n1 || echo "")
            ;;
        "ip")
            version=$(ip --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -n1 || echo "")
            ;;
        "wg")
            version=$(wg --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -n1 || echo "")
            ;;
        "bird")
            version=$(bird --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -n1 || echo "")
            ;;
        "systemctl")
            version=$(systemctl --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1 || echo "")
            ;;
        "docker")
            version=$(docker --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -n1 || echo "")
            ;;
    esac
    
    echo "$version"
}

# 比较版本号
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    if [[ "$version1" == "$version2" ]]; then
        return 0
    fi
    
    local IFS='.'
    local -a v1=($version1)
    local -a v2=($version2)
    
    local max_len=${#v1[@]}
    if [[ ${#v2[@]} -gt $max_len ]]; then
        max_len=${#v2[@]}
    fi
    
    for ((i=0; i<max_len; i++)); do
        local num1=${v1[$i]:-0}
        local num2=${v2[$i]:-0}
        
        if [[ $num1 -gt $num2 ]]; then
            return 1
        elif [[ $num1 -lt $num2 ]]; then
            return 2
        fi
    done
    
    return 0
}

# 检查工具是否满足版本要求
check_tool_version() {
    local tool="$1"
    local required_version="$2"
    local current_version=""
    
    # 检查工具是否存在
    if ! command -v "$tool" &> /dev/null; then
        return 1
    fi
    
    # 获取当前版本
    current_version=$(detect_tool_version "$tool")
    if [[ -z "$current_version" ]]; then
        return 1
    fi
    
    # 比较版本
    compare_versions "$current_version" "$required_version"
    return $?
}

# =============================================================================
# 依赖项验证函数
# =============================================================================

# 验证必需工具
validate_required_tools() {
    local missing_tools=()
    local outdated_tools=()
    local valid_tools=()
    
    log_info "验证必需工具..."
    
    for tool in "${!IPV6WGM_REQUIRED_TOOLS[@]}"; do
        local required_version="${IPV6WGM_REQUIRED_TOOLS[$tool]}"
        
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
            IPV6WGM_DEPENDENCY_STATUS["$tool"]="missing"
            log_error "必需工具缺失: $tool (需要版本 $required_version+)"
        elif ! check_tool_version "$tool" "$required_version"; then
            local current_version=$(detect_tool_version "$tool")
            outdated_tools+=("$tool")
            IPV6WGM_DEPENDENCY_STATUS["$tool"]="outdated"
            log_warning "工具版本过低: $tool (当前: $current_version, 需要: $required_version+)"
        else
            local current_version=$(detect_tool_version "$tool")
            valid_tools+=("$tool")
            IPV6WGM_DEPENDENCY_STATUS["$tool"]="valid"
            log_success "工具版本满足要求: $tool $current_version"
        fi
    done
    
    # 输出验证结果
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "缺失的必需工具: ${missing_tools[*]}"
        return 1
    fi
    
    if [[ ${#outdated_tools[@]} -gt 0 ]]; then
        log_warning "版本过低的工具: ${outdated_tools[*]}"
    fi
    
    log_success "必需工具验证完成: ${#valid_tools[@]} 个工具满足要求"
    return 0
}

# 验证可选工具
validate_optional_tools() {
    local available_tools=()
    local missing_tools=()
    local outdated_tools=()
    
    log_info "验证可选工具..."
    
    for tool in "${!IPV6WGM_OPTIONAL_TOOLS[@]}"; do
        local required_version="${IPV6WGM_OPTIONAL_TOOLS[$tool]}"
        
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
            IPV6WGM_DEPENDENCY_STATUS["$tool"]="missing"
            log_warning "可选工具不可用: $tool"
        elif ! check_tool_version "$tool" "$required_version"; then
            local current_version=$(detect_tool_version "$tool")
            outdated_tools+=("$tool")
            IPV6WGM_DEPENDENCY_STATUS["$tool"]="outdated"
            log_warning "可选工具版本过低: $tool (当前: $current_version, 需要: $required_version+)"
        else
            local current_version=$(detect_tool_version "$tool")
            available_tools+=("$tool")
            IPV6WGM_DEPENDENCY_STATUS["$tool"]="valid"
            log_success "可选工具可用: $tool $current_version"
        fi
    done
    
    log_info "可选工具验证完成: ${#available_tools[@]} 个工具可用"
    return 0
}

# 验证系统依赖
validate_system_dependencies() {
    log_info "验证系统依赖..."
    
    # 检查操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        log_success "操作系统: $NAME $VERSION"
    else
        log_warning "无法检测操作系统信息"
    fi
    
    # 检查内核版本
    local kernel_version=$(uname -r)
    log_info "内核版本: $kernel_version"
    
    # 检查架构
    local arch=$(uname -m)
    log_info "系统架构: $arch"
    
    # 检查内存
    if [[ -f /proc/meminfo ]]; then
        local total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local total_mem_gb=$((total_mem / 1024 / 1024))
        log_info "总内存: ${total_mem_gb}GB"
        
        if [[ $total_mem_gb -lt 1 ]]; then
            log_warning "系统内存较少: ${total_mem_gb}GB (建议至少1GB)"
        fi
    fi
    
    # 检查磁盘空间
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local available_space_gb=$((available_space / 1024 / 1024))
    log_info "可用磁盘空间: ${available_space_gb}GB"
    
    if [[ $available_space_gb -lt 1 ]]; then
        log_warning "可用磁盘空间较少: ${available_space_gb}GB (建议至少1GB)"
    fi
    
    return 0
}

# =============================================================================
# 依赖项安装函数
# =============================================================================

# 安装工具
install_tool() {
    local tool="$1"
    local package_manager="$2"
    local package_name="$3"
    
    log_info "安装工具: $tool"
    
    case "$package_manager" in
        "apt")
            if ! sudo apt-get update; then
                log_error "包列表更新失败"
                return 1
            fi
            if ! sudo apt-get install -y "$package_name"; then
                log_error "工具安装失败: $tool"
                return 1
            fi
            ;;
        "yum"|"dnf")
            if ! sudo "$package_manager" install -y "$package_name"; then
                log_error "工具安装失败: $tool"
                return 1
            fi
            ;;
        "pacman")
            if ! sudo pacman -S --noconfirm "$package_name"; then
                log_error "工具安装失败: $tool"
                return 1
            fi
            ;;
        "zypper")
            if ! sudo zypper install -y "$package_name"; then
                log_error "工具安装失败: $tool"
                return 1
            fi
            ;;
        "apk")
            if ! sudo apk add "$package_name"; then
                log_error "工具安装失败: $tool"
                return 1
            fi
            ;;
        *)
            log_error "不支持的包管理器: $package_manager"
            return 1
            ;;
    esac
    
    # 记录安装日志
    IPV6WGM_INSTALLATION_LOG["$tool"]="$(date): 通过 $package_manager 安装 $package_name"
    log_success "工具安装成功: $tool"
    return 0
}

# 自动安装缺失的必需工具
auto_install_missing_tools() {
    local package_manager=$(detect_package_manager)
    
    if [[ -z "$package_manager" ]]; then
        log_error "无法检测包管理器"
        return 1
    fi
    
    log_info "使用包管理器: $package_manager"
    
    # 工具包名映射
    declare -A tool_packages=(
        ["bash"]="bash"
        ["grep"]="grep"
        ["sed"]="sed"
        ["awk"]="gawk"
        ["cut"]="coreutils"
        ["sort"]="coreutils"
        ["uniq"]="coreutils"
        ["curl"]="curl"
        ["wget"]="wget"
    )
    
    local installed_count=0
    local failed_count=0
    
    for tool in "${!IPV6WGM_REQUIRED_TOOLS[@]}"; do
        if [[ "${IPV6WGM_DEPENDENCY_STATUS[$tool]}" == "missing" ]]; then
            local package_name="${tool_packages[$tool]:-$tool}"
            
            if install_tool "$tool" "$package_manager" "$package_name"; then
                installed_count=$((installed_count + 1))
            else
                failed_count=$((failed_count + 1))
            fi
        fi
    done
    
    log_info "安装完成: $installed_count 个工具成功, $failed_count 个工具失败"
    
    if [[ $failed_count -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# =============================================================================
# 回滚机制
# =============================================================================

# 回滚安装的工具
rollback_installations() {
    local package_manager=$(detect_package_manager)
    
    if [[ -z "$package_manager" ]]; then
        log_error "无法检测包管理器，无法回滚"
        return 1
    fi
    
    log_info "开始回滚安装的工具..."
    
    local rolled_back_count=0
    
    for tool in "${!IPV6WGM_INSTALLATION_LOG[@]}"; do
        if [[ -n "${IPV6WGM_INSTALLATION_LOG[$tool]}" ]]; then
            log_info "回滚工具: $tool"
            
            case "$package_manager" in
                "apt")
                    if sudo apt-get remove -y "$tool"; then
                        rolled_back_count=$((rolled_back_count + 1))
                        log_success "工具回滚成功: $tool"
                    else
                        log_warning "工具回滚失败: $tool"
                    fi
                    ;;
                "yum"|"dnf")
                    if sudo "$package_manager" remove -y "$tool"; then
                        rolled_back_count=$((rolled_back_count + 1))
                        log_success "工具回滚成功: $tool"
                    else
                        log_warning "工具回滚失败: $tool"
                    fi
                    ;;
                "pacman")
                    if sudo pacman -R --noconfirm "$tool"; then
                        rolled_back_count=$((rolled_back_count + 1))
                        log_success "工具回滚成功: $tool"
                    else
                        log_warning "工具回滚失败: $tool"
                    fi
                    ;;
                "zypper")
                    if sudo zypper remove -y "$tool"; then
                        rolled_back_count=$((rolled_back_count + 1))
                        log_success "工具回滚成功: $tool"
                    else
                        log_warning "工具回滚失败: $tool"
                    fi
                    ;;
                "apk")
                    if sudo apk del "$tool"; then
                        rolled_back_count=$((rolled_back_count + 1))
                        log_success "工具回滚成功: $tool"
                    else
                        log_warning "工具回滚失败: $tool"
                    fi
                    ;;
            esac
        fi
    done
    
    log_info "回滚完成: $rolled_back_count 个工具已回滚"
    return 0
}

# =============================================================================
# 主验证函数
# =============================================================================

# 完整的依赖项验证
validate_all_dependencies() {
    local auto_install="${1:-false}"
    local rollback_on_failure="${2:-true}"
    
    log_info "开始依赖项验证..."
    
    # 验证系统依赖
    validate_system_dependencies
    
    # 验证必需工具
    if ! validate_required_tools; then
        if [[ "$auto_install" == "true" ]]; then
            log_info "尝试自动安装缺失的工具..."
            if auto_install_missing_tools; then
                log_info "重新验证必需工具..."
                if ! validate_required_tools; then
                    log_error "自动安装后验证仍然失败"
                    if [[ "$rollback_on_failure" == "true" ]]; then
                        rollback_installations
                    fi
                    return 1
                fi
            else
                log_error "自动安装失败"
                if [[ "$rollback_on_failure" == "true" ]]; then
                    rollback_installations
                fi
                return 1
            fi
        else
            log_error "必需工具验证失败，请手动安装缺失的工具"
            return 1
        fi
    fi
    
    # 验证可选工具
    validate_optional_tools
    
    log_success "所有依赖项验证完成"
    return 0
}

# 生成依赖项报告
generate_dependency_report() {
    local report_file="${1:-/tmp/ipv6wgm_dependency_report.txt}"
    
    log_info "生成依赖项报告: $report_file"
    
    cat > "$report_file" << EOF
IPv6 WireGuard Manager 依赖项报告
=====================================

生成时间: $(date)
系统信息: $(uname -s) $(uname -r) $(uname -m)

必需工具状态:
EOF
    
    for tool in "${!IPV6WGM_REQUIRED_TOOLS[@]}"; do
        local status="${IPV6WGM_DEPENDENCY_STATUS[$tool]:-unknown}"
        local version=$(detect_tool_version "$tool")
        echo "  $tool: $status (版本: ${version:-N/A})" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

可选工具状态:
EOF
    
    for tool in "${!IPV6WGM_OPTIONAL_TOOLS[@]}"; do
        local status="${IPV6WGM_DEPENDENCY_STATUS[$tool]:-unknown}"
        local version=$(detect_tool_version "$tool")
        echo "  $tool: $status (版本: ${version:-N/A})" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

安装日志:
EOF
    
    for tool in "${!IPV6WGM_INSTALLATION_LOG[@]}"; do
        echo "  $tool: ${IPV6WGM_INSTALLATION_LOG[$tool]}" >> "$report_file"
    done
    
    log_success "依赖项报告已生成: $report_file"
}

# =============================================================================
# 导出函数
# =============================================================================

export -f detect_package_manager
export -f detect_tool_version
export -f compare_versions
export -f check_tool_version
export -f validate_required_tools
export -f validate_optional_tools
export -f validate_system_dependencies
export -f install_tool
export -f auto_install_missing_tools
export -f rollback_installations
export -f validate_all_dependencies
export -f generate_dependency_report
