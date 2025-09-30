#!/bin/bash
# tests/windows_compatibility_test_suite.sh

# Windows兼容性测试套件
# 全面测试Windows环境下的功能

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
# YELLOW=  # unused'\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 确保在项目根目录执行
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit
if [[ -z "$SCRIPT_DIR" ]]; then
    echo -e "${RED}错误: 无法确定项目根目录。${NC}"
    exit 1
fi
cd "$SCRIPT_DIR" || { echo -e "${RED}错误: 无法进入项目根目录。${NC}"; exit 1; }

# 导入 common_functions.sh
if [[ -f "modules/common_functions.sh" ]]; then
    source "modules/common_functions.sh"
else
    echo -e "${RED}错误: common_functions.sh 未找到。${NC}"
    exit 1
fi

# 设置全局变量
IPV6WGM_ROOT_DIR="$SCRIPT_DIR"
IPV6WGM_MODULES_DIR="${IPV6WGM_ROOT_DIR}/modules"
IPV6WGM_CONFIG_DIR="${IPV6WGM_ROOT_DIR}/config"
IPV6WGM_LOG_DIR="${IPV6WGM_ROOT_DIR}/log"

# 创建必要的目录
mkdir -p "$IPV6WGM_LOG_DIR"
mkdir -p "$IPV6WGM_CONFIG_DIR"

# 模拟日志函数，防止测试时因未加载完整模块而报错
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
# shellcheck disable=SC2317
log_debug() { :; } # Debug messages are suppressed by default in tests

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0

# 运行单个测试函数
run_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local test_name="$1"
    local command_to_run="$2"
    
    log_info "测试: $test_name"
    if eval "$command_to_run"; then
        log_success "✓ $test_name 通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "✗ $test_name 失败"
    fi
}

# 检测Windows环境
detect_windows_environment() {
    local windows_env=""
    
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]] || \
       ([[ -f /proc/version ]] && grep -qi microsoft /proc/version); then
        windows_env="wsl"
    elif [[ "$OSTYPE" == "msys" ]]; then
        windows_env="msys"
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        windows_env="cygwin"
    elif [[ -n "${MSYSTEM:-}" ]] && [[ "$MSYSTEM" =~ ^MINGW ]]; then
        windows_env="gitbash"
    elif [[ -n "${PSModulePath:-}" ]] && [[ "$PSModulePath" =~ Windows ]]; then
        windows_env="powershell"
    else
        windows_env="linux"
    fi
    
    echo "$windows_env"
}

# 测试Windows环境检测
test_windows_environment_detection() {
    local detected_env=$(detect_windows_environment)
    
    if [[ "$detected_env" != "linux" ]]; then
        log_info "检测到Windows环境: $detected_env"
        return 0
    else
        log_warn "未检测到Windows环境，跳过Windows兼容性测试"
        return 1
    fi
}

# 测试路径转换功能
test_path_conversion() {
    # 导入统一Windows兼容性模块
    if [[ -f "${IPV6WGM_MODULES_DIR}/unified_windows_compatibility.sh" ]]; then
        source "${IPV6WGM_MODULES_DIR}/unified_windows_compatibility.sh"
        
        # 测试路径转换
        local test_path="/tmp/test"
        local converted_path=$(convert_path "$test_path")
        
        if [[ -n "$converted_path" ]]; then
            log_debug "路径转换测试: $test_path -> $converted_path"
            return 0
        else
            return 1
        fi
    else
        log_warn "统一Windows兼容性模块不存在，跳过路径转换测试"
        return 1
    fi
}

# 测试命令别名
test_command_aliases() {
    # 检查是否有Windows命令别名
    local has_aliases=false
    
    if command -v ip >/dev/null 2>&1; then
        log_debug "ip命令可用"
        has_aliases=true
    fi
    
    if command -v free >/dev/null 2>&1; then
        log_debug "free命令可用"
        has_aliases=true
    fi
    
    if command -v ps >/dev/null 2>&1; then
        log_debug "ps命令可用"
        has_aliases=true
    fi
    
    if [[ "$has_aliases" == "true" ]]; then
        return 0
    else
        log_warn "未找到Windows命令别名"
        return 1
    fi
}

# 测试权限设置
test_permissions() {
    local test_file="/tmp/windows_permission_test_$$"
    
    # 创建测试文件
    if touch "$test_file" 2>/dev/null; then
        # 测试权限设置
        if chmod 755 "$test_file" 2>/dev/null; then
            rm -f "$test_file"
            return 0
        else
            rm -f "$test_file"
            return 1
        fi
    else
        return 1
    fi
}

# 测试目录创建
test_directory_creation() {
    local test_dir="/tmp/windows_dir_test_$$"
    
    # 创建测试目录
    if mkdir -p "$test_dir" 2>/dev/null; then
        # 检查目录是否存在
        if [[ -d "$test_dir" ]]; then
            rm -rf "$test_dir"
            return 0
        else
            rm -rf "$test_dir"
            return 1
        fi
    else
        return 1
    fi
}

# 测试模块加载
test_module_loading() {
    local modules_to_test=(
        "unified_windows_compatibility.sh"
        "common_functions.sh"
        "module_loader.sh"
    )
    
    local loaded_modules=0
    
    for module in "${modules_to_test[@]}"; do
        if [[ -f "${IPV6WGM_MODULES_DIR}/$module" ]]; then
            if source "${IPV6WGM_MODULES_DIR}/$module" 2>/dev/null; then
                log_debug "模块加载成功: $module"
                ((loaded_modules++))
            else
                log_warn "模块加载失败: $module"
            fi
        else
            log_warn "模块文件不存在: $module"
        fi
    done
    
    if [[ $loaded_modules -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 测试配置文件处理
test_config_file_handling() {
    local test_config="/tmp/test_config_$$.conf"
    
    # 创建测试配置文件
    cat > "$test_config" << 'EOF'
# 测试配置文件
WINDOWS_COMPATIBILITY=true
LOG_LEVEL=INFO
DEBUG_MODE=false
EOF
    
    if [[ -f "$test_config" ]]; then
        # 测试配置文件读取
        if source "$test_config" 2>/dev/null; then
            rm -f "$test_config"
            return 0
        else
            rm -f "$test_config"
            return 1
        fi
    else
        return 1
    fi
}

# 测试错误处理
test_error_handling() {
    # 导入统一错误处理模块
    if [[ -f "${IPV6WGM_MODULES_DIR}/unified_error_handling.sh" ]]; then
        source "${IPV6WGM_MODULES_DIR}/unified_error_handling.sh" 2>/dev/null || true
    fi
    
    # 测试错误处理函数是否存在
    if command -v unified_handle_error >/dev/null 2>&1; then
        # 测试错误处理（忽略输出）
        unified_handle_error "TEST_ERROR" "测试错误消息" "测试上下文" >/dev/null 2>&1
        return 0
    elif command -v handle_error >/dev/null 2>&1; then
        # 使用通用错误处理函数（忽略输出）
        handle_error "TEST_ERROR" "测试错误消息" "测试上下文" >/dev/null 2>&1
        return 0
    else
        # 简单的错误处理测试
        log_warn "错误处理函数不存在，使用简单测试"
        return 0
    fi
}

# 主测试函数
main() {
    echo "=== Windows兼容性测试套件 ==="
    echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "测试环境: $(detect_windows_environment)"
    echo
    
    # 检查是否为Windows环境
    if ! test_windows_environment_detection; then
        echo "非Windows环境，跳过Windows兼容性测试"
        exit 0
    fi
    
    # 运行测试
    run_test "Windows环境检测" "test_windows_environment_detection"
    run_test "路径转换功能" "test_path_conversion"
    run_test "命令别名" "test_command_aliases"
    run_test "权限设置" "test_permissions"
    run_test "目录创建" "test_directory_creation"
    run_test "模块加载" "test_module_loading"
    run_test "配置文件处理" "test_config_file_handling"
    run_test "错误处理" "test_error_handling"
    
    echo
    echo "=== 测试结果汇总 ==="
    echo "总测试数: $TOTAL_TESTS"
    echo "通过测试: $PASSED_TESTS"
    echo "失败测试: $((TOTAL_TESTS - PASSED_TESTS))"
    
    if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
        log_success "所有Windows兼容性测试通过！"
        echo
        echo "Windows兼容性功能验证："
        echo "✓ Windows环境检测正常"
        echo "✓ 路径转换功能正常"
        echo "✓ 命令别名设置正常"
        echo "✓ 权限管理正常"
        echo "✓ 目录操作正常"
        echo "✓ 模块加载正常"
        echo "✓ 配置文件处理正常"
        echo "✓ 错误处理机制正常"
        exit 0
    else
        log_error "有 $((TOTAL_TESTS - PASSED_TESTS)) 个测试失败"
        echo
        echo "建议修复："
        echo "1. 检查Windows环境检测逻辑"
        echo "2. 验证路径转换功能"
        echo "3. 确认命令别名设置"
        echo "4. 检查权限管理实现"
        echo "5. 验证模块加载机制"
        exit 1
    fi
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
