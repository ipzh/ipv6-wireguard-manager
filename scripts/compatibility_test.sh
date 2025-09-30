#!/bin/bash

# IPv6 WireGuard Manager 兼容性测试脚本
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team
# 描述: 测试脚本在不同环境下的兼容性

# 设置错误处理，根据执行环境调整严格程度
if [[ -t 0 ]]; then
    # 交互式执行，使用严格模式
    set -euo pipefail
else
    # 管道执行，使用宽松模式
    set -e
fi

# 安全的脚本目录检测
get_script_dir() {
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        # 标准情况：通过BASH_SOURCE获取
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    elif [[ -n "${0:-}" && "$0" != "-bash" && "$0" != "bash" ]]; then
        # 备选方案1：通过$0获取
        echo "$(cd "$(dirname "$0")" && pwd)"
    else
        # 备选方案2：使用当前工作目录
        echo "$(pwd)"
    fi
}

# 获取脚本目录
SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 提前定义颜色变量，避免导入失败时出错
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 基础日志函数的备选实现
if ! command -v log_info &> /dev/null; then
    log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
    log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
    # log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }  # 不可达代码
    log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
    # log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $*"; }  # 不可达代码
fi

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local description="${3:-}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_info "运行测试: $test_name"
    if [[ -n "$description" ]]; then
        log_info "描述: $description"
    fi
    
    if eval "$test_command"; then
        log_success "测试通过: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "测试失败: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 测试 BASH_SOURCE[0] 在不同环境下的行为
test_bash_source() {
    log_info "测试 BASH_SOURCE[0] 兼容性..."
    
    # 测试1: 直接执行
    run_test "bash_source_direct" \
        "[[ -n \"\${BASH_SOURCE[0]:-}\" ]]" \
        "检查 BASH_SOURCE[0] 是否可用"
    
    # 测试2: 管道执行
    run_test "bash_source_pipe" \
        "echo 'test' | bash -c '[[ -n \"\${BASH_SOURCE[0]:-}\" ]] || echo \"fallback\"; exit 0'" \
        "检查管道执行下的 BASH_SOURCE[0] 行为"
    
    # 测试3: 备选方案
    run_test "bash_source_fallback" \
        "[[ -n \"\${0:-}\" && \"\$0\" != \"-bash\" && \"\$0\" != \"bash\" ]]" \
        "检查备选方案是否可用"
}

# 测试颜色变量定义
test_color_variables() {
    log_info "测试颜色变量兼容性..."
    
    # 测试颜色变量是否正确定义
    run_test "color_red" \
        "[[ -n \"\$RED\" && \"\$RED\" == *'31m' ]]" \
        "检查 RED 颜色变量"
    
    run_test "color_green" \
        "[[ -n \"\$GREEN\" && \"\$GREEN\" == *'32m' ]]" \
        "检查 GREEN 颜色变量"
    
    run_test "color_yellow" \
        "[[ -n \"\$YELLOW\" && \"\$YELLOW\" == *'33m' ]]" \
        "检查 YELLOW 颜色变量"
    
    run_test "color_blue" \
        "[[ -n \"\$BLUE\" && \"\$BLUE\" == *'34m' ]]" \
        "检查 BLUE 颜色变量"
    
    run_test "color_nc" \
        "[[ -n \"\$NC\" && \"\$NC\" == *'0m' ]]" \
        "检查 NC 颜色变量"
}

# 测试日志函数
test_log_functions() {
    log_info "测试日志函数兼容性..."
    
    # 测试日志函数是否可用
    run_test "log_info_function" \
        "command -v log_info &> /dev/null" \
        "检查 log_info 函数是否可用"
    
    run_test "log_success_function" \
        "command -v log_success &> /dev/null" \
        "检查 log_success 函数是否可用"
    
    run_test "log_error_function" \
        "command -v log_error &> /dev/null" \
        "检查 log_error 函数是否可用"
    
    # 测试日志函数输出
    run_test "log_info_output" \
        "log_info 'test message' | grep -q 'INFO'" \
        "检查 log_info 输出格式"
    
    run_test "log_success_output" \
        "log_success 'test message' | grep -q 'SUCCESS'" \
        "检查 log_success 输出格式"
    
    run_test "log_error_output" \
        "log_error 'test message' | grep -q 'ERROR'" \
        "检查 log_error 输出格式"
}

# 测试模块导入机制
test_module_import() {
    log_info "测试模块导入兼容性..."
    
    # 测试模块目录是否存在
    run_test "modules_dir_exists" \
        "[[ -d \"$PROJECT_ROOT/modules\" ]]" \
        "检查模块目录是否存在"
    
    # 测试关键模块文件
    local key_modules=("common_functions.sh" "module_loader.sh" "unified_config.sh")
    
    for module in "${key_modules[@]}"; do
        run_test "module_${module%.sh}" \
            "[[ -f \"$PROJECT_ROOT/modules/$module\" ]]" \
            "检查模块文件: $module"
    done
    
    # 测试模块导入函数
    run_test "import_module_function" \
        "command -v import_module &> /dev/null" \
        "检查 import_module 函数是否可用"
}

# 测试脚本执行环境
test_execution_environment() {
    log_info "测试脚本执行环境..."
    
    # 测试 Bash 版本
    run_test "bash_version" \
        "bash --version | grep -q 'GNU bash'" \
        "检查 Bash 版本"
    
    # 测试必要命令
    local required_commands=("curl" "wget" "tar" "chmod" "mkdir" "rm")
    
    for cmd in "${required_commands[@]}"; do
        run_test "command_$cmd" \
            "command -v $cmd &> /dev/null" \
            "检查命令是否可用: $cmd"
    done
    
    # 测试网络连接
    run_test "network_github" \
        "curl -s --connect-timeout 5 https://github.com > /dev/null" \
        "检查 GitHub 网络连接"
    
    # 测试权限
    run_test "sudo_permission" \
        "sudo -v 2>/dev/null" \
        "检查 sudo 权限"
}

# 测试不同执行方式
test_execution_methods() {
    log_info "测试不同执行方式..."
    
    # 测试直接执行
    run_test "direct_execution" \
        "bash -n \"$PROJECT_ROOT/install.sh\"" \
        "检查直接执行语法"
    
    # 测试管道执行
    run_test "pipe_execution" \
        "echo 'test' | bash -c 'set -e; echo \"pipe test passed\"'" \
        "检查管道执行兼容性"
    
    # 测试非交互式执行
    run_test "non_interactive_execution" \
        "bash -c '[[ \$- == *i* ]] || echo \"non-interactive\"; exit 0'" \
        "检查非交互式执行"
}

# 测试错误处理
test_error_handling() {
    log_info "测试错误处理兼容性..."
    
    # 测试严格模式
    run_test "strict_mode" \
        "bash -c 'set -euo pipefail; echo \"strict mode test\"; exit 0'" \
        "检查严格模式兼容性"
    
    # 测试宽松模式
    run_test "lenient_mode" \
        "bash -c 'set -e; echo \"lenient mode test\"; exit 0'" \
        "检查宽松模式兼容性"
    
    # 测试错误陷阱
    run_test "error_trap" \
        "bash -c 'trap \"echo error trapped\" ERR; false; exit 0'" \
        "检查错误陷阱机制"
}

# 测试跨平台兼容性
test_cross_platform() {
    log_info "测试跨平台兼容性..."
    
    # 检测操作系统
    run_test "os_detection" \
        "[[ -f /etc/os-release ]] || [[ -f /etc/redhat-release ]] || [[ -f /etc/debian_version ]]" \
        "检查操作系统检测"
    
    # 检测包管理器
    run_test "package_manager" \
        "command -v apt-get &> /dev/null || command -v yum &> /dev/null || command -v dnf &> /dev/null || command -v pacman &> /dev/null" \
        "检查包管理器可用性"
    
    # 检测系统服务
    run_test "systemd_available" \
        "command -v systemctl &> /dev/null" \
        "检查 systemd 可用性"
}

# 生成测试报告
generate_report() {
    local report_file="$PROJECT_ROOT/reports/compatibility_test_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "生成兼容性测试报告..."
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
IPv6 WireGuard Manager 兼容性测试报告
生成时间: $(date)
测试环境: $(uname -a)
Bash版本: $(bash --version | head -n1)

=== 测试结果统计 ===
总测试数: $TOTAL_TESTS
通过测试: $PASSED_TESTS
失败测试: $FAILED_TESTS
成功率: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%

=== 系统信息 ===
操作系统: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || uname -s)
内核版本: $(uname -r)
架构: $(uname -m)
Bash版本: $(bash --version | head -n1)

=== 网络环境 ===
GitHub连接: $(curl -s --connect-timeout 5 https://github.com > /dev/null && echo "正常" || echo "异常")
DNS解析: $(nslookup github.com > /dev/null 2>&1 && echo "正常" || echo "异常")

=== 权限检查 ===
当前用户: $(whoami)
Sudo权限: $(sudo -v 2>/dev/null && echo "可用" || echo "不可用")
Root权限: $([ $EUID -eq 0 ] && echo "是" || echo "否")

=== 命令可用性 ===
curl: $(command -v curl &> /dev/null && echo "可用" || echo "不可用")
wget: $(command -v wget &> /dev/null && echo "可用" || echo "不可用")
tar: $(command -v tar &> /dev/null && echo "可用" || echo "不可用")
git: $(command -v git &> /dev/null && echo "可用" || echo "不可用")
systemctl: $(command -v systemctl &> /dev/null && echo "可用" || echo "不可用")

=== 建议 ===
EOF

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "所有测试通过，系统完全兼容！" >> "$report_file"
    else
        echo "发现 $FAILED_TESTS 个问题，建议检查相关配置。" >> "$report_file"
    fi
    
    log_success "测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始兼容性测试..."
    
    # 运行所有测试
    test_bash_source
    test_color_variables
    test_log_functions
    test_module_import
    test_execution_environment
    test_execution_methods
    test_error_handling
    test_cross_platform
    
    # 显示测试结果
    echo
    log_info "=== 兼容性测试结果 ==="
    log_info "总测试数: $TOTAL_TESTS"
    log_success "通过测试: $PASSED_TESTS"
    if [[ $FAILED_TESTS -gt 0 ]]; then
        log_error "失败测试: $FAILED_TESTS"
    else
        log_success "失败测试: $FAILED_TESTS"
    fi
    
    local success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    log_info "成功率: ${success_rate}%"
    
    # 生成报告
    generate_report
    
    # 返回退出码
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "所有兼容性测试通过！"
        exit 0
    else
        log_error "发现兼容性问题，请查看测试报告。"
        exit 1
    fi
}

# 运行主函数
main "$@"
