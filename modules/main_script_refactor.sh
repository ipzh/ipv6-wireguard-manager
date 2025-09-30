#!/bin/bash

# 主脚本重构模块
# 提供主脚本的结构化重构和功能分离

# =============================================================================
# 主脚本结构定义
# =============================================================================

# 脚本阶段定义
declare -A IPV6WGM_SCRIPT_PHASES=(
    ["init"]="初始化阶段"
    ["load_modules"]="模块加载阶段"
    ["parse_args"]="参数解析阶段"
    ["validate_env"]="环境验证阶段"
    ["execute_main"]="主执行阶段"
    ["cleanup"]="清理阶段"
)

# 功能模块映射
declare -A IPV6WGM_FUNCTION_MODULES=(
    ["install_dependencies"]="system_detection"
    ["configure_wireguard"]="wireguard_config"
    ["configure_bgp"]="bird_config"
    ["setup_web_interface"]="web_management"
    ["manage_clients"]="client_management"
    ["monitor_system"]="system_monitoring"
    ["backup_restore"]="backup_restore"
)

# =============================================================================
# 主脚本重构函数
# =============================================================================

# 初始化主脚本
init_main_script() {
    local script_name="$1"
    local version="${2:-1.0.0}"
    
    log_info "初始化主脚本: $script_name v$version"
    
    # 设置脚本元数据
    set_variable "IPV6WGM_SCRIPT_NAME" "$script_name" "true"
    set_variable "IPV6WGM_SCRIPT_VERSION" "$version" "true"
    set_variable "IPV6WGM_SCRIPT_START_TIME" "$(date +%s)" "true"
    
    # 初始化变量系统
    init_variables || {
        log_error "变量系统初始化失败"
        return 1
    }
    
    # 设置错误处理
    setup_error_handling
    
    # 设置信号处理
    setup_signal_handlers
    
    log_success "主脚本初始化完成"
    return 0
}

# 设置错误处理
setup_error_handling() {
    # 设置错误陷阱
    trap 'handle_script_error $? $LINENO' ERR
    trap 'handle_script_exit' EXIT
    
    # 设置调试模式
    if [[ "$IPV6WGM_DEBUG" == "true" ]]; then
        set -x
    fi
    
    log_debug "错误处理已设置"
}

# 设置信号处理
setup_signal_handlers() {
    # 处理中断信号
    trap 'handle_interrupt' INT TERM
    
    # 处理挂起信号
    trap 'handle_suspend' TSTP
    
    log_debug "信号处理器已设置"
}

# 处理脚本错误
handle_script_error() {
    local exit_code="$1"
    local line_number="$2"
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "脚本在第 $line_number 行发生错误，退出码: $exit_code"
        
        # 记录错误上下文
        log_error "错误上下文:"
        log_error "  脚本: $IPV6WGM_SCRIPT_NAME"
        log_error "  版本: $IPV6WGM_SCRIPT_VERSION"
        log_error "  行号: $line_number"
        log_error "  退出码: $exit_code"
        
        # 执行清理
        cleanup_script_resources
    fi
}

# 处理脚本退出
handle_script_exit() {
    local exit_code="$?"
    
    # 计算执行时间
    if [[ -n "${IPV6WGM_SCRIPT_START_TIME:-}" ]]; then
        local end_time=$(date +%s)
        local duration=$((end_time - IPV6WGM_SCRIPT_START_TIME))
        log_info "脚本执行时间: ${duration}s"
    fi
    
    # 执行清理
    cleanup_script_resources
    
    # 记录退出
    if [[ $exit_code -eq 0 ]]; then
        log_success "脚本正常退出"
    else
        log_error "脚本异常退出，退出码: $exit_code"
    fi
}

# 处理中断信号
handle_interrupt() {
    log_warn "收到中断信号，正在清理..."
    cleanup_script_resources
    exit 130
}

# 处理挂起信号
handle_suspend() {
    log_warn "脚本被挂起"
    # 可以在这里添加挂起时的处理逻辑
}

# 清理脚本资源
cleanup_script_resources() {
    log_debug "清理脚本资源..."
    
    # 清理临时文件
    if [[ -d "$IPV6WGM_TEMP_DIR" ]]; then
        rm -rf "$IPV6WGM_TEMP_DIR"/* 2>/dev/null || true
    fi
    
    # 清理缓存
    if command -v clear_cache &> /dev/null; then
        clear_cache 2>/dev/null || true
    fi
    
    # 清理函数注册
    if command -v cleanup_functions &> /dev/null; then
        cleanup_functions "$IPV6WGM_SCRIPT_NAME" 2>/dev/null || true
    fi
    
    log_debug "资源清理完成"
}

# 加载功能模块
load_function_modules() {
    local modules=("${@}")
    
    log_info "加载功能模块: ${modules[*]}"
    
    for module in "${modules[@]}"; do
        if [[ -f "$IPV6WGM_MODULES_DIR/$module.sh" ]]; then
            source "$IPV6WGM_MODULES_DIR/$module.sh" || {
                log_error "模块加载失败: $module"
                return 1
            }
            log_debug "模块已加载: $module"
        else
            log_warn "模块文件不存在: $module"
        fi
    done
    
    log_success "功能模块加载完成"
    return 0
}

# 解析命令行参数
parse_command_line_args() {
    local args=("$@")
    local parsed_args=()
    
    log_debug "解析命令行参数: ${args[*]}"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --debug)
                set_variable "IPV6WGM_DEBUG" "true" "true"
                log_info "调试模式已启用"
                ;;
            --verbose)
                set_variable "IPV6WGM_VERBOSE" "true" "true"
                log_info "详细模式已启用"
                ;;
            --dry-run)
                set_variable "IPV6WGM_DRY_RUN" "true" "true"
                log_info "试运行模式已启用"
                ;;
            --config)
                if [[ -n "$2" ]]; then
                    set_variable "IPV6WGM_CONFIG_FILE" "$2" "true"
                    shift
                else
                    log_error "--config 需要指定配置文件路径"
                    return 1
                fi
                ;;
            --log-level)
                if [[ -n "$2" ]]; then
                    set_variable "IPV6WGM_LOG_LEVEL" "$2" "true"
                    shift
                else
                    log_error "--log-level 需要指定日志级别"
                    return 1
                fi
                ;;
            -*)
                log_error "未知参数: $1"
                return 1
                ;;
            *)
                parsed_args+=("$1")
                ;;
        esac
        shift
    done
    
    # 设置解析后的参数
    set_variable "IPV6WGM_PARSED_ARGS" "$(printf '%s\n' "${parsed_args[@]}")" "true"
    
    log_success "命令行参数解析完成"
    return 0
}

# 验证执行环境
validate_execution_environment() {
    log_info "验证执行环境..."
    
    # 检查操作系统
    if ! command -v uname &> /dev/null; then
        log_error "无法检测操作系统"
        return 1
    fi
    
    # 检查必要命令
    local required_commands=("bash" "mkdir" "cp" "rm" "chmod" "chown")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "缺少必要命令: $cmd"
            return 1
        fi
    done
    
    # 检查权限
    if [[ $EUID -ne 0 ]] && [[ "$1" != "--help" ]] && [[ "$1" != "--version" ]]; then
        log_error "此脚本需要root权限运行"
        return 1
    fi
    
    # 检查磁盘空间
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then  # 1GB in KB
        log_warn "磁盘空间不足，可能影响安装"
    fi
    
    log_success "环境验证通过"
    return 0
}

# 执行主功能
execute_main_function() {
    local function_name="$1"
    local args=("${@:2}")
    
    log_info "执行主功能: $function_name"
    
    # 检查函数是否存在
    if ! command -v "$function_name" &> /dev/null; then
        log_error "函数不存在: $function_name"
        return 1
    fi
    
    # 检查函数是否已注册
    if command -v is_function_registered &> /dev/null; then
        if ! is_function_registered "$function_name"; then
            log_warn "函数未注册: $function_name"
        fi
    fi
    
    # 执行函数
    if [[ "$IPV6WGM_DRY_RUN" == "true" ]]; then
        log_info "试运行模式: 将执行 $function_name ${args[*]}"
        return 0
    fi
    
    "$function_name" "${args[@]}"
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "主功能执行完成: $function_name"
    else
        log_error "主功能执行失败: $function_name，退出码: $exit_code"
    fi
    
    return $exit_code
}

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager - 帮助信息

用法: $IPV6WGM_SCRIPT_NAME [选项] [命令]

选项:
    --help, -h          显示此帮助信息
    --version, -v       显示版本信息
    --debug             启用调试模式
    --verbose           启用详细模式
    --dry-run           试运行模式（不执行实际操作）
    --config FILE       指定配置文件
    --log-level LEVEL   设置日志级别 (DEBUG|INFO|WARN|ERROR|FATAL)

命令:
    install             安装IPv6 WireGuard Manager
    uninstall           卸载IPv6 WireGuard Manager
    start               启动服务
    stop                停止服务
    restart             重启服务
    status              查看状态
    config              配置管理
    client              客户端管理
    monitor             系统监控

示例:
    $IPV6WGM_SCRIPT_NAME install
    $IPV6WGM_SCRIPT_NAME --debug --verbose install
    $IPV6WGM_SCRIPT_NAME --config /path/to/config.conf install
    $IPV6WGM_SCRIPT_NAME --dry-run install

更多信息请访问: https://github.com/ipzh/ipv6-wireguard-manager
EOF
}

# 显示版本信息
show_version() {
    cat << EOF
IPv6 WireGuard Manager v$IPV6WGM_SCRIPT_VERSION

构建信息:
    版本: $IPV6WGM_SCRIPT_VERSION
    构建日期: $IPV6WGM_BUILD_DATE
    架构: $IPV6WGM_ARCH
    操作系统: $IPV6WGM_OS_TYPE

版权所有 (c) 2025 IPv6 WireGuard Manager Team
许可证: MIT License
EOF
}

# 导出函数
export -f init_main_script
export -f setup_error_handling
export -f setup_signal_handlers
export -f handle_script_error
export -f handle_script_exit
export -f handle_interrupt
export -f handle_suspend
export -f cleanup_script_resources
export -f load_function_modules
export -f parse_command_line_args
export -f validate_execution_environment
export -f execute_main_function
export -f show_help
export -f show_version
