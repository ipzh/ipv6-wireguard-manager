#!/bin/bash

# 增强的模块加载系统
# 实现智能模块依赖管理和懒加载机制

# =============================================================================
# 模块依赖关系管理
# =============================================================================

# 模块依赖关系图 - 完善版本
declare -A MODULE_DEPENDENCIES=(
    ["common_functions"]=""
    ["variable_management"]="common_functions"
    ["function_management"]="common_functions variable_management"
    ["main_script_refactor"]="common_functions variable_management function_management"
    ["unified_config"]="common_functions variable_management"
    ["unified_config_manager"]="common_functions enhanced_security_functions"
    ["error_handling"]="common_functions variable_management"
    ["enhanced_error_handling"]="common_functions error_handling"
    ["unified_error_handling"]="common_functions error_handling enhanced_error_handling"
    ["system_detection"]="common_functions variable_management"
    ["function_optimizer"]="common_functions function_management"
    ["wireguard_config"]="common_functions unified_config system_detection enhanced_security_functions"
    ["bird_config"]="common_functions unified_config system_detection"
    ["web_management"]="common_functions unified_config error_handling enhanced_security_functions"
    ["firewall_management"]="common_functions unified_config system_detection"
    ["client_management"]="common_functions unified_config wireguard_config enhanced_security_functions"
    ["backup_restore"]="common_functions unified_config enhanced_security_functions"
    ["system_monitoring"]="common_functions unified_config"
    ["resource_monitoring"]="common_functions system_monitoring"
    ["self_diagnosis"]="common_functions unified_config system_monitoring"
    ["lazy_loading"]="common_functions"
    ["version_control"]="common_functions"
    ["enhanced_module_loader"]="common_functions function_management"
    ["oauth_authentication"]="common_functions unified_config error_handling enhanced_security_functions"
    ["security_functions"]="common_functions unified_config"
    ["enhanced_security_functions"]="common_functions"
    ["security_audit_monitoring"]="common_functions security_functions enhanced_security_functions"
    ["smart_caching"]="common_functions"
    ["unified_test_framework"]="common_functions"
    ["advanced_performance_optimization"]="common_functions smart_caching"
    ["config_hot_reload"]="common_functions unified_config unified_config_manager"
    ["user_interface"]="common_functions"
    ["update_management"]="common_functions unified_config enhanced_security_functions"
    ["network_management"]="common_functions unified_config system_detection enhanced_security_functions"
    ["network_topology"]="common_functions network_management"
    ["multi_tenant"]="common_functions unified_config enhanced_security_functions oauth_authentication"
    ["websocket_realtime"]="common_functions web_management"
    ["web_interface_enhanced"]="common_functions web_management enhanced_security_functions"
    ["monitoring_alerting"]="common_functions system_monitoring enhanced_security_functions"
    ["hardware_compatibility"]="common_functions system_detection"
    ["windows_compatibility"]="common_functions system_detection"
    ["unified_windows_compatibility"]="common_functions windows_compatibility"
)

# 模块版本信息
declare -A MODULE_VERSIONS=(
    ["common_functions"]="1.2.0"
    ["variable_management"]="1.0.0"
    ["function_management"]="1.0.0"
    ["main_script_refactor"]="1.0.0"
    ["unified_config"]="1.1.0"
    ["error_handling"]="1.0.0"
    ["enhanced_error_handling"]="1.0.0"
    ["unified_error_handling"]="1.0.0"
    ["system_detection"]="1.0.0"
    ["function_optimizer"]="1.0.0"
    ["wireguard_config"]="1.0.0"
    ["bird_config"]="1.0.0"
    ["web_management"]="1.1.0"
    ["firewall_management"]="1.0.0"
    ["client_management"]="1.0.0"
    ["backup_restore"]="1.0.0"
    ["system_monitoring"]="1.0.0"
    ["resource_monitoring"]="1.1.0"
    ["self_diagnosis"]="1.0.0"
    ["lazy_loading"]="1.0.0"
    ["version_control"]="1.0.0"
    ["enhanced_module_loader"]="1.1.0"
    ["oauth_authentication"]="1.0.0"
    ["security_functions"]="1.0.0"
    ["security_audit_monitoring"]="1.0.0"
    ["smart_caching"]="1.0.0"
    ["unified_test_framework"]="1.0.0"
    ["advanced_performance_optimization"]="1.0.0"
    ["config_hot_reload"]="1.0.0"
    ["user_interface"]="1.0.0"
    ["update_management"]="1.0.0"
)

# 模块加载状态
declare -A MODULE_LOAD_STATES=(
    ["unloaded"]="未加载"
    ["loading"]="加载中"
    ["loaded"]="已加载"
    ["failed"]="加载失败"
    ["deprecated"]="已废弃"
)

# 已加载模块记录
declare -A LOADED_MODULES
declare -A MODULE_LOAD_TIMES
declare -A MODULE_LOAD_COUNTS

# 模块加载统计
declare -g TOTAL_MODULE_LOADS=0
declare -g TOTAL_MODULE_LOAD_TIME=0

# =============================================================================
# 核心模块加载函数
# =============================================================================

# 智能模块加载函数
load_module_smart() {
    local module_name="$1"
    local force_reload="${2:-false}"
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # 检查模块是否已加载
    if [[ -n "${LOADED_MODULES[$module_name]}" && "$force_reload" != "true" ]]; then
        log_debug "模块 '$module_name' 已加载，跳过"
        return 0
    fi
    
    # 检查模块版本兼容性
    if ! check_module_version_compatibility "$module_name"; then
        log_error "模块 '$module_name' 版本不兼容"
        return 1
    fi
    
    # 检查模块依赖
    if [[ -n "${MODULE_DEPENDENCIES[$module_name]}" ]]; then
        for dep in ${MODULE_DEPENDENCIES[$module_name]}; do
            if [[ -n "$dep" ]]; then
                log_debug "加载模块 '$module_name' 的依赖: '$dep'"
                if ! load_module_smart "$dep" "$force_reload"; then
                    log_error "无法加载模块 '$module_name' 的依赖 '$dep'"
                    return 1
                fi
            fi
        done
    fi
    
    # 查找模块文件 - 优化路径查找顺序
    local module_path=""
    local search_paths=(
        "$IPV6WGM_MODULES_DIR/${module_name}.sh"                    # 首选：环境变量定义的路径
        "${SCRIPT_DIR}/modules/${module_name}.sh"                   # 相对于脚本目录
        "$(pwd)/modules/${module_name}.sh"                          # 相对于当前工作目录
        "$(dirname "${BASH_SOURCE[0]}")/${module_name}.sh"          # 相对于当前模块目录
        "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"     # 标准安装路径（仅Linux）
        "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"  # 系统级安装路径（仅Linux）
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            module_path="$path"
            break
        fi
    done
    
    if [[ -z "$module_path" ]]; then
        log_error "无法找到模块文件: $module_name"
        return 1
    fi
    
    # 加载模块
    log_debug "加载模块: $module_name (文件: $module_path, 版本: ${MODULE_VERSIONS[$module_name]})"
    
    # 记录加载前状态
    local functions_before=$(declare -F | wc -l)
    
    if source "$module_path"; then
        # 记录加载后状态
        local functions_after=$(declare -F | wc -l)
        local functions_added=$((functions_after - functions_before))
        
        # 更新加载记录
        LOADED_MODULES[$module_name]=1
        MODULE_LOAD_TIMES[$module_name]=$(date +%s%3N 2>/dev/null || date +%s)
        MODULE_LOAD_COUNTS[$module_name]=$((${MODULE_LOAD_COUNTS[$module_name]:-0} + 1))
        
        # 更新统计
        TOTAL_MODULE_LOADS=$((TOTAL_MODULE_LOADS + 1))
        local load_time=$(($(date +%s%3N 2>/dev/null || date +%s) - start_time))
        TOTAL_MODULE_LOAD_TIME=$((TOTAL_MODULE_LOAD_TIME + load_time))
        
        log_success "模块 '$module_name' 加载成功 (版本: ${MODULE_VERSIONS[$module_name]}, 新增函数: $functions_added, 耗时: ${load_time}ms)"
        return 0
    else
        log_error "模块 '$module_name' 加载失败"
        return 1
    fi
}

# 检查模块版本兼容性
check_module_version_compatibility() {
    local module_name="$1"
    local required_version="${MODULE_VERSIONS[$module_name]}"
    
    if [[ -z "$required_version" ]]; then
        log_warn "模块 '$module_name' 没有版本信息"
        return 0
    fi
    
    # 检查核心模块版本
    if [[ "$module_name" == "common_functions" ]]; then
        local current_version="1.2.0"
        if ! compare_versions "$current_version" "$required_version"; then
            log_error "核心模块版本不匹配: 当前 $current_version, 需要 $required_version"
            return 1
        fi
    fi
    
    return 0
}

# 版本比较函数
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # 简单的版本比较 (支持 x.y.z 格式)
    local IFS='.'
    local -a v1=($version1)
    local -a v2=($version2)
    
    for i in {0..2}; do
        local num1=${v1[$i]:-0}
        local num2=${v2[$i]:-0}
        
        if [[ $num1 -gt $num2 ]]; then
            return 0
        elif [[ $num1 -lt $num2 ]]; then
            return 1
        fi
    done
    
    return 0
}

# 懒加载模块函数
lazy_load_module() {
    local module_name="$1"
    local function_name="$2"
    
    # 检查函数是否已存在
    if declare -f "$function_name" >/dev/null 2>&1; then
        return 0
    fi
    
    # 懒加载模块
    if load_module_smart "$module_name"; then
        # 检查函数是否现在存在
        if declare -f "$function_name" >/dev/null 2>&1; then
            log_debug "懒加载成功: $function_name 来自模块 $module_name"
            return 0
        else
            log_warn "模块 $module_name 加载成功，但函数 $function_name 不存在"
            return 1
        fi
    else
        log_error "懒加载失败: 无法加载模块 $module_name"
        return 1
    fi
}

# 批量加载模块
load_modules_batch() {
    local modules=("$@")
    local success_count=0
    local failed_count=0
    
    log_info "开始批量加载模块: ${modules[*]}"
    
    for module in "${modules[@]}"; do
        if load_module_smart "$module"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    log_info "批量加载完成: 成功 $success_count, 失败 $failed_count"
    
    if [[ $failed_count -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# 模块管理函数
# =============================================================================

# 列出已加载模块
list_loaded_modules() {
    log_info "已加载模块列表:"
    for module in "${!LOADED_MODULES[@]}"; do
        local load_time="${MODULE_LOAD_TIMES[$module]:-未知}"
        local load_count="${MODULE_LOAD_COUNTS[$module]:-0}"
        log_info "- $module (加载时间: $load_time, 加载次数: $load_count)"
    done
}

# 获取模块统计信息
get_module_stats() {
    local total_modules=${#LOADED_MODULES[@]}
    local avg_load_time=0
    
    if [[ $TOTAL_MODULE_LOADS -gt 0 ]]; then
        avg_load_time=$((TOTAL_MODULE_LOAD_TIME / TOTAL_MODULE_LOADS))
    fi
    
    echo "模块统计信息:"
    echo "- 已加载模块数: $total_modules"
    echo "- 总加载次数: $TOTAL_MODULE_LOADS"
    echo "- 平均加载时间: ${avg_load_time}ms"
    echo "- 总加载时间: ${TOTAL_MODULE_LOAD_TIME}ms"
}

# 检查模块依赖
check_module_dependencies() {
    local module_name="$1"
    
    if [[ -z "${MODULE_DEPENDENCIES[$module_name]}" ]]; then
        log_info "模块 '$module_name' 没有依赖"
        return 0
    fi
    
    log_info "模块 '$module_name' 的依赖关系:"
    for dep in ${MODULE_DEPENDENCIES[$module_name]}; do
        if [[ -n "$dep" ]]; then
            if [[ -n "${LOADED_MODULES[$dep]}" ]]; then
                log_success "- $dep (已加载)"
            else
                log_warn "- $dep (未加载)"
            fi
        fi
    done
}

# 卸载模块（实验性功能）
unload_module() {
    local module_name="$1"
    
    if [[ -z "${LOADED_MODULES[$module_name]}" ]]; then
        log_warn "模块 '$module_name' 未加载"
        return 1
    fi
    
    # 注意：在bash中完全卸载模块是困难的，这里只是标记为未加载
    unset LOADED_MODULES[$module_name]
    unset MODULE_LOAD_TIMES[$module_name]
    unset MODULE_LOAD_COUNTS[$module_name]
    
    log_info "模块 '$module_name' 已标记为卸载"
    return 0
}

# 清理模块缓存
clear_module_cache() {
    LOADED_MODULES=()
    MODULE_LOAD_TIMES=()
    MODULE_LOAD_COUNTS=()
    TOTAL_MODULE_LOADS=0
    TOTAL_MODULE_LOAD_TIME=0
    
    log_info "模块缓存已清理"
}

# =============================================================================
# 性能优化函数
# =============================================================================

# 预加载核心模块
preload_core_modules() {
    local core_modules=("common_functions" "unified_config" "error_handling")
    
    log_info "预加载核心模块..."
    load_modules_batch "${core_modules[@]}"
}

# 按需加载模块
load_module_on_demand() {
    local function_name="$1"
    local module_name="$2"
    
    # 检查函数是否已存在
    if declare -f "$function_name" >/dev/null 2>&1; then
        return 0
    fi
    
    # 如果指定了模块名，直接加载
    if [[ -n "$module_name" ]]; then
        lazy_load_module "$module_name" "$function_name"
        return $?
    fi
    
    # 否则尝试从所有模块中查找
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        if load_module_smart "$module" 2>/dev/null; then
            if declare -f "$function_name" >/dev/null 2>&1; then
                log_debug "按需加载成功: $function_name 来自模块 $module"
                return 0
            fi
        fi
    done
    
    log_error "无法找到函数: $function_name"
    return 1
}

# =============================================================================
# 依赖冲突检测和循环依赖预防
# =============================================================================

# 检测循环依赖
detect_circular_dependencies() {
    local module="$1"
    local visited=()
    local recursion_stack=()
    
    # 深度优先搜索检测循环
    local function detect_cycle() {
        local current_module="$1"
        local current_path="$2"
        
        # 检查是否已经在当前路径中（循环依赖）
        if [[ "$current_path" == *"$current_module"* ]]; then
            echo "检测到循环依赖: $current_path -> $current_module"
            return 1
        fi
        
        # 检查是否已经访问过
        if [[ " ${visited[@]} " =~ " $current_module " ]]; then
            return 0
        fi
        
        # 标记为已访问
        visited+=("$current_module")
        
        # 获取依赖
        local dependencies="${MODULE_DEPENDENCIES[$current_module]:-}"
        if [[ -z "$dependencies" ]]; then
            return 0
        fi
        
        # 递归检查每个依赖
        for dep in $dependencies; do
            local new_path="$current_path -> $current_module"
            if ! detect_cycle "$dep" "$new_path"; then
                return 1
            fi
        done
        
        return 0
    }
    
    detect_cycle "$module" ""
    return $?
}

# 检测依赖冲突
detect_dependency_conflicts() {
    local conflicts=()
    local conflict_count=0
    
    echo "检查模块依赖冲突..."
    
    # 检查每个模块的依赖关系
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        local dependencies="${MODULE_DEPENDENCIES[$module]:-}"
        
        if [[ -n "$dependencies" ]]; then
            # 检查循环依赖
            if ! detect_circular_dependencies "$module"; then
                conflicts+=("$module: 循环依赖")
                ((conflict_count++))
            fi
            
            # 检查版本冲突
            local module_version="${MODULE_VERSIONS[$module]:-unknown}"
            for dep in $dependencies; do
                local dep_version="${MODULE_VERSIONS[$dep]:-unknown}"
                
                # 检查版本兼容性（简化版本检查）
                if [[ "$module_version" != "unknown" && "$dep_version" != "unknown" ]]; then
                    local module_major=$(echo "$module_version" | cut -d. -f1)
                    local dep_major=$(echo "$dep_version" | cut -d. -f1)
                    
                    if [[ $module_major -lt $dep_major ]]; then
                        conflicts+=("$module: 版本不兼容 (需要 $dep >= $dep_version)")
                        ((conflict_count++))
                    fi
                fi
            done
        fi
    done
    
    # 输出冲突报告
    if [[ $conflict_count -gt 0 ]]; then
        echo "发现 $conflict_count 个依赖冲突:"
        for conflict in "${conflicts[@]}"; do
            echo "  - $conflict"
        done
        return 1
    else
        echo "未发现依赖冲突"
        return 0
    fi
}

# 解决依赖冲突
resolve_dependency_conflicts() {
    echo -e "${SECONDARY_COLOR}=== 解决依赖冲突 ===${NC}"
    echo
    
    # 检测冲突
    if detect_dependency_conflicts; then
        show_success "所有依赖冲突已解决"
        return 0
    fi
    
    echo "尝试自动解决冲突..."
    
    # 重新排序模块加载顺序
    local sorted_modules=()
    local remaining_modules=("${!MODULE_DEPENDENCIES[@]}")
    
    # 拓扑排序
    while [[ ${#remaining_modules[@]} -gt 0 ]]; do
        local added=false
        
        for i in "${!remaining_modules[@]}"; do
            local module="${remaining_modules[$i]}"
            local dependencies="${MODULE_DEPENDENCIES[$module]:-}"
            local can_add=true
            
            # 检查所有依赖是否已排序
            for dep in $dependencies; do
                if [[ ! " ${sorted_modules[@]} " =~ " $dep " ]]; then
                    can_add=false
                    break
                fi
            done
            
            if [[ "$can_add" == "true" ]]; then
                sorted_modules+=("$module")
                unset remaining_modules[$i]
                remaining_modules=("${remaining_modules[@]}")  # 重新索引
                added=true
                break
            fi
        done
        
        if [[ "$added" == "false" ]]; then
            echo "无法解决循环依赖，请手动修复"
            return 1
        fi
    done
    
    echo "建议的模块加载顺序:"
    for i in "${!sorted_modules[@]}"; do
        echo "  $((i+1)). ${sorted_modules[$i]}"
    done
    
    show_success "依赖冲突解决建议已生成"
}

# 验证模块完整性
validate_module_integrity() {
    local module="$1"
    local issues=()
    
    echo "验证模块完整性: $module"
    
    # 检查模块文件是否存在
    local module_file="${MODULES_DIR}/${module}.sh"
    if [[ ! -f "$module_file" ]]; then
        issues+=("模块文件不存在: $module_file")
    fi
    
    # 检查依赖模块是否存在
    local dependencies="${MODULE_DEPENDENCIES[$module]:-}"
    for dep in $dependencies; do
        local dep_file="${MODULES_DIR}/${dep}.sh"
        if [[ ! -f "$dep_file" ]]; then
            issues+=("依赖模块文件不存在: $dep_file")
        fi
    done
    
    # 检查版本信息
    local version="${MODULE_VERSIONS[$module]:-}"
    if [[ -z "$version" ]]; then
        issues+=("缺少版本信息")
    fi
    
    # 输出验证结果
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "发现以下问题:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
        return 1
    else
        echo "模块完整性验证通过"
        return 0
    fi
}

# 批量验证所有模块
validate_all_modules() {
    echo -e "${SECONDARY_COLOR}=== 批量验证所有模块 ===${NC}"
    echo
    
    local total_modules=0
    local valid_modules=0
    local invalid_modules=0
    
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        ((total_modules++))
        
        if validate_module_integrity "$module"; then
            ((valid_modules++))
        else
            ((invalid_modules++))
        fi
        echo
    done
    
    echo "验证结果汇总:"
    echo "  总模块数: $total_modules"
    echo "  有效模块: $valid_modules"
    echo "  无效模块: $invalid_modules"
    
    if [[ $invalid_modules -eq 0 ]]; then
        show_success "所有模块验证通过"
        return 0
    else
        show_warn "发现 $invalid_modules 个模块存在问题"
        return 1
    fi
}

# 生成依赖关系图
generate_dependency_graph() {
    local output_file="${CONFIG_DIR}/dependency_graph.dot"
    
    echo "生成依赖关系图: $output_file"
    
    cat > "$output_file" << 'EOF'
digraph ModuleDependencies {
    rankdir=TB;
    node [shape=box, style=filled, fillcolor=lightblue];
    edge [color=gray];
EOF
    
    # 添加节点
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        local version="${MODULE_VERSIONS[$module]:-unknown}"
        echo "    \"$module\" [label=\"$module\\n$version\"];" >> "$output_file"
    done
    
    # 添加边
    for module in "${!MODULE_DEPENDENCIES[@]}"; do
        local dependencies="${MODULE_DEPENDENCIES[$module]:-}"
        for dep in $dependencies; do
            echo "    \"$module\" -> \"$dep\";" >> "$output_file"
        done
    done
    
    echo "}" >> "$output_file"
    
    show_success "依赖关系图已生成: $output_file"
    echo "可以使用 Graphviz 工具查看: dot -Tpng $output_file -o dependency_graph.png"
}

# 模块依赖管理菜单
dependency_management_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 模块依赖管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 检测循环依赖"
        echo -e "${GREEN}2.${NC} 检测依赖冲突"
        echo -e "${GREEN}3.${NC} 解决依赖冲突"
        echo -e "${GREEN}4.${NC} 验证模块完整性"
        echo -e "${GREEN}5.${NC} 批量验证所有模块"
        echo -e "${GREEN}6.${NC} 生成依赖关系图"
        echo -e "${GREEN}7.${NC} 查看模块统计"
        echo -e "${GREEN}8.${NC} 重新加载所有模块"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-8]: " choice
        
        case $choice in
            1) 
                echo "检测循环依赖..."
                for module in "${!MODULE_DEPENDENCIES[@]}"; do
                    if ! detect_circular_dependencies "$module"; then
                        echo "发现循环依赖"
                    fi
                done
                ;;
            2) detect_dependency_conflicts ;;
            3) resolve_dependency_conflicts ;;
            4) 
                local module=$(show_input "输入模块名" "")
                if [[ -n "$module" ]]; then
                    validate_module_integrity "$module"
                fi
                ;;
            5) validate_all_modules ;;
            6) generate_dependency_graph ;;
            7) get_module_stats ;;
            8) 
                echo "重新加载所有模块..."
                clear_module_cache
                preload_core_modules
                ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 智能模块加载（增强版）
load_module_smart_enhanced() {
    local module_name="$1"
    local force_reload="${2:-false}"
    
    # 验证模块完整性
    if ! validate_module_integrity "$module_name" >/dev/null 2>&1; then
        log_error "模块完整性验证失败: $module_name"
        return 1
    fi
    
    # 检测循环依赖
    if ! detect_circular_dependencies "$module_name" >/dev/null 2>&1; then
        log_error "检测到循环依赖: $module_name"
        return 1
    fi
    
    # 使用原有的智能加载逻辑
    load_module_smart "$module_name" "$force_reload"
    return $?
}

# 导出函数
export -f load_module_smart lazy_load_module load_modules_batch
export -f list_loaded_modules get_module_stats check_module_dependencies
export -f unload_module clear_module_cache preload_core_modules load_module_on_demand
export -f detect_circular_dependencies detect_dependency_conflicts resolve_dependency_conflicts
export -f validate_module_integrity validate_all_modules generate_dependency_graph
export -f dependency_management_menu load_module_smart_enhanced
