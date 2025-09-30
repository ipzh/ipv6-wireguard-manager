#!/bin/bash

# Root权限检查测试脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
# CYAN='\033[0;36m'  # 未使用的变量
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 测试用例1: 验证权限检测功能
function test_permission_detection() {
    echo "测试1: 验证权限检测功能"
    # 检测当前用户ID
    local user_id
    user_id=$(id -u 2>/dev/null || echo "unknown")
    
    if [[ "$user_id" == "0" ]]; then
        log_success "当前用户是root用户"
        return 0
    elif [[ "$user_id" == "unknown" ]]; then
        log_warn "无法确定用户权限 (Windows环境)"
        return 1
    else
        log_success "当前用户是非root用户 (UID: $user_id)"
        return 0
    fi
}

# 测试用例2: 模拟权限不足场景
function test_permission_denied() {
    echo "测试2: 模拟权限不足场景"
    local test_file="/root/test_permission.txt"
    
    # 尝试在root目录创建文件
    if touch "$test_file" 2>/dev/null; then
        log_warn "警告: 非root用户能够在/root目录创建文件"
        rm -f "$test_file" 2>/dev/null
        return 1
    else
        log_success "权限不足: 无法在/root目录创建文件"
        return 0
    fi
}

# 测试用例3: 验证错误处理机制
function test_error_handling() {
    echo "测试3: 验证错误处理机制"
    # 检查是否有合适的错误消息和退出码
    local output
    output=$(bash -c "if [[ \$EUID -ne 0 ]]; then echo '需要root权限'; exit 1; fi" 2>&1)
    local exit_code=$?
    
    if [[ "$output" == "需要root权限" && $exit_code -eq 1 ]]; then
        log_success "错误处理机制正常工作"
        return 0
    else
        log_error "错误处理机制存在问题"
        log_debug "输出: $output"
        log_debug "退出码: $exit_code"
        return 1
    fi
}

# 测试用例4: 验证EUID检查
function test_euid_check() {
    echo "测试4: 验证EUID检查"
    
    # 测试EUID检查逻辑
    local euid_check_output
    euid_check_output=$(bash -c 'if [[ $EUID -ne 0 ]]; then echo "EUID检查: 非root用户"; exit 1; else echo "EUID检查: root用户"; exit 0; fi' 2>&1)
    local euid_exit_code=$?
    
    if [[ $EUID -eq 0 ]]; then
        if [[ "$euid_check_output" == "EUID检查: root用户" && $euid_exit_code -eq 0 ]]; then
            log_success "EUID检查: root用户检测正确"
            return 0
        else
            log_error "EUID检查: root用户检测失败"
            return 1
        fi
    else
        if [[ "$euid_check_output" == "EUID检查: 非root用户" && $euid_exit_code -eq 1 ]]; then
            log_success "EUID检查: 非root用户检测正确"
            return 0
        else
            log_error "EUID检查: 非root用户检测失败"
            return 1
        fi
    fi
}

# 测试用例5: 验证id命令检查
function test_id_command_check() {
    echo "测试5: 验证id命令检查"
    
    # 测试id命令检查逻辑
    local id_check_output
    id_check_output=$(bash -c 'if ! id -u >/dev/null 2>&1 || [[ $(id -u) -ne 0 ]]; then echo "id检查: 非root用户"; exit 1; else echo "id检查: root用户"; exit 0; fi' 2>&1)
    local id_exit_code=$?
    
    if [[ $(id -u) -eq 0 ]]; then
        if [[ "$id_check_output" == "id检查: root用户" && $id_exit_code -eq 0 ]]; then
            log_success "id命令检查: root用户检测正确"
            return 0
        else
            log_error "id命令检查: root用户检测失败"
            return 1
        fi
    else
        if [[ "$id_check_output" == "id检查: 非root用户" && $id_exit_code -eq 1 ]]; then
            log_success "id命令检查: 非root用户检测正确"
            return 0
        else
            log_error "id命令检查: 非root用户检测失败"
            return 1
        fi
    fi
}

# 测试用例6: 验证权限检查函数
function test_permission_check_function() {
    echo "测试6: 验证权限检查函数"
    
    # 创建测试权限检查函数
    local test_script
    test_script=$(cat << 'EOF'
#!/bin/bash
check_root_permission() {
    if [[ $EUID -ne 0 ]]; then
        echo "错误: 此脚本需要以root权限运行"
        echo "请使用sudo命令或以root用户身份执行此脚本"
        return 1
    fi
    
    if ! id -u >/dev/null 2>&1 || [[ $(id -u) -ne 0 ]]; then
        echo "无法验证root权限"
        return 1
    fi
    
    echo "权限验证通过"
    return 0
}

check_root_permission
EOF
)
    
    # 执行测试
    local test_output
    test_output=$(bash -c "$test_script" 2>&1)
    local test_exit_code=$?
    
    if [[ $EUID -eq 0 ]]; then
        if [[ "$test_output" == "权限验证通过" && $test_exit_code -eq 0 ]]; then
            log_success "权限检查函数: root用户测试通过"
            return 0
        else
            log_error "权限检查函数: root用户测试失败"
            log_debug "输出: $test_output"
            log_debug "退出码: $test_exit_code"
            return 1
        fi
    else
        if [[ "$test_output" == *"错误: 此脚本需要以root权限运行"* && $test_exit_code -eq 1 ]]; then
            log_success "权限检查函数: 非root用户测试通过"
            return 0
        else
            log_error "权限检查函数: 非root用户测试失败"
            log_debug "输出: $test_output"
            log_debug "退出码: $test_exit_code"
            return 1
        fi
    fi
}

# 测试用例7: 验证系统信息
function test_system_info() {
    echo "测试7: 验证系统信息"
    
    # 获取系统信息
    local os_info
    local user_info
    local home_dir
    os_info=$(uname -a 2>/dev/null || echo "unknown")
    user_info=$(whoami 2>/dev/null || echo "unknown")
    home_dir=$(echo "$HOME" 2>/dev/null || echo "unknown")
    
    log_info "操作系统: $os_info"
    log_info "当前用户: $user_info"
    log_info "用户目录: $home_dir"
    
    # 检查是否为root用户
    if [[ "$user_info" == "root" ]]; then
        log_success "系统信息: 确认root用户"
        return 0
    else
        log_success "系统信息: 确认非root用户"
        return 0
    fi
}

# 运行所有测试
function run_all_tests() {
    local total=0
    local passed=0
    
    echo "=== Root权限检查测试 ==="
    echo
    
    for test_case in test_permission_detection test_permission_denied test_error_handling test_euid_check test_id_command_check test_permission_check_function test_system_info; do
        ((total++))
        echo "----------------------------------------"
        if $test_case; then
            ((passed++))
        fi
        echo
    done
    
    echo "========================================"
    echo "=== 测试结果汇总 ==="
    echo "总测试数: $total"
    echo "通过测试: $passed"
    echo "失败测试: $((total-passed))"
    
    if [[ $passed -eq $total ]]; then
        log_success "所有测试通过！"
        return 0
    else
        log_error "部分测试失败！"
        return 1
    fi
}

# 显示使用说明
function show_usage() {
    echo "Root权限检查测试脚本"
    echo
    echo "用法:"
    echo "  $0                    # 运行所有测试"
    echo "  $0 --help            # 显示帮助信息"
    echo "  $0 --test <name>     # 运行指定测试"
    echo
    echo "可用测试:"
    echo "  permission_detection     # 权限检测功能"
    echo "  permission_denied        # 权限不足场景"
    echo "  error_handling          # 错误处理机制"
    echo "  euid_check              # EUID检查"
    echo "  id_command_check        # id命令检查"
    echo "  permission_check_function # 权限检查函数"
    echo "  system_info             # 系统信息"
}

# 运行指定测试
function run_specific_test() {
    local test_name="$1"
    
    case "$test_name" in
        "permission_detection")
            test_permission_detection
            ;;
        "permission_denied")
            test_permission_denied
            ;;
        "error_handling")
            test_error_handling
            ;;
        "euid_check")
            test_euid_check
            ;;
        "id_command_check")
            test_id_command_check
            ;;
        "permission_check_function")
            test_permission_check_function
            ;;
        "system_info")
            test_system_info
            ;;
        *)
            log_error "未知测试: $test_name"
            show_usage
            return 1
            ;;
    esac
}

# 主函数
function main() {
    case "${1:-}" in
        "--help"|"-h")
            show_usage
            ;;
        "--test"|"-t")
            if [[ -n "${2:-}" ]]; then
                run_specific_test "$2"
            else
                log_error "请指定测试名称"
                show_usage
                return 1
            fi
            ;;
        "")
            run_all_tests
            ;;
        *)
            log_error "未知参数: $1"
            show_usage
            return 1
            ;;
    esac
}

# 执行主函数
main "$@"
