#!/bin/bash

# 硬件架构兼容性检查模块
# 提供硬件架构检测、兼容性验证和性能优化建议功能

# =============================================================================
# 硬件兼容性配置
# =============================================================================

# 硬件信息存储
declare -g IPV6WGM_CPU_ARCH=""
declare -g IPV6WGM_CPU_CORES=0
declare -g IPV6WGM_CPU_FREQUENCY=0
declare -g IPV6WGM_TOTAL_MEMORY=0
declare -g IPV6WGM_AVAILABLE_MEMORY=0
declare -g IPV6WGM_DISK_SPACE=0
declare -g IPV6WGM_NETWORK_INTERFACES=0

# 兼容性设置
declare -g IPV6WGM_HARDWARE_CHECK_ENABLED=true
declare -g IPV6WGM_PERFORMANCE_MONITORING=true
declare -g IPV6WGM_COMPATIBILITY_WARNINGS=true

# 硬件要求
declare -A IPV6WGM_MINIMUM_REQUIREMENTS=(
    ["cpu_cores"]="1"
    ["memory_gb"]="1"
    ["disk_gb"]="5"
    ["network_interfaces"]="1"
)

declare -A IPV6WGM_RECOMMENDED_REQUIREMENTS=(
    ["cpu_cores"]="2"
    ["memory_gb"]="2"
    ["disk_gb"]="10"
    ["network_interfaces"]="2"
)

# 兼容性结果
declare -A IPV6WGM_HARDWARE_COMPATIBILITY=()
declare -g IPV6WGM_COMPATIBILITY_PASSED=0
declare -g IPV6WGM_COMPATIBILITY_FAILED=0
declare -g IPV6WGM_COMPATIBILITY_WARNINGS_COUNT=0

# =============================================================================
# 硬件兼容性函数
# =============================================================================

# 初始化硬件兼容性检查
init_hardware_compatibility() {
    log_info "初始化硬件兼容性检查系统..."
    
    # 检测硬件信息
    detect_hardware_info
    
    # 检查硬件兼容性
    check_hardware_compatibility
    
    # 生成兼容性报告
    generate_compatibility_report
    
    log_success "硬件兼容性检查系统初始化完成"
    return 0
}

# 检测硬件信息
detect_hardware_info() {
    log_info "检测硬件信息..."
    
    # 检测CPU架构
    detect_cpu_architecture
    
    # 检测CPU核心数
    detect_cpu_cores
    
    # 检测内存信息
    detect_memory_info
    
    # 检测磁盘空间
    detect_disk_space
    
    # 检测网络接口
    detect_network_interfaces
    
    log_debug "硬件信息检测完成"
}

# 检测CPU架构
detect_cpu_architecture() {
    if command -v uname >/dev/null 2>&1; then
        IPV6WGM_CPU_ARCH=$(uname -m 2>/dev/null || echo "unknown")
    elif command -v arch >/dev/null 2>&1; then
        IPV6WGM_CPU_ARCH=$(arch 2>/dev/null || echo "unknown")
    else
        IPV6WGM_CPU_ARCH="unknown"
    fi
    
    log_debug "CPU架构: $IPV6WGM_CPU_ARCH"
}

# 检测CPU核心数
detect_cpu_cores() {
    if [[ -f /proc/cpuinfo ]]; then
        # Linux系统
        IPV6WGM_CPU_CORES=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "0")
    elif command -v nproc >/dev/null 2>&1; then
        # 使用nproc命令
        IPV6WGM_CPU_CORES=$(nproc 2>/dev/null || echo "0")
    elif command -v sysctl >/dev/null 2>&1; then
        # macOS系统
        IPV6WGM_CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "0")
    else
        IPV6WGM_CPU_CORES=1
    fi
    
    log_debug "CPU核心数: $IPV6WGM_CPU_CORES"
}

# 检测内存信息
detect_memory_info() {
    if [[ -f /proc/meminfo ]]; then
        # Linux系统
        local mem_total=$(grep "^MemTotal:" /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
        local mem_available=$(grep "^MemAvailable:" /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
        
        IPV6WGM_TOTAL_MEMORY=$((mem_total / 1024))  # 转换为MB
        IPV6WGM_AVAILABLE_MEMORY=$((mem_available / 1024))  # 转换为MB
    elif command -v free >/dev/null 2>&1; then
        # 使用free命令
        local mem_info=$(free -m 2>/dev/null | grep "^Mem:" || echo "Mem: 0 0 0 0 0 0")
        IPV6WGM_TOTAL_MEMORY=$(echo "$mem_info" | awk '{print $2}')
        IPV6WGM_AVAILABLE_MEMORY=$(echo "$mem_info" | awk '{print $7}')
    elif command -v vm_stat >/dev/null 2>&1; then
        # macOS系统
        local page_size=$(vm_stat 2>/dev/null | grep "page size" | awk '{print $8}' | tr -d '.')
        local mem_free=$(vm_stat 2>/dev/null | grep "Pages free" | awk '{print $3}' | tr -d '.')
        local mem_inactive=$(vm_stat 2>/dev/null | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
        
        IPV6WGM_TOTAL_MEMORY=$(( (mem_free + mem_inactive) * page_size / 1024 / 1024 ))
        IPV6WGM_AVAILABLE_MEMORY=$((mem_free * page_size / 1024 / 1024))
    else
        IPV6WGM_TOTAL_MEMORY=1024
        IPV6WGM_AVAILABLE_MEMORY=512
    fi
    
    log_debug "总内存: ${IPV6WGM_TOTAL_MEMORY}MB"
    log_debug "可用内存: ${IPV6WGM_AVAILABLE_MEMORY}MB"
}

# 检测磁盘空间
detect_disk_space() {
    if command -v df >/dev/null 2>&1; then
        # 使用df命令检测根分区空间
        local disk_info=$(df -m / 2>/dev/null | tail -1 || echo "0 0 0 0 0 /")
        IPV6WGM_DISK_SPACE=$(echo "$disk_info" | awk '{print $4}')  # 可用空间MB
    else
        IPV6WGM_DISK_SPACE=0
    fi
    
    log_debug "可用磁盘空间: ${IPV6WGM_DISK_SPACE}MB"
}

# 检测网络接口
detect_network_interfaces() {
    if command -v ip >/dev/null 2>&1; then
        # 使用ip命令
        IPV6WGM_NETWORK_INTERFACES=$(ip link show 2>/dev/null | grep -c "^[0-9]" || echo "0")
    elif command -v ifconfig >/dev/null 2>&1; then
        # 使用ifconfig命令
        IPV6WGM_NETWORK_INTERFACES=$(ifconfig -a 2>/dev/null | grep -c "^[a-zA-Z]" || echo "0")
    else
        IPV6WGM_NETWORK_INTERFACES=1
    fi
    
    log_debug "网络接口数: $IPV6WGM_NETWORK_INTERFACES"
}

# 检查硬件兼容性
check_hardware_compatibility() {
    log_info "检查硬件兼容性..."
    
    IPV6WGM_COMPATIBILITY_PASSED=0
    IPV6WGM_COMPATIBILITY_FAILED=0
    IPV6WGM_COMPATIBILITY_WARNINGS_COUNT=0
    
    # 检查CPU核心数
    check_cpu_compatibility
    
    # 检查内存
    check_memory_compatibility
    
    # 检查磁盘空间
    check_disk_compatibility
    
    # 检查网络接口
    check_network_compatibility
    
    # 检查架构兼容性
    check_architecture_compatibility
    
    log_info "硬件兼容性检查完成"
}

# 检查CPU兼容性
check_cpu_compatibility() {
    local min_cores="${IPV6WGM_MINIMUM_REQUIREMENTS[cpu_cores]}"
    local rec_cores="${IPV6WGM_RECOMMENDED_REQUIREMENTS[cpu_cores]}"
    
    if [[ $IPV6WGM_CPU_CORES -ge $min_cores ]]; then
        IPV6WGM_HARDWARE_COMPATIBILITY["cpu"]="PASS"
        ((IPV6WGM_COMPATIBILITY_PASSED++))
        log_success "✓ CPU核心数满足最低要求 ($IPV6WGM_CPU_CORES >= $min_cores)"
        
        if [[ $IPV6WGM_CPU_CORES -ge $rec_cores ]]; then
            log_info "✓ CPU核心数满足推荐要求 ($IPV6WGM_CPU_CORES >= $rec_cores)"
        else
            log_warn "! CPU核心数低于推荐要求 ($IPV6WGM_CPU_CORES < $rec_cores)"
            ((IPV6WGM_COMPATIBILITY_WARNINGS_COUNT++))
        fi
    else
        IPV6WGM_HARDWARE_COMPATIBILITY["cpu"]="FAIL"
        ((IPV6WGM_COMPATIBILITY_FAILED++))
        log_error "✗ CPU核心数不满足最低要求 ($IPV6WGM_CPU_CORES < $min_cores)"
    fi
}

# 检查内存兼容性
check_memory_compatibility() {
    local min_memory="${IPV6WGM_MINIMUM_REQUIREMENTS[memory_gb]}"
    local rec_memory="${IPV6WGM_RECOMMENDED_REQUIREMENTS[memory_gb]}"
    local memory_gb=$((IPV6WGM_TOTAL_MEMORY / 1024))
    
    if [[ $memory_gb -ge $min_memory ]]; then
        IPV6WGM_HARDWARE_COMPATIBILITY["memory"]="PASS"
        ((IPV6WGM_COMPATIBILITY_PASSED++))
        log_success "✓ 内存满足最低要求 (${memory_gb}GB >= ${min_memory}GB)"
        
        if [[ $memory_gb -ge $rec_memory ]]; then
            log_info "✓ 内存满足推荐要求 (${memory_gb}GB >= ${rec_memory}GB)"
        else
            log_warn "! 内存低于推荐要求 (${memory_gb}GB < ${rec_memory}GB)"
            ((IPV6WGM_COMPATIBILITY_WARNINGS_COUNT++))
        fi
    else
        IPV6WGM_HARDWARE_COMPATIBILITY["memory"]="FAIL"
        ((IPV6WGM_COMPATIBILITY_FAILED++))
        log_error "✗ 内存不满足最低要求 (${memory_gb}GB < ${min_memory}GB)"
    fi
}

# 检查磁盘兼容性
check_disk_compatibility() {
    local min_disk="${IPV6WGM_MINIMUM_REQUIREMENTS[disk_gb]}"
    local rec_disk="${IPV6WGM_RECOMMENDED_REQUIREMENTS[disk_gb]}"
    local disk_gb=$((IPV6WGM_DISK_SPACE / 1024))
    
    if [[ $disk_gb -ge $min_disk ]]; then
        IPV6WGM_HARDWARE_COMPATIBILITY["disk"]="PASS"
        ((IPV6WGM_COMPATIBILITY_PASSED++))
        log_success "✓ 磁盘空间满足最低要求 (${disk_gb}GB >= ${min_disk}GB)"
        
        if [[ $disk_gb -ge $rec_disk ]]; then
            log_info "✓ 磁盘空间满足推荐要求 (${disk_gb}GB >= ${rec_disk}GB)"
        else
            log_warn "! 磁盘空间低于推荐要求 (${disk_gb}GB < ${rec_disk}GB)"
            ((IPV6WGM_COMPATIBILITY_WARNINGS_COUNT++))
        fi
    else
        IPV6WGM_HARDWARE_COMPATIBILITY["disk"]="FAIL"
        ((IPV6WGM_COMPATIBILITY_FAILED++))
        log_error "✗ 磁盘空间不满足最低要求 (${disk_gb}GB < ${min_disk}GB)"
    fi
}

# 检查网络兼容性
check_network_compatibility() {
    local min_interfaces="${IPV6WGM_MINIMUM_REQUIREMENTS[network_interfaces]}"
    local rec_interfaces="${IPV6WGM_RECOMMENDED_REQUIREMENTS[network_interfaces]}"
    
    if [[ $IPV6WGM_NETWORK_INTERFACES -ge $min_interfaces ]]; then
        IPV6WGM_HARDWARE_COMPATIBILITY["network"]="PASS"
        ((IPV6WGM_COMPATIBILITY_PASSED++))
        log_success "✓ 网络接口满足最低要求 ($IPV6WGM_NETWORK_INTERFACES >= $min_interfaces)"
        
        if [[ $IPV6WGM_NETWORK_INTERFACES -ge $rec_interfaces ]]; then
            log_info "✓ 网络接口满足推荐要求 ($IPV6WGM_NETWORK_INTERFACES >= $rec_interfaces)"
        else
            log_warn "! 网络接口低于推荐要求 ($IPV6WGM_NETWORK_INTERFACES < $rec_interfaces)"
            ((IPV6WGM_COMPATIBILITY_WARNINGS_COUNT++))
        fi
    else
        IPV6WGM_HARDWARE_COMPATIBILITY["network"]="FAIL"
        ((IPV6WGM_COMPATIBILITY_FAILED++))
        log_error "✗ 网络接口不满足最低要求 ($IPV6WGM_NETWORK_INTERFACES < $min_interfaces)"
    fi
}

# 检查架构兼容性
check_architecture_compatibility() {
    case "$IPV6WGM_CPU_ARCH" in
        "x86_64"|"amd64")
            IPV6WGM_HARDWARE_COMPATIBILITY["architecture"]="PASS"
            ((IPV6WGM_COMPATIBILITY_PASSED++))
            log_success "✓ CPU架构兼容 (x86_64)"
            ;;
        "aarch64"|"arm64")
            IPV6WGM_HARDWARE_COMPATIBILITY["architecture"]="PASS"
            ((IPV6WGM_COMPATIBILITY_PASSED++))
            log_success "✓ CPU架构兼容 (ARM64)"
            ;;
        "i386"|"i686"|"x86")
            IPV6WGM_HARDWARE_COMPATIBILITY["architecture"]="WARN"
            ((IPV6WGM_COMPATIBILITY_WARNINGS_COUNT++))
            log_warn "! CPU架构可能不兼容 (32位)"
            ;;
        "armv7l"|"armv6l")
            IPV6WGM_HARDWARE_COMPATIBILITY["architecture"]="WARN"
            ((IPV6WGM_COMPATIBILITY_WARNINGS_COUNT++))
            log_warn "! CPU架构可能不兼容 (ARM32)"
            ;;
        *)
            IPV6WGM_HARDWARE_COMPATIBILITY["architecture"]="UNKNOWN"
            log_warn "! CPU架构未知 ($IPV6WGM_CPU_ARCH)"
            ;;
    esac
}

# 生成兼容性报告
generate_compatibility_report() {
    echo
    echo "=== 硬件兼容性报告 ==="
    echo "CPU架构: $IPV6WGM_CPU_ARCH"
    echo "CPU核心数: $IPV6WGM_CPU_CORES"
    echo "总内存: ${IPV6WGM_TOTAL_MEMORY}MB ($((IPV6WGM_TOTAL_MEMORY / 1024))GB)"
    echo "可用内存: ${IPV6WGM_AVAILABLE_MEMORY}MB ($((IPV6WGM_AVAILABLE_MEMORY / 1024))GB)"
    echo "可用磁盘空间: ${IPV6WGM_DISK_SPACE}MB ($((IPV6WGM_DISK_SPACE / 1024))GB)"
    echo "网络接口数: $IPV6WGM_NETWORK_INTERFACES"
    echo
    echo "兼容性检查结果:"
    echo "通过: $IPV6WGM_COMPATIBILITY_PASSED"
    echo "失败: $IPV6WGM_COMPATIBILITY_FAILED"
    echo "警告: $IPV6WGM_COMPATIBILITY_WARNINGS_COUNT"
    
    # 显示详细结果
    echo
    echo "详细结果:"
    for component in cpu memory disk network architecture; do
        local status="${IPV6WGM_HARDWARE_COMPATIBILITY[$component]}"
        case "$status" in
            "PASS")
                echo "  ✓ $component: 通过"
                ;;
            "FAIL")
                echo "  ✗ $component: 失败"
                ;;
            "WARN")
                echo "  ! $component: 警告"
                ;;
            "UNKNOWN")
                echo "  ? $component: 未知"
                ;;
        esac
    done
}

# 获取硬件性能建议
get_hardware_performance_suggestions() {
    echo "=== 硬件性能优化建议 ==="
    
    # CPU建议
    local cpu_cores=$IPV6WGM_CPU_CORES
    local rec_cores="${IPV6WGM_RECOMMENDED_REQUIREMENTS[cpu_cores]}"
    if [[ $cpu_cores -lt $rec_cores ]]; then
        echo "CPU: 建议升级到至少 $rec_cores 个核心以获得更好性能"
    else
        echo "CPU: 核心数充足，性能良好"
    fi
    
    # 内存建议
    local memory_gb=$((IPV6WGM_TOTAL_MEMORY / 1024))
    local rec_memory="${IPV6WGM_RECOMMENDED_REQUIREMENTS[memory_gb]}"
    if [[ $memory_gb -lt $rec_memory ]]; then
        echo "内存: 建议升级到至少 ${rec_memory}GB 内存"
    else
        echo "内存: 内存充足，性能良好"
    fi
    
    # 磁盘建议
    local disk_gb=$((IPV6WGM_DISK_SPACE / 1024))
    local rec_disk="${IPV6WGM_RECOMMENDED_REQUIREMENTS[disk_gb]}"
    if [[ $disk_gb -lt $rec_disk ]]; then
        echo "磁盘: 建议释放磁盘空间或升级存储"
    else
        echo "磁盘: 磁盘空间充足"
    fi
    
    # 网络建议
    local interfaces=$IPV6WGM_NETWORK_INTERFACES
    local rec_interfaces="${IPV6WGM_RECOMMENDED_REQUIREMENTS[network_interfaces]}"
    if [[ $interfaces -lt $rec_interfaces ]]; then
        echo "网络: 建议配置更多网络接口"
    else
        echo "网络: 网络接口充足"
    fi
    
    # 架构建议
    case "$IPV6WGM_CPU_ARCH" in
        "x86_64"|"amd64")
            echo "架构: x86_64架构，完全兼容"
            ;;
        "aarch64"|"arm64")
            echo "架构: ARM64架构，兼容性良好"
            ;;
        "i386"|"i686"|"x86")
            echo "架构: 32位架构，建议升级到64位"
            ;;
        *)
            echo "架构: 未知架构，需要进一步测试"
            ;;
    esac
}

# 获取硬件统计信息
get_hardware_statistics() {
    echo "=== 硬件统计信息 ==="
    echo "硬件检查: $([ "$IPV6WGM_HARDWARE_CHECK_ENABLED" == "true" ] && echo "启用" || echo "禁用")"
    echo "性能监控: $([ "$IPV6WGM_PERFORMANCE_MONITORING" == "true" ] && echo "启用" || echo "禁用")"
    echo "兼容性警告: $([ "$IPV6WGM_COMPATIBILITY_WARNINGS" == "true" ] && echo "启用" || echo "禁用")"
    echo
    echo "硬件规格:"
    echo "  CPU架构: $IPV6WGM_CPU_ARCH"
    echo "  CPU核心: $IPV6WGM_CPU_CORES"
    echo "  总内存: ${IPV6WGM_TOTAL_MEMORY}MB"
    echo "  可用内存: ${IPV6WGM_AVAILABLE_MEMORY}MB"
    echo "  磁盘空间: ${IPV6WGM_DISK_SPACE}MB"
    echo "  网络接口: $IPV6WGM_NETWORK_INTERFACES"
    echo
    echo "兼容性状态:"
    echo "  通过检查: $IPV6WGM_COMPATIBILITY_PASSED"
    echo "  失败检查: $IPV6WGM_COMPATIBILITY_FAILED"
    echo "  警告数量: $IPV6WGM_COMPATIBILITY_WARNINGS_COUNT"
}

# 导出函数
export -f init_hardware_compatibility
export -f detect_hardware_info
export -f check_hardware_compatibility
export -f get_hardware_performance_suggestions
export -f get_hardware_statistics
