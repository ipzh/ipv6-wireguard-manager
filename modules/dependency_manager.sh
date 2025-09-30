#!/bin/bash

# 依赖管理系统
# 提供模块依赖关系管理、自动解析和版本锁定功能

# =============================================================================
# 依赖管理配置
# =============================================================================

# 依赖关系图
declare -A IPV6WGM_DEPENDENCY_GRAPH=(
    # 核心模块
    ["common_functions"]=""
    ["variable_management"]="common_functions"
    ["function_management"]="common_functions variable_management"
    ["main_script_refactor"]="common_functions variable_management function_management"
    
    # 配置管理
    ["unified_config"]="common_functions variable_management"
    ["enhanced_config_management"]="common_functions variable_management unified_config"
    
    # 错误处理
    ["error_handling"]="common_functions variable_management"
    ["enhanced_error_handling"]="common_functions error_handling"
    
    # 系统检测
    ["system_detection"]="common_functions variable_management"
    
    # 模块加载
    ["module_loader"]="common_functions"
    ["enhanced_module_loader"]="common_functions function_management"
    ["lazy_loading"]="common_functions"
    
    # 功能模块
    ["wireguard_config"]="common_functions unified_config system_detection"
    ["bird_config"]="common_functions unified_config system_detection"
    ["web_management"]="common_functions unified_config error_handling"
    ["firewall_management"]="common_functions unified_config system_detection"
    ["client_management"]="common_functions unified_config wireguard_config"
    ["backup_restore"]="common_functions unified_config"
    ["system_monitoring"]="common_functions unified_config"
    ["resource_monitoring"]="common_functions system_monitoring"
    ["self_diagnosis"]="common_functions unified_config system_monitoring"
    
    # 工具模块
    ["function_optimizer"]="common_functions function_management"
    ["version_control"]="common_functions"
    ["update_management"]="common_functions version_control"
)

# 模块版本要求
declare -A IPV6WGM_VERSION_REQUIREMENTS=(
    ["common_functions"]=">=1.2.0"
    ["variable_management"]=">=1.0.0"
    ["function_management"]=">=1.0.0"
    ["main_script_refactor"]=">=1.0.0"
    ["unified_config"]=">=1.1.0"
    ["enhanced_config_management"]=">=1.0.0"
    ["error_handling"]=">=1.0.0"
    ["enhanced_error_handling"]=">=1.0.0"
    ["system_detection"]=">=1.0.0"
    ["module_loader"]=">=1.0.0"
    ["enhanced_module_loader"]=">=1.1.0"
    ["lazy_loading"]=">=1.0.0"
    ["wireguard_config"]=">=1.0.0"
    ["bird_config"]=">=1.0.0"
    ["web_management"]=">=1.0.0"
    ["firewall_management"]=">=1.0.0"
    ["client_management"]=">=1.0.0"
    ["backup_restore"]=">=1.0.0"
    ["system_monitoring"]=">=1.0.0"
    ["resource_monitoring"]=">=1.0.0"
    ["self_diagnosis"]=">=1.0.0"
    ["function_optimizer"]=">=1.0.0"
    ["version_control"]=">=1.0.0"
    ["update_management"]=">=1.0.0"
)

# 依赖状态跟踪
declare -A IPV6WGM_DEPENDENCY_STATUS=()
declare -A IPV6WGM_LOADED_DEPENDENCIES=()

# =============================================================================
# 依赖解析函数
# =============================================================================

# 解析模块依赖
resolve_dependencies() {
    local module_name="$1"
    local resolved_deps=()
    local visited=()
    
    log_debug "解析模块依赖: $module_name"
    
    # 递归解析依赖
    _resolve_dependencies_recursive "$module_name" resolved_deps visited
    
    echo "${resolved_deps[@]}"
}

# 递归解析依赖
_resolve_dependencies_recursive() {
    local module_name="$1"
    local -n deps_ref="$2"
    local -n visited_ref="$3"
    
    # 检查是否已访问
    if [[ " ${visited_ref[@]} " =~ " $module_name " ]]; then
        return 0
    fi
    
    # 标记为已访问
    visited_ref+=("$module_name")
    
    # 获取直接依赖
    local direct_deps="${IPV6WGM_DEPENDENCY_GRAPH[$module_name]:-}"
    
    if [[ -n "$direct_deps" ]]; then
        for dep in $direct_deps; do
            # 递归解析依赖的依赖
            _resolve_dependencies_recursive "$dep" deps_ref visited_ref
            
            # 添加到依赖列表
            if [[ ! " ${deps_ref[@]} " =~ " $dep " ]]; then
                deps_ref+=("$dep")
            fi
        done
    fi
}

# 检查依赖是否满足
check_dependency_satisfied() {
    local module_name="$1"
    local dep_name="$2"
    local required_version="${IPV6WGM_VERSION_REQUIREMENTS[$dep_name]:-}"
    
    # 检查模块是否已加载
    if [[ -n "${IPV6WGM_LOADED_DEPENDENCIES[$dep_name]:-}" ]]; then
        # 检查版本要求
        if [[ -n "$required_version" ]]; then
            local current_version="${IPV6WGM_LOADED_DEPENDENCIES[$dep_name]}"
            if ! check_version_compatibility "$current_version" "$required_version"; then
                log_error "模块 '$module_name' 的依赖 '$dep_name' 版本不满足要求"
                log_error "需要: $required_version, 当前: $current_version"
                return 1
            fi
        fi
        return 0
    else
        log_error "模块 '$module_name' 缺少依赖: $dep_name"
        return 1
    fi
}

# 版本兼容性检查
check_version_compatibility() {
    local current_version="$1"
    local required_version="$2"
    
    # 移除版本前缀
    current_version=$(echo "$current_version" | sed 's/^v//')
    required_version=$(echo "$required_version" | sed 's/^v//')
    
    # 提取操作符和版本号
    local operator=$(echo "$required_version" | grep -o '[><=!]*')
    local version=$(echo "$required_version" | sed 's/[><=!]*//')
    
    # 比较版本
    case "$operator" in
        ">=")
            if compare_versions "$current_version" "$version" -ge; then
                return 0
            fi
            ;;
        ">")
            if compare_versions "$current_version" "$version" -gt; then
                return 0
            fi
            ;;
        "<=")
            if compare_versions "$current_version" "$version" -le; then
                return 0
            fi
            ;;
        "<")
            if compare_versions "$current_version" "$version" -lt; then
                return 0
            fi
            ;;
        "="|"")
            if compare_versions "$current_version" "$version" -eq; then
                return 0
            fi
            ;;
        "!=")
            if ! compare_versions "$current_version" "$version" -eq; then
                return 0
            fi
            ;;
        *)
            log_warn "未知的版本操作符: $operator"
            return 1
            ;;
    esac
    
    return 1
}

# 版本比较函数
compare_versions() {
    local version1="$1"
    local version2="$2"
    local operator="$3"
    
    # 将版本号转换为数字数组
    local mapfile -t v1_parts < <(echo "$version1" | tr '.' ' ')
    local mapfile -t v2_parts < <(echo "$version2" | tr '.' ' ')
    
    # 补齐版本号长度
    local max_len=$((${#v1_parts[@]} > ${#v2_parts[@]} ? ${#v1_parts[@]} : ${#v2_parts[@]}))
    
    for ((i=0; i<max_len; i++)); do
        local v1_part=${v1_parts[$i]:-0}
        local v2_part=${v2_parts[$i]:-0}
        
        if [[ $v1_part -gt $v2_part ]]; then
            case "$operator" in
                "-gt"|">") return 0 ;;
                "-ge"|">=") return 0 ;;
                "-lt"|"<") return 1 ;;
                "-le"|"<=") return 1 ;;
                "-eq"|"=") return 1 ;;
                "-ne"|"!=") return 0 ;;
            esac
        elif [[ $v1_part -lt $v2_part ]]; then
            case "$operator" in
                "-gt"|">") return 1 ;;
                "-ge"|">=") return 1 ;;
                "-lt"|"<") return 0 ;;
                "-le"|"<=") return 0 ;;
                "-eq"|"=") return 1 ;;
                "-ne"|"!=") return 0 ;;
            esac
        fi
    done
    
    # 版本相等
    case "$operator" in
        "-gt"|">") return 1 ;;
        "-ge"|">=") return 0 ;;
        "-lt"|"<") return 1 ;;
        "-le"|"<=") return 0 ;;
        "-eq"|"=") return 0 ;;
        "-ne"|"!=") return 1 ;;
    esac
}

# =============================================================================
# 依赖安装和检查
# =============================================================================

# 检查模块依赖
check_module_dependencies() {
    local module_name="$1"
    local missing_deps=()
    local version_conflicts=()
    
    log_info "检查模块依赖: $module_name"
    
    # 解析依赖
    local mapfile -t dependencies < <(resolve_dependencies "$module_name")
    
    for dep in "${dependencies[@]}"; do
        # 检查依赖是否存在
        if ! check_dependency_exists "$dep"; then
            missing_deps+=("$dep")
            continue
        fi
        
        # 检查版本兼容性
        if ! check_dependency_satisfied "$module_name" "$dep"; then
            version_conflicts+=("$dep")
        fi
    done
    
    # 报告结果
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        return 1
    fi
    
    if [[ ${#version_conflicts[@]} -gt 0 ]]; then
        log_error "版本冲突: ${version_conflicts[*]}"
        return 1
    fi
    
    log_success "模块依赖检查通过: $module_name"
    return 0
}

# 检查依赖是否存在
check_dependency_exists() {
    local dep_name="$1"
    
    # 检查模块文件是否存在
    if [[ -f "$IPV6WGM_MODULES_DIR/${dep_name}.sh" ]]; then
        return 0
    fi
    
    # 检查是否已加载
    if [[ -n "${IPV6WGM_LOADED_DEPENDENCIES[$dep_name]:-}" ]]; then
        return 0
    fi
    
    return 1
}

# 自动安装缺失依赖
install_missing_dependencies() {
    local module_name="$1"
    local mapfile -t dependencies < <(resolve_dependencies "$module_name")
    
    log_info "自动安装缺失依赖: $module_name"
    
    for dep in "${dependencies[@]}"; do
        if ! check_dependency_exists "$dep"; then
            log_info "安装依赖: $dep"
            if ! install_dependency "$dep"; then
                log_error "依赖安装失败: $dep"
                return 1
            fi
        fi
    done
    
    log_success "所有依赖安装完成: $module_name"
    return 0
}

# 安装单个依赖
install_dependency() {
    local dep_name="$1"
    
    # 这里可以实现具体的依赖安装逻辑
    # 例如：从包管理器安装、从源码编译等
    
    case "$dep_name" in
        "common_functions")
            # 基础模块，应该已经存在
            return 0
            ;;
        "variable_management"|"function_management"|"main_script_refactor")
            # 新模块，检查文件是否存在
            if [[ -f "$IPV6WGM_MODULES_DIR/${dep_name}.sh" ]]; then
                return 0
            else
                log_error "模块文件不存在: ${dep_name}.sh"
                return 1
            fi
            ;;
        *)
            log_warn "未知依赖类型: $dep_name"
            return 1
            ;;
    esac
}

# =============================================================================
# 依赖锁定和版本管理
# =============================================================================

# 锁定依赖版本
lock_dependencies() {
    local lock_file="${1:-$IPV6WGM_CONFIG_DIR/dependencies.lock}"
    
    log_info "锁定依赖版本: $lock_file"
    
    {
        echo "# IPv6 WireGuard Manager 依赖锁定文件"
        echo "# 生成时间: $(date)"
        echo ""
        
        for module in "${!IPV6WGM_LOADED_DEPENDENCIES[@]}"; do
            local version="${IPV6WGM_LOADED_DEPENDENCIES[$module]}"
            echo "$module=$version"
        done
    } > "$lock_file"
    
    log_success "依赖版本已锁定: $lock_file"
}

# 从锁定文件加载依赖
load_dependencies_from_lock() {
    local lock_file="${1:-$IPV6WGM_CONFIG_DIR/dependencies.lock}"
    
    if [[ ! -f "$lock_file" ]]; then
        log_warn "依赖锁定文件不存在: $lock_file"
        return 1
    fi
    
    log_info "从锁定文件加载依赖: $lock_file"
    
    while IFS='=' read -r module version; do
        # 跳过注释和空行
        [[ "$module" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$module" ]] && continue
        
        IPV6WGM_LOADED_DEPENDENCIES[$module]="$version"
        log_debug "加载依赖: $module=$version"
    done < "$lock_file"
    
    log_success "依赖版本已加载"
    return 0
}

# 更新依赖版本
update_dependencies() {
    local module_name="$1"
    local new_version="$2"
    
    if [[ -z "${IPV6WGM_LOADED_DEPENDENCIES[$module_name]:-}" ]]; then
        log_error "模块未加载: $module_name"
        return 1
    fi
    
    local old_version="${IPV6WGM_LOADED_DEPENDENCIES[$module_name]}"
    IPV6WGM_LOADED_DEPENDENCIES[$module_name]="$new_version"
    
    log_info "更新依赖版本: $module_name $old_version -> $new_version"
    
    # 检查版本兼容性
    local required_version="${IPV6WGM_VERSION_REQUIREMENTS[$module_name]:-}"
    if [[ -n "$required_version" ]]; then
        if ! check_version_compatibility "$new_version" "$required_version"; then
            log_error "新版本不满足要求: $module_name $new_version vs $required_version"
            # 回滚版本
            IPV6WGM_LOADED_DEPENDENCIES[$module_name]="$old_version"
            return 1
        fi
    fi
    
    log_success "依赖版本更新成功: $module_name"
    return 0
}

# =============================================================================
# 依赖分析和报告
# =============================================================================

# 生成依赖报告
generate_dependency_report() {
    local output_file="${1:-/tmp/dependency_report_$(date +%Y%m%d_%H%M%S).txt}"
    
    {
        echo "=== IPv6 WireGuard Manager 依赖分析报告 ==="
        echo "生成时间: $(date)"
        echo ""
        
        echo "=== 依赖关系图 ==="
        for module in "${!IPV6WGM_DEPENDENCY_GRAPH[@]}"; do
            local deps="${IPV6WGM_DEPENDENCY_GRAPH[$module]}"
            if [[ -n "$deps" ]]; then
                echo "$module -> $deps"
            else
                echo "$module (无依赖)"
            fi
        done
        echo ""
        
        echo "=== 已加载依赖 ==="
        for module in "${!IPV6WGM_LOADED_DEPENDENCIES[@]}"; do
            local version="${IPV6WGM_LOADED_DEPENDENCIES[$module]}"
            echo "$module: $version"
        done
        echo ""
        
        echo "=== 版本要求 ==="
        for module in "${!IPV6WGM_VERSION_REQUIREMENTS[@]}"; do
            local requirement="${IPV6WGM_VERSION_REQUIREMENTS[$module]}"
            echo "$module: $requirement"
        done
        
    } > "$output_file"
    
    log_info "依赖报告已生成: $output_file"
    echo "$output_file"
}

# 检查循环依赖
check_circular_dependencies() {
    local module_name="$1"
    local visited=()
    local recursion_stack=()
    
    log_info "检查循环依赖: $module_name"
    
    if _check_circular_dependencies_recursive "$module_name" visited recursion_stack; then
        log_error "发现循环依赖: $module_name"
        return 1
    else
        log_success "无循环依赖: $module_name"
        return 0
    fi
}

# 递归检查循环依赖
_check_circular_dependencies_recursive() {
    local module_name="$1"
    local -n visited_ref="$2"
    local -n stack_ref="$3"
    
    # 检查是否在递归栈中
    if [[ " ${stack_ref[@]} " =~ " $module_name " ]]; then
        return 0  # 发现循环依赖
    fi
    
    # 检查是否已访问
    if [[ " ${visited_ref[@]} " =~ " $module_name " ]]; then
        return 1  # 已访问，无循环
    fi
    
    # 标记为已访问
    visited_ref+=("$module_name")
    stack_ref+=("$module_name")
    
    # 检查依赖
    local dependencies="${IPV6WGM_DEPENDENCY_GRAPH[$module_name]:-}"
    if [[ -n "$dependencies" ]]; then
        for dep in $dependencies; do
            if _check_circular_dependencies_recursive "$dep" visited_ref stack_ref; then
                return 0  # 发现循环依赖
            fi
        done
    fi
    
    # 从递归栈中移除
    stack_ref=(${stack_ref[@]/$module_name/})
    
    return 1  # 无循环依赖
}

# 导出函数
export -f resolve_dependencies check_dependency_satisfied check_version_compatibility
export -f check_module_dependencies install_missing_dependencies install_dependency
export -f lock_dependencies load_dependencies_from_lock update_dependencies
export -f generate_dependency_report check_circular_dependencies
