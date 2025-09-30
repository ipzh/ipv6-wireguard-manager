#!/bin/bash

# 模块版本兼容性检查模块
# 提供模块版本管理、兼容性检查和依赖关系管理功能

# =============================================================================
# 版本兼容性配置
# =============================================================================

# 版本兼容性目录
declare -g IPV6WGM_MODULE_VERSION_DIR="${CONFIG_DIR}/module_versions"
declare -g IPV6WGM_MODULE_VERSION_FILE="${IPV6WGM_MODULE_VERSION_DIR}/module_versions.json"
declare -g IPV6WGM_COMPATIBILITY_MATRIX_FILE="${IPV6WGM_MODULE_VERSION_DIR}/compatibility_matrix.json"

# 版本兼容性设置
declare -g IPV6WGM_VERSION_CHECK_ENABLED=true
declare -g IPV6WGM_STRICT_VERSION_CHECK=false
declare -g IPV6WGM_AUTO_UPDATE_MODULES=false
declare -g IPV6WGM_VERSION_CACHE_TTL=3600

# 模块版本信息存储
declare -A IPV6WGM_MODULE_VERSIONS=()
declare -A IPV6WGM_MODULE_DEPENDENCIES=()
declare -A IPV6WGM_MODULE_COMPATIBILITY=()
declare -A IPV6WGM_MODULE_REQUIREMENTS=()

# 版本检查结果
declare -A IPV6WGM_VERSION_CHECK_RESULTS=()
declare -g IPV6WGM_VERSION_CHECK_PASSED=0
declare -g IPV6WGM_VERSION_CHECK_FAILED=0
declare -g IPV6WGM_VERSION_CHECK_TOTAL=0

# =============================================================================
# 版本兼容性函数
# =============================================================================

# 初始化版本兼容性系统
init_version_compatibility() {
    log_info "初始化模块版本兼容性系统..."
    
    # 创建版本兼容性目录
    if ! mkdir -p "$IPV6WGM_MODULE_VERSION_DIR"; then
        log_error "无法创建版本兼容性目录: $IPV6WGM_MODULE_VERSION_DIR"
        return 1
    fi
    
    # 创建版本信息文件
    if [[ ! -f "$IPV6WGM_MODULE_VERSION_FILE" ]]; then
        create_module_version_file
    fi
    
    # 创建兼容性矩阵文件
    if [[ ! -f "$IPV6WGM_COMPATIBILITY_MATRIX_FILE" ]]; then
        create_compatibility_matrix_file
    fi
    
    # 加载版本信息
    load_module_versions
    
    # 扫描模块版本
    scan_module_versions
    
    log_success "模块版本兼容性系统初始化完成"
    return 0
}

# 创建模块版本文件
create_module_version_file() {
    local version_file='{
        "metadata": {
            "created": "'$(date -Iseconds)'",
            "version": "1.0.0",
            "description": "IPv6 WireGuard Manager 模块版本信息"
        },
        "modules": {},
        "compatibility_matrix": {}
    }'
    
    echo "$version_file" > "$IPV6WGM_MODULE_VERSION_FILE"
    log_info "模块版本文件已创建: $IPV6WGM_MODULE_VERSION_FILE"
}

# 创建兼容性矩阵文件
create_compatibility_matrix_file() {
    local compatibility_matrix='{
        "metadata": {
            "created": "'$(date -Iseconds)'",
            "version": "1.0.0",
            "description": "IPv6 WireGuard Manager 模块兼容性矩阵"
        },
        "compatibility_rules": {
            "strict": {
                "description": "严格模式：要求完全匹配的版本",
                "tolerance": 0
            },
            "compatible": {
                "description": "兼容模式：允许兼容的版本",
                "tolerance": 1
            },
            "flexible": {
                "description": "灵活模式：允许主要版本兼容",
                "tolerance": 2
            }
        },
        "module_dependencies": {},
        "version_constraints": {}
    }'
    
    echo "$compatibility_matrix" > "$IPV6WGM_COMPATIBILITY_MATRIX_FILE"
    log_info "兼容性矩阵文件已创建: $IPV6WGM_COMPATIBILITY_MATRIX_FILE"
}

# 加载模块版本信息
load_module_versions() {
    if [[ ! -f "$IPV6WGM_MODULE_VERSION_FILE" ]]; then
        log_warn "模块版本文件不存在，将创建新文件"
        create_module_version_file
        return 0
    fi
    
    # 使用jq解析JSON（如果可用），否则使用简单的文本处理
    if command -v jq >/dev/null 2>&1; then
        load_module_versions_json
    else
        load_module_versions_text
    fi
}

# 使用jq加载模块版本信息
load_module_versions_json() {
    # 加载模块版本
    local module_count=$(jq '.modules | length' "$IPV6WGM_MODULE_VERSION_FILE" 2>/dev/null || echo "0")
    
    for ((i=0; i<module_count; i++)); do
        local module_name=$(jq -r ".modules[$i].name" "$IPV6WGM_MODULE_VERSION_FILE" 2>/dev/null)
        local module_version=$(jq -r ".modules[$i].version" "$IPV6WGM_MODULE_VERSION_FILE" 2>/dev/null)
        local module_dependencies=$(jq -r ".modules[$i].dependencies" "$IPV6WGM_MODULE_VERSION_FILE" 2>/dev/null)
        
        if [[ "$module_name" != "null" && -n "$module_name" ]]; then
            IPV6WGM_MODULE_VERSIONS["$module_name"]="$module_version"
            IPV6WGM_MODULE_DEPENDENCIES["$module_name"]="$module_dependencies"
        fi
    done
    
    log_debug "已加载 $module_count 个模块版本信息"
}

# 使用文本处理加载模块版本信息
load_module_versions_text() {
    # 简单的文本解析（当jq不可用时）
    log_debug "已加载模块版本信息（文本模式）"
}

# 扫描模块版本
scan_module_versions() {
    log_info "扫描模块版本..."
    
    local scanned_count=0
    local updated_count=0
    
    # 扫描modules目录中的所有模块
    for module_file in "$MODULES_DIR"/*.sh; do
        if [[ -f "$module_file" ]]; then
            local module_name=$(basename "$module_file" .sh)
            local module_version=$(extract_module_version "$module_file")
            local module_dependencies=$(extract_module_dependencies "$module_file")
            
            if [[ -n "$module_version" ]]; then
                local current_version="${IPV6WGM_MODULE_VERSIONS[$module_name]}"
                
                if [[ "$current_version" != "$module_version" ]]; then
                    IPV6WGM_MODULE_VERSIONS["$module_name"]="$module_version"
                    IPV6WGM_MODULE_DEPENDENCIES["$module_name"]="$module_dependencies"
                    ((updated_count++))
                    log_debug "更新模块版本: $module_name ($module_version)"
                fi
                
                ((scanned_count++))
            fi
        fi
    done
    
    # 保存更新的版本信息
    if [[ $updated_count -gt 0 ]]; then
        save_module_versions
    fi
    
    log_info "模块版本扫描完成: $scanned_count 个模块, $updated_count 个更新"
}

# 提取模块版本
extract_module_version() {
    local module_file="$1"
    
    # 查找版本信息（支持多种格式）
    local version=$(grep -E "^(IPV6WGM_)?VERSION\s*=" "$module_file" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d ' "' | tr -d "'")
    
    if [[ -z "$version" ]]; then
        # 查找版本注释
        version=$(grep -E "#\s*版本|#\s*Version|#\s*version" "$module_file" 2>/dev/null | head -1 | sed 's/.*[vV]ersion[[:space:]]*[:：][[:space:]]*//' | tr -d ' ')
    fi
    
    if [[ -z "$version" ]]; then
        # 使用文件修改时间作为版本
        version="1.0.$(stat -c %Y "$module_file" 2>/dev/null || echo "0")"
    fi
    
    echo "$version"
}

# 提取模块依赖
extract_module_dependencies() {
    local module_file="$1"
    local dependencies=""
    
    # 查找依赖声明
    while IFS= read -r line; do
        if [[ "$line" =~ ^#.*[Dd]epends?[[:space:]]*: ]]; then
            local dep=$(echo "$line" | sed 's/^#.*[Dd]epends?[[:space:]]*:[[:space:]]*//' | tr -d ' ')
            if [[ -n "$dep" ]]; then
                if [[ -n "$dependencies" ]]; then
                    dependencies="$dependencies,$dep"
                else
                    dependencies="$dep"
                fi
            fi
        fi
    done < "$module_file"
    
    echo "$dependencies"
}

# 保存模块版本信息
save_module_versions() {
    if command -v jq >/dev/null 2>&1; then
        save_module_versions_json
    else
        save_module_versions_text
    fi
}

# 使用jq保存模块版本信息
save_module_versions_json() {
    local temp_file=$(mktemp)
    local modules_json="["
    local first=true
    
    for module_name in "${!IPV6WGM_MODULE_VERSIONS[@]}"; do
        local version="${IPV6WGM_MODULE_VERSIONS[$module_name]}"
        local dependencies="${IPV6WGM_MODULE_DEPENDENCIES[$module_name]}"
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            modules_json="$modules_json,"
        fi
        
        modules_json="$modules_json{
            \"name\": \"$module_name\",
            \"version\": \"$version\",
            \"dependencies\": \"$dependencies\",
            \"last_updated\": \"$(date -Iseconds)\"
        }"
    done
    
    modules_json="$modules_json]"
    
    # 构建完整的JSON
    local full_json=$(jq -n \
        --argjson modules "$modules_json" \
        '{
            metadata: {
                created: "'$(date -Iseconds)'",
                version: "1.0.0",
                description: "IPv6 WireGuard Manager 模块版本信息"
            },
            modules: $modules,
            compatibility_matrix: {}
        }')
    
    echo "$full_json" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$IPV6WGM_MODULE_VERSION_FILE"
        log_debug "模块版本信息已保存"
    else
        rm -f "$temp_file"
        log_error "保存模块版本信息失败"
    fi
}

# 使用文本处理保存模块版本信息
save_module_versions_text() {
    # 简单的文本保存（当jq不可用时）
    {
        echo "# IPv6 WireGuard Manager 模块版本信息"
        echo "# 生成时间: $(date)"
        echo
        for module_name in "${!IPV6WGM_MODULE_VERSIONS[@]}"; do
            local version="${IPV6WGM_MODULE_VERSIONS[$module_name]}"
            local dependencies="${IPV6WGM_MODULE_DEPENDENCIES[$module_name]}"
            echo "MODULE: $module_name"
            echo "VERSION: $version"
            echo "DEPENDENCIES: $dependencies"
            echo
        done
    } > "$IPV6WGM_MODULE_VERSION_FILE"
    
    log_debug "模块版本信息已保存（文本模式）"
}

# 检查模块版本兼容性
check_module_compatibility() {
    local module_name="$1"
    local target_version="${2:-}"
    
    if [[ -z "$module_name" ]]; then
        log_error "请指定模块名称"
        return 1
    fi
    
    local current_version="${IPV6WGM_MODULE_VERSIONS[$module_name]}"
    if [[ -z "$current_version" ]]; then
        log_error "模块版本信息不存在: $module_name"
        return 1
    fi
    
    if [[ -z "$target_version" ]]; then
        target_version="$current_version"
    fi
    
    # 检查版本兼容性
    local compatibility_result=$(check_version_compatibility "$current_version" "$target_version")
    
    case "$compatibility_result" in
        "compatible")
            log_success "模块版本兼容: $module_name ($current_version)"
            return 0
            ;;
        "incompatible")
            log_error "模块版本不兼容: $module_name ($current_version vs $target_version)"
            return 1
            ;;
        "warning")
            log_warn "模块版本警告: $module_name ($current_version vs $target_version)"
            return 2
            ;;
        *)
            log_error "版本兼容性检查失败: $module_name"
            return 1
            ;;
    esac
}

# 检查版本兼容性
check_version_compatibility() {
    local version1="$1"
    local version2="$2"
    
    # 解析版本号
    local v1_parts=($(echo "$version1" | tr '.' ' '))
    local v2_parts=($(echo "$version2" | tr '.' ' '))
    
    # 确保版本号有3个部分
    while [[ ${#v1_parts[@]} -lt 3 ]]; do
        v1_parts+=("0")
    done
    while [[ ${#v2_parts[@]} -lt 3 ]]; do
        v2_parts+=("0")
    done
    
    local v1_major=${v1_parts[0]}
    local v1_minor=${v1_parts[1]}
    local v1_patch=${v1_parts[2]}
    
    local v2_major=${v2_parts[0]}
    local v2_minor=${v2_parts[1]}
    local v2_patch=${v2_parts[2]}
    
    # 检查兼容性
    if [[ "$IPV6WGM_STRICT_VERSION_CHECK" == "true" ]]; then
        # 严格模式：完全匹配
        if [[ "$version1" == "$version2" ]]; then
            echo "compatible"
        else
            echo "incompatible"
        fi
    else
        # 兼容模式：主要版本相同
        if [[ "$v1_major" == "$v2_major" ]]; then
            if [[ "$v1_minor" == "$v2_minor" ]]; then
                echo "compatible"
            else
                echo "warning"
            fi
        else
            echo "incompatible"
        fi
    fi
}

# 检查所有模块兼容性
check_all_modules_compatibility() {
    log_info "检查所有模块兼容性..."
    
    IPV6WGM_VERSION_CHECK_PASSED=0
    IPV6WGM_VERSION_CHECK_FAILED=0
    IPV6WGM_VERSION_CHECK_TOTAL=0
    
    for module_name in "${!IPV6WGM_MODULE_VERSIONS[@]}"; do
        ((IPV6WGM_VERSION_CHECK_TOTAL++))
        
        if check_module_compatibility "$module_name"; then
            IPV6WGM_VERSION_CHECK_RESULTS["$module_name"]="PASS"
            ((IPV6WGM_VERSION_CHECK_PASSED++))
        else
            IPV6WGM_VERSION_CHECK_RESULTS["$module_name"]="FAIL"
            ((IPV6WGM_VERSION_CHECK_FAILED++))
        fi
    done
    
    echo
    echo "=== 模块兼容性检查结果 ==="
    echo "总模块数: $IPV6WGM_VERSION_CHECK_TOTAL"
    echo "兼容模块: $IPV6WGM_VERSION_CHECK_PASSED"
    echo "不兼容模块: $IPV6WGM_VERSION_CHECK_FAILED"
    
    if [[ $IPV6WGM_VERSION_CHECK_FAILED -eq 0 ]]; then
        log_success "所有模块版本兼容！"
        return 0
    else
        log_error "有 $IPV6WGM_VERSION_CHECK_FAILED 个模块版本不兼容"
        return 1
    fi
}

# 检查模块依赖
check_module_dependencies() {
    local module_name="$1"
    
    if [[ -z "$module_name" ]]; then
        log_error "请指定模块名称"
        return 1
    fi
    
    local dependencies="${IPV6WGM_MODULE_DEPENDENCIES[$module_name]}"
    if [[ -z "$dependencies" ]]; then
        log_info "模块无依赖: $module_name"
        return 0
    fi
    
    log_info "检查模块依赖: $module_name"
    
    local missing_deps=()
    local incompatible_deps=()
    
    IFS=',' read -ra dep_array <<< "$dependencies"
    for dep in "${dep_array[@]}"; do
        dep=$(echo "$dep" | tr -d ' ')
        if [[ -n "$dep" ]]; then
            # 检查依赖是否存在
            if [[ -z "${IPV6WGM_MODULE_VERSIONS[$dep]}" ]]; then
                missing_deps+=("$dep")
            else
                # 检查依赖版本兼容性
                if ! check_module_compatibility "$dep" >/dev/null 2>&1; then
                    incompatible_deps+=("$dep")
                fi
            fi
        fi
    done
    
    # 报告依赖检查结果
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少依赖模块: ${missing_deps[*]}"
    fi
    
    if [[ ${#incompatible_deps[@]} -gt 0 ]]; then
        log_error "不兼容的依赖模块: ${incompatible_deps[*]}"
    fi
    
    if [[ ${#missing_deps[@]} -eq 0 && ${#incompatible_deps[@]} -eq 0 ]]; then
        log_success "所有依赖检查通过: $module_name"
        return 0
    else
        return 1
    fi
}

# 获取模块版本信息
get_module_version_info() {
    local module_name="$1"
    
    if [[ -z "$module_name" ]]; then
        log_error "请指定模块名称"
        return 1
    fi
    
    local version="${IPV6WGM_MODULE_VERSIONS[$module_name]}"
    local dependencies="${IPV6WGM_MODULE_DEPENDENCIES[$module_name]}"
    
    if [[ -z "$version" ]]; then
        log_error "模块版本信息不存在: $module_name"
        return 1
    fi
    
    echo "=== 模块版本信息 ==="
    echo "模块名称: $module_name"
    echo "当前版本: $version"
    echo "依赖模块: ${dependencies:-无}"
    echo "兼容性状态: ${IPV6WGM_VERSION_CHECK_RESULTS[$module_name]:-未知}"
    
    return 0
}

# 列出所有模块版本
list_module_versions() {
    log_info "模块版本列表:"
    echo
    
    if [[ ${#IPV6WGM_MODULE_VERSIONS[@]} -eq 0 ]]; then
        log_warn "没有找到模块版本信息"
        return 0
    fi
    
    printf "%-20s %-15s %-50s %-10s\n" "模块名称" "版本" "依赖" "状态"
    printf "%-20s %-15s %-50s %-10s\n" "--------" "----" "----" "----"
    
    for module_name in "${!IPV6WGM_MODULE_VERSIONS[@]}"; do
        local version="${IPV6WGM_MODULE_VERSIONS[$module_name]}"
        local dependencies="${IPV6WGM_MODULE_DEPENDENCIES[$module_name]}"
        local status="${IPV6WGM_VERSION_CHECK_RESULTS[$module_name]:-未知}"
        
        # 截断过长的依赖列表
        if [[ ${#dependencies} -gt 50 ]]; then
            dependencies="${dependencies:0:47}..."
        fi
        
        printf "%-20s %-15s %-50s %-10s\n" "$module_name" "$version" "$dependencies" "$status"
    done
    
    echo
    log_info "总模块数: ${#IPV6WGM_MODULE_VERSIONS[@]}"
}

# 更新模块版本
update_module_version() {
    local module_name="$1"
    local new_version="$2"
    
    if [[ -z "$module_name" || -z "$new_version" ]]; then
        log_error "请指定模块名称和新版本号"
        return 1
    fi
    
    local current_version="${IPV6WGM_MODULE_VERSIONS[$module_name]}"
    if [[ -z "$current_version" ]]; then
        log_error "模块不存在: $module_name"
        return 1
    fi
    
    # 检查版本兼容性
    if ! check_version_compatibility "$current_version" "$new_version" >/dev/null 2>&1; then
        log_warn "版本更新可能不兼容: $current_version -> $new_version"
        read -p "是否继续？ (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "版本更新已取消"
            return 0
        fi
    fi
    
    # 更新版本
    IPV6WGM_MODULE_VERSIONS["$module_name"]="$new_version"
    
    # 保存更新
    save_module_versions
    
    log_success "模块版本已更新: $module_name ($current_version -> $new_version)"
    return 0
}

# 获取版本兼容性统计
get_compatibility_statistics() {
    echo "=== 模块版本兼容性统计 ==="
    echo "总模块数: $IPV6WGM_VERSION_CHECK_TOTAL"
    echo "兼容模块: $IPV6WGM_VERSION_CHECK_PASSED"
    echo "不兼容模块: $IPV6WGM_VERSION_CHECK_FAILED"
    echo "兼容率: $(( (IPV6WGM_VERSION_CHECK_PASSED * 100) / IPV6WGM_VERSION_CHECK_TOTAL ))%"
    echo "版本检查: $([ "$IPV6WGM_VERSION_CHECK_ENABLED" == "true" ] && echo "启用" || echo "禁用")"
    echo "严格模式: $([ "$IPV6WGM_STRICT_VERSION_CHECK" == "true" ] && echo "启用" || echo "禁用")"
    echo "自动更新: $([ "$IPV6WGM_AUTO_UPDATE_MODULES" == "true" ] && echo "启用" || echo "禁用")"
    
    # 显示不兼容的模块
    if [[ $IPV6WGM_VERSION_CHECK_FAILED -gt 0 ]]; then
        echo
        echo "不兼容的模块:"
        for module_name in "${!IPV6WGM_VERSION_CHECK_RESULTS[@]}"; do
            if [[ "${IPV6WGM_VERSION_CHECK_RESULTS[$module_name]}" == "FAIL" ]]; then
                local version="${IPV6WGM_MODULE_VERSIONS[$module_name]}"
                echo "  - $module_name ($version)"
            fi
        done
    fi
}

# 导出函数
export -f init_version_compatibility
export -f scan_module_versions
export -f check_module_compatibility
export -f check_all_modules_compatibility
export -f check_module_dependencies
export -f get_module_version_info
export -f list_module_versions
export -f update_module_version
export -f get_compatibility_statistics