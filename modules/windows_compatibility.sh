#!/bin/bash

# Windows兼容性模块
# 提供Windows环境检测、适配和兼容性测试功能

# ================================================================
# Windows环境检测和适配
# ================================================================

# 检测Windows环境
check_windows_environment() {
    # 使用统一的Windows环境检测
    if detect_unified_windows_env; then
        log_info "检测到Windows环境: $IPV6WGM_WINDOWS_ENV_TYPE"
        return 0
    else
        log_info "检测到Linux环境"
        return 1
    fi
}

# 路径转换函数
convert_path() {
    local path="$1"
    
    # 使用统一的路径转换函数
    convert_unified_path "$path"
}

# 命令别名设置
setup_windows_aliases() {
    case "${IPV6WGM_WINDOWS_ENV_TYPE:-linux}" in
        "windows")
            # Windows CMD/PowerShell环境
            if ! command -v ip &> /dev/null && command -v ipconfig &> /dev/null; then
                alias ip='ipconfig'
            fi
            
            if ! command -v free &> /dev/null && command -v wmic &> /dev/null; then
                alias free='wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value'
            fi
            
            if ! command -v ps &> /dev/null && command -v tasklist &> /dev/null; then
                alias ps='tasklist'
            fi
            ;;
        "msys"|"cygwin"|"gitbash")
            # MSYS/Cygwin环境
            if ! command -v ip &> /dev/null && command -v ipconfig &> /dev/null; then
                alias ip='ipconfig'
            fi
            ;;
    esac
}

# ================================================================
# Windows兼容性语法检查
# ================================================================

# 运行Windows兼容性语法检查
run_windows_compatible_syntax_check() {
    log_info "运行Windows兼容性语法检查..."
    local syntax_errors=0
    
    # 检查Windows不兼容的命令
    local incompatible_commands=(
        "stat -c" "ip link" "ip route" "free -m"
        "bc -l" "grep -q" "awk" "sed -i"
        "systemctl" "service" "chmod" "chown"
    )
    
    for cmd in "${incompatible_commands[@]}"; do
        if grep -r "$cmd" "$PROJECT_ROOT" --include="*.sh" >/dev/null 2>&1; then
            log_warn "发现Windows不兼容命令: $cmd"
            syntax_errors=$((syntax_errors + 1))
        fi
    done
    
    # 检查Linux特有的文件路径
    local linux_paths=(
        "/etc/" "/var/" "/usr/" "/opt/"
        "/sys/" "/proc/" "/dev/"
    )
    
    for path in "${linux_paths[@]}"; do
        if grep -r "$path" "$PROJECT_ROOT" --include="*.sh" >/dev/null 2>&1; then
            log_warn "发现Linux特有路径: $path"
            syntax_errors=$((syntax_errors + 1))
        fi
    done
    
    # 检查权限相关命令
    local permission_commands=(
        "chmod" "chown" "chgrp" "umask"
        "su " "sudo " "runuser"
    )
    
    for cmd in "${permission_commands[@]}"; do
        if grep -r "$cmd" "$PROJECT_ROOT" --include="*.sh" >/dev/null 2>&1; then
            log_warn "发现权限相关命令: $cmd"
            syntax_errors=$((syntax_errors + 1))
        fi
    done
    
    if [[ $syntax_errors -eq 0 ]]; then
        log_success "Windows兼容性语法检查通过"
        return 0
    else
        log_error "发现 $syntax_errors 个Windows兼容性问题"
        return 1
    fi
}

# 检查配置文件语法
check_config_syntax() {
    local config_file="$1"
    local syntax_errors=0
    
    if [[ ! -f "$config_file" ]]; then
        log_warn "配置文件不存在: $config_file"
        return 1
    fi
    
    # 检查YAML语法
    if [[ "$config_file" == *.yml ]] || [[ "$config_file" == *.yaml ]]; then
        if command -v yamllint &> /dev/null; then
            if ! yamllint "$config_file" >/dev/null 2>&1; then
                log_error "YAML语法错误: $config_file"
                syntax_errors=$((syntax_errors + 1))
            fi
        else
            log_warn "yamllint未安装，跳过YAML语法检查"
        fi
    fi
    
    # 检查WireGuard配置语法
    if [[ "$config_file" == *.conf ]] && grep -q "\[Interface\]" "$config_file"; then
        if ! validate_wireguard_config "$config_file"; then
            log_error "WireGuard配置语法错误: $config_file"
            syntax_errors=$((syntax_errors + 1))
        fi
    fi
    
    # 检查BIRD配置语法
    if [[ "$config_file" == *.conf ]] && grep -q "router id" "$config_file"; then
        if command -v birdc &> /dev/null; then
            if ! birdc -p -c "$config_file" >/dev/null 2>&1; then
                log_error "BIRD配置语法错误: $config_file"
                syntax_errors=$((syntax_errors + 1))
            fi
        else
            log_warn "birdc未安装，跳过BIRD配置检查"
        fi
    fi
    
    return $syntax_errors
}

# 验证WireGuard配置
validate_wireguard_config() {
    local config_file="$1"
    
    # 检查必要的节
    if ! grep -q "\[Interface\]" "$config_file"; then
        log_error "缺少[Interface]节"
        return 1
    fi
    
    # 检查接口配置
    local interface_section=false
    while IFS= read -r line; do
        if [[ "$line" == "[Interface]" ]]; then
            interface_section=true
            continue
        elif [[ "$line" == "["* ]]; then
            interface_section=false
            continue
        fi
        
        if [[ "$interface_section" == true ]]; then
            case "$line" in
                "PrivateKey="*)
                    if [[ ${#line} -lt 50 ]]; then
                        log_error "PrivateKey长度不足"
                        return 1
                    fi
                    ;;
                "Address="*)
                    if ! validate_ip_address "${line#Address=}"; then
                        log_error "无效的Address: ${line#Address=}"
                        return 1
                    fi
                    ;;
            esac
        fi
    done < "$config_file"
    
    return 0
}

# 验证IP地址
validate_ip_address() {
    local ip="$1"
    
    # 简单的IP地址验证
    if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 0
    elif [[ "$ip" =~ ^[0-9a-fA-F:]+/[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# ================================================================
# Windows环境适配函数
# ================================================================

# 获取系统信息（Windows兼容）
get_system_info() {
    case "${IPV6WGM_WINDOWS_ENV_TYPE:-linux}" in
        "windows")
            echo "操作系统: Windows"
            if command -v systeminfo &> /dev/null; then
                systeminfo | grep "OS Name" | head -1
                systeminfo | grep "OS Version" | head -1
            fi
            ;;
        "wsl")
            echo "操作系统: WSL ($(uname -s))"
            uname -a
            ;;
        "msys"|"cygwin"|"gitbash")
            echo "操作系统: $OSTYPE"
            uname -a
            ;;
        *)
            echo "操作系统: $(uname -s)"
            uname -a
            ;;
    esac
}

# 获取网络信息（Windows兼容）
get_network_info() {
    case "${IPV6WGM_WINDOWS_ENV_TYPE:-linux}" in
        "windows")
            if command -v ipconfig &> /dev/null; then
                ipconfig
            else
                echo "无法获取网络信息"
            fi
            ;;
        *)
            if command -v ip &> /dev/null; then
                ip addr show
            elif command -v ifconfig &> /dev/null; then
                ifconfig
            else
                echo "无法获取网络信息"
            fi
            ;;
    esac
}

# 获取内存信息（Windows兼容）
get_memory_info() {
    case "${IPV6WGM_WINDOWS_ENV_TYPE:-linux}" in
        "windows")
            if command -v wmic &> /dev/null; then
                wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /Value
            else
                echo "无法获取内存信息"
            fi
            ;;
        *)
            if command -v free &> /dev/null; then
                free -h
            else
                echo "无法获取内存信息"
            fi
            ;;
    esac
}

# 获取进程信息（Windows兼容）
get_process_info() {
    case "${IPV6WGM_WINDOWS_ENV_TYPE:-linux}" in
        "windows")
            if command -v tasklist &> /dev/null; then
                tasklist
            else
                echo "无法获取进程信息"
            fi
            ;;
        *)
            if command -v ps &> /dev/null; then
                ps aux
            else
                echo "无法获取进程信息"
            fi
            ;;
    esac
}

# ================================================================
# 测试函数
# ================================================================

# 测试Windows兼容性
test_windows_compatibility() {
    log_info "开始Windows兼容性测试..."
    
    # 测试环境检测
    if check_windows_environment; then
        log_success "✓ Windows环境检测成功"
    else
        log_info "当前环境: ${IPV6WGM_WINDOWS_ENV_TYPE:-linux}"
    fi
    
    # 测试路径转换
    local test_path="/etc/test/path"
    local converted_path=$(convert_path "$test_path")
    log_info "路径转换测试: $test_path -> $converted_path"
    
    # 测试命令别名
    setup_windows_aliases
    log_info "Windows命令别名已设置"
    
    # 测试系统信息获取
    log_info "系统信息:"
    get_system_info
    
    # 测试网络信息获取
    log_info "网络信息:"
    get_network_info | head -5
    
    # 测试内存信息获取
    log_info "内存信息:"
    get_memory_info | head -3
    
    log_success "Windows兼容性测试完成"
}

# ================================================================
# 导出函数
# ================================================================

export -f check_windows_environment convert_path setup_windows_aliases
export -f run_windows_compatible_syntax_check check_config_syntax
export -f validate_wireguard_config validate_ip_address
export -f get_system_info get_network_info get_memory_info get_process_info
export -f test_windows_compatibility