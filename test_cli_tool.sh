#!/bin/bash

# IPv6 WireGuard Manager - CLI工具测试脚本
# 测试CLI管理工具的各项功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 测试配置
CLI_TOOL="ipv6-wireguard-manager"
TEST_RESULTS=()

# 运行测试
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    log_info "测试: $test_name"
    log_info "命令: $command"
    
    if eval "$command" > /dev/null 2>&1; then
        local exit_code=$?
        if [[ $exit_code -eq $expected_exit_code ]]; then
            log_success "✓ $test_name 通过"
            TEST_RESULTS+=("✓ $test_name")
        else
            log_error "✗ $test_name 失败 (退出码: $exit_code, 期望: $expected_exit_code)"
            TEST_RESULTS+=("✗ $test_name")
        fi
    else
        local exit_code=$?
        if [[ $exit_code -eq $expected_exit_code ]]; then
            log_success "✓ $test_name 通过"
            TEST_RESULTS+=("✓ $test_name")
        else
            log_error "✗ $test_name 失败 (退出码: $exit_code, 期望: $expected_exit_code)"
            TEST_RESULTS+=("✗ $test_name")
        fi
    fi
    echo ""
}

# 检查CLI工具是否存在
check_cli_tool() {
    log_info "检查CLI工具是否存在..."
    
    if command -v "$CLI_TOOL" &> /dev/null; then
        log_success "✓ CLI工具已安装"
        log_info "位置: $(which $CLI_TOOL)"
        return 0
    else
        log_error "✗ CLI工具未安装"
        log_info "请先运行安装脚本安装CLI工具"
        return 1
    fi
}

# 测试帮助命令
test_help_commands() {
    log_info "测试帮助命令..."
    
    run_test "显示帮助信息" "$CLI_TOOL help"
    run_test "显示版本信息" "$CLI_TOOL version"
    run_test "无效命令" "$CLI_TOOL invalid-command" 1
}

# 测试服务管理命令
test_service_commands() {
    log_info "测试服务管理命令..."
    
    run_test "查看服务状态" "$CLI_TOOL status"
    run_test "启动服务" "$CLI_TOOL start"
    run_test "停止服务" "$CLI_TOOL stop"
    run_test "重启服务" "$CLI_TOOL restart"
}

# 测试系统管理命令
test_system_commands() {
    log_info "测试系统管理命令..."
    
    run_test "查看日志" "$CLI_TOOL logs -n 10"
    run_test "系统监控" "$CLI_TOOL monitor"
    run_test "创建备份" "$CLI_TOOL backup --name test-backup"
}

# 测试参数解析
test_parameter_parsing() {
    log_info "测试参数解析..."
    
    run_test "日志行数参数" "$CLI_TOOL logs -n 5"
    run_test "备份名称参数" "$CLI_TOOL backup --name parameter-test"
    run_test "无效参数" "$CLI_TOOL logs --invalid-param" 1
}

# 测试错误处理
test_error_handling() {
    log_info "测试错误处理..."
    
    run_test "无效命令" "$CLI_TOOL nonexistent-command" 1
    run_test "无效选项" "$CLI_TOOL logs --invalid-option" 1
}

# 性能测试
test_performance() {
    log_info "测试性能..."
    
    local start_time=$(date +%s.%N)
    $CLI_TOOL status > /dev/null 2>&1
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    if (( $(echo "$duration < 5.0" | bc -l) )); then
        log_success "✓ 性能测试通过 (耗时: ${duration}s)"
        TEST_RESULTS+=("✓ 性能测试")
    else
        log_warning "⚠ 性能测试警告 (耗时: ${duration}s)"
        TEST_RESULTS+=("⚠ 性能测试")
    fi
}

# 显示测试结果
show_test_results() {
    log_info "测试结果汇总:"
    echo "=================================="
    
    local passed=0
    local failed=0
    local total=0
    
    for result in "${TEST_RESULTS[@]}"; do
        echo "$result"
        if [[ $result == ✓* ]]; then
            ((passed++))
        elif [[ $result == ✗* ]]; then
            ((failed++))
        fi
        ((total++))
    done
    
    echo "=================================="
    log_info "总计: $total 个测试"
    log_success "通过: $passed 个"
    if [[ $failed -gt 0 ]]; then
        log_error "失败: $failed 个"
    else
        log_success "失败: $failed 个"
    fi
    
    if [[ $failed -eq 0 ]]; then
        log_success "🎉 所有测试通过！"
        return 0
    else
        log_error "❌ 部分测试失败"
        return 1
    fi
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - CLI工具测试"
    echo ""
    
    # 检查CLI工具
    if ! check_cli_tool; then
        exit 1
    fi
    echo ""
    
    # 运行测试
    test_help_commands
    test_service_commands
    test_system_commands
    test_parameter_parsing
    test_error_handling
    test_performance
    
    # 显示结果
    show_test_results
}

# 运行主函数
main "$@"
