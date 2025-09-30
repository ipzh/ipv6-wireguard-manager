#!/bin/bash

# 模块加载器
# 负责动态加载和管理所有功能模块

# 模块状态跟踪
declare -A MODULE_STATUS
declare -A MODULE_DEPENDENCIES
declare -A MODULE_FUNCTIONS

# 模块加载顺序（按依赖关系排序）
MODULE_LOAD_ORDER=(
    "common_functions"
    "error_handling"
    "system_detection"
    "user_interface"
    "menu_templates"
    "wireguard_config"
    "bird_config"
    "network_management"
    "firewall_management"
    "client_management"
    "backup_restore"
    "monitoring_alerting"
    "client_auto_install"
    "web_management"
    "update_management"
    "repository_config"
    "firewall_ports"
    "config_management"
    "web_interface_enhanced"
    "oauth_authentication"
    "security_audit_monitoring"
    "network_topology"
    "api_documentation"
    "websocket_realtime"
    "multi_tenant"
    "resource_quota"
    "lazy_loading"
    "performance_optimization"
    "performance_enhancements"
)

# 模块依赖关系定义
MODULE_DEPENDENCIES=(
    # 基础模块 - 无依赖
    ["common_functions"]=""
    
    # 第一层依赖 - 仅依赖common_functions
    ["error_handling"]="common_functions"
    ["system_detection"]="common_functions"
    ["user_interface"]="common_functions"
    ["repository_config"]="common_functions"
    ["config_management"]="common_functions"
    ["lazy_loading"]="common_functions"
    ["performance_optimization"]="common_functions"
    
    # 第二层依赖 - 依赖基础模块
    ["menu_templates"]="common_functions user_interface"
    ["wireguard_config"]="common_functions system_detection"
    ["bird_config"]="common_functions system_detection"
    ["backup_restore"]="common_functions"
    ["update_management"]="common_functions system_detection"
    ["firewall_ports"]="common_functions system_detection"
    ["oauth_authentication"]="common_functions"
    
    # 第三层依赖 - 依赖第二层模块
    ["network_management"]="common_functions wireguard_config bird_config"
    ["firewall_management"]="common_functions system_detection"
    ["client_management"]="common_functions wireguard_config"
    ["monitoring_alerting"]="common_functions system_detection"
    ["web_management"]="common_functions client_management"
    ["security_audit_monitoring"]="common_functions oauth_authentication"
    
    # 第四层依赖 - 依赖第三层模块
    ["client_auto_install"]="common_functions client_management"
    ["web_interface_enhanced"]="common_functions web_management"
    ["network_topology"]="common_functions web_management"
    ["api_documentation"]="common_functions web_management"
    ["websocket_realtime"]="common_functions web_management"
    ["multi_tenant"]="common_functions oauth_authentication"
    
    # 第五层依赖 - 依赖第四层模块
    ["resource_quota"]="common_functions multi_tenant"
    ["performance_enhancements"]="common_functions performance_optimization"
)

# 加载单个模块
load_module() {
    local module_name="$1"
    local module_file="${MODULES_DIR}/${module_name}.sh"
    
    # 检查模块是否已加载
    if [[ "${MODULE_STATUS[$module_name]:-}" == "loaded" ]]; then
        log_debug "模块已加载: $module_name"
        return 0
    fi
    
    # 检查模块文件是否存在
    if [[ ! -f "$module_file" ]]; then
        log_error "模块文件不存在: $module_file"
        MODULE_STATUS[$module_name]="error"
        return 1
    fi
    
    # 检查模块依赖
    if ! check_module_dependencies "$module_name"; then
        log_error "模块依赖检查失败: $module_name"
        MODULE_STATUS[$module_name]="error"
        return 1
    fi
    
    # 加载模块
    log_debug "正在加载模块: $module_name"
    
    # 创建模块命名空间
    local module_namespace="module_${module_name}_"
    
    # 保存当前函数列表
    local functions_before=$(declare -F | awk '{print $3}')
    
    # 加载模块文件
    if source "$module_file"; then
        # 获取新加载的函数
        local functions_after=$(declare -F | awk '{print $3}')
        local new_functions=$(comm -13 <(echo "$functions_before" | sort) <(echo "$functions_after" | sort))
        
        # 记录模块函数
        MODULE_FUNCTIONS[$module_name]="$new_functions"
        MODULE_STATUS[$module_name]="loaded"
        
        log_info "模块加载成功: $module_name"
        return 0
    else
        log_error "模块加载失败: $module_name"
        MODULE_STATUS[$module_name]="error"
        return 1
    fi
}

# 检查模块依赖
check_module_dependencies() {
    local module_name="$1"
    local dependencies="${MODULE_DEPENDENCIES[$module_name]:-}"
    
    if [[ -z "$dependencies" ]]; then
        return 0
    fi
    
    for dep in $dependencies; do
        if [[ "${MODULE_STATUS[$dep]:-}" != "loaded" ]]; then
            log_error "模块 $module_name 依赖的模块 $dep 未加载"
            return 1
        fi
    done
    
    return 0
}

# 加载所有模块
load_all_modules() {
    log_info "开始加载所有模块..."
    
    local loaded_count=0
    local total_count=${#MODULE_LOAD_ORDER[@]}
    local failed_modules=()
    
    for module in "${MODULE_LOAD_ORDER[@]}"; do
        show_progress $((loaded_count + 1)) $total_count "加载模块: $module"
        
        if load_module "$module"; then
            ((loaded_count++))
        else
            failed_modules+=("$module")
        fi
    done
    
    echo # 换行
    
    if [[ ${#failed_modules[@]} -eq 0 ]]; then
        log_info "所有模块加载成功 ($loaded_count/$total_count)"
        return 0
    else
        log_error "部分模块加载失败: ${failed_modules[*]}"
        return 1
    fi
}

# 卸载模块
unload_module() {
    local module_name="$1"
    
    if [[ "${MODULE_STATUS[$module_name]:-}" != "loaded" ]]; then
        log_warn "模块未加载: $module_name"
        return 0
    fi
    
    # 获取模块函数列表
    local functions="${MODULE_FUNCTIONS[$module_name]:-}"
    
    if [[ -n "$functions" ]]; then
        # 卸载模块函数
        for func in $functions; do
            unset -f "$func" 2>/dev/null || true
        done
    fi
    
    # 更新模块状态
    MODULE_STATUS[$module_name]="unloaded"
    unset MODULE_FUNCTIONS[$module_name]
    
    log_info "模块已卸载: $module_name"
}

# 重新加载模块
reload_module() {
    local module_name="$1"
    
    log_info "重新加载模块: $module_name"
    
    # 先卸载
    unload_module "$module_name"
    
    # 再加载
    load_module "$module_name"
}

# 检查模块状态
check_module_status() {
    local module_name="$1"
    echo "${MODULE_STATUS[$module_name]:-unknown}"
}

# 列出已加载的模块
list_loaded_modules() {
    echo "已加载的模块:"
    for module in "${!MODULE_STATUS[@]}"; do
        if [[ "${MODULE_STATUS[$module]}" == "loaded" ]]; then
            echo "  ✓ $module"
        fi
    done
}

# 列出模块函数
list_module_functions() {
    local module_name="$1"
    local functions="${MODULE_FUNCTIONS[$module_name]:-}"
    
    if [[ -n "$functions" ]]; then
        echo "模块 $module_name 的函数:"
        for func in $functions; do
            echo "  - $func"
        done
    else
        echo "模块 $module_name 没有导出函数"
    fi
}

# 验证模块完整性
validate_modules() {
    log_info "验证模块完整性..."
    
    local missing_files=()
    local invalid_dependencies=()
    
    # 检查模块文件是否存在
    for module in "${MODULE_LOAD_ORDER[@]}"; do
        local module_file="${MODULES_DIR}/${module}.sh"
        if [[ ! -f "$module_file" ]]; then
            missing_files+=("$module")
        fi
    done
    
    # 检查依赖关系
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        local dependencies="${MODULE_DEPENDENCIES[$module]}"
        for dep in $dependencies; do
            if ! array_contains "$dep" "${MODULE_LOAD_ORDER[@]}"; then
                invalid_dependencies+=("$module -> $dep")
            fi
        done
    done
    
    # 报告结果
    if [[ ${#missing_files[@]} -eq 0 && ${#invalid_dependencies[@]} -eq 0 ]]; then
        log_info "模块完整性验证通过"
        return 0
    else
        if [[ ${#missing_files[@]} -gt 0 ]]; then
            log_error "缺少模块文件: ${missing_files[*]}"
        fi
        if [[ ${#invalid_dependencies[@]} -gt 0 ]]; then
            log_error "无效的依赖关系: ${invalid_dependencies[*]}"
        fi
        return 1
    fi
}

# 获取模块信息
get_module_info() {
    local module_name="$1"
    local module_file="${MODULES_DIR}/${module_name}.sh"
    
    if [[ ! -f "$module_file" ]]; then
        echo "模块文件不存在: $module_name"
        return 1
    fi
    
    echo "模块信息: $module_name"
    echo "  文件: $module_file"
    echo "  状态: ${MODULE_STATUS[$module_name]:-unknown}"
    echo "  依赖: ${MODULE_DEPENDENCIES[$module_name]:-无}"
    echo "  函数数量: $(echo "${MODULE_FUNCTIONS[$module_name]:-}" | wc -w)"
    
    # 获取文件信息
    if [[ -f "$module_file" ]]; then
        local file_size=$(stat -c%s "$module_file" 2>/dev/null || echo "unknown")
        local file_lines=$(wc -l < "$module_file" 2>/dev/null || echo "unknown")
        echo "  文件大小: $file_size 字节"
        echo "  代码行数: $file_lines 行"
    fi
}

# 模块热重载
hot_reload_modules() {
    log_info "开始热重载模块..."
    
    local reloaded_count=0
    local failed_count=0
    
    for module in "${!MODULE_STATUS[@]}"; do
        if [[ "${MODULE_STATUS[$module]}" == "loaded" ]]; then
            if reload_module "$module"; then
                ((reloaded_count++))
            else
                ((failed_count++))
            fi
        fi
    done
    
    log_info "热重载完成: 成功 $reloaded_count, 失败 $failed_count"
}

# 模块依赖分析
analyze_dependencies() {
    log_info "分析模块依赖关系..."
    
    echo "依赖关系图:"
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        local dependencies="${MODULE_DEPENDENCIES[$module]}"
        if [[ -n "$dependencies" ]]; then
            echo "  $module 依赖: $dependencies"
        else
            echo "  $module (无依赖)"
        fi
    done
    
    # 检查循环依赖
    local circular_deps=()
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        if check_circular_dependency "$module" "$module"; then
            circular_deps+=("$module")
        fi
    done
    
    if [[ ${#circular_deps[@]} -gt 0 ]]; then
        log_error "发现循环依赖: ${circular_deps[*]}"
        return 1
    else
        log_info "未发现循环依赖"
        return 0
    fi
}

# 检查循环依赖
check_circular_dependency() {
    local current_module="$1"
    local target_module="$2"
    local visited=()
    
    return check_circular_dependency_recursive "$current_module" "$target_module" "${visited[@]}"
}

check_circular_dependency_recursive() {
    local current_module="$1"
    local target_module="$2"
    shift 2
    local visited=("$@")
    
    # 检查是否已访问过
    if array_contains "$current_module" "${visited[@]}"; then
        return 1
    fi
    
    # 添加到访问列表
    visited+=("$current_module")
    
    # 获取依赖
    local dependencies="${MODULE_DEPENDENCIES[$current_module]:-}"
    
    for dep in $dependencies; do
        if [[ "$dep" == "$target_module" ]]; then
            return 0  # 找到循环依赖
        fi
        
        if check_circular_dependency_recursive "$dep" "$target_module" "${visited[@]}"; then
            return 0
        fi
    done
    
    return 1
}

# 模块性能分析
analyze_module_performance() {
    log_info "分析模块性能..."
    
    echo "模块加载时间分析:"
    for module in "${MODULE_LOAD_ORDER[@]}"; do
        local module_file="${MODULES_DIR}/${module}.sh"
        if [[ -f "$module_file" ]]; then
            local start_time=$(date +%s.%N)
            source "$module_file" 2>/dev/null
            local end_time=$(date +%s.%N)
            local load_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "unknown")
            echo "  $module: ${load_time}s"
        fi
    done
}

# 导出函数
export -f load_module load_all_modules unload_module reload_module
export -f check_module_status list_loaded_modules list_module_functions
export -f validate_modules get_module_info hot_reload_modules
export -f analyze_dependencies check_circular_dependency analyze_module_performance
