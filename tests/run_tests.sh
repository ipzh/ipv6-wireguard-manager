#!/bin/bash

# IPv6 WireGuard Manager 测试运行器
# 版本: 2.0.0 - 重构版本，消除重复代码

# 设置错误处理
set -euo pipefail

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 导入统一测试框架
source "$PROJECT_ROOT/modules/unified_test_framework.sh"

# 导入测试配置
source "$SCRIPT_DIR/test_config.sh"

# 测试参数
TEST_TYPE="all"
VERBOSE=false
DRY_RUN=false
TIMEOUT=300

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager 测试运行器 v2.0.0

用法: $0 [选项] [测试类型]

选项:
  -h, --help              显示帮助信息
  -v, --verbose           详细输出
  -d, --dry-run           模拟运行（不执行实际测试）
  -t, --timeout SECONDS   设置测试超时时间（默认: 300秒）

测试类型:
  unit                    单元测试
  integration             集成测试
  performance             性能测试
  compatibility           兼容性测试
  all                     所有测试（默认）

示例:
  $0 --verbose unit
  $0 --timeout 600 integration
  $0 --dry-run all
EOF
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            unit|integration|performance|compatibility|all)
                TEST_TYPE="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 运行测试套件
run_test_suite() {
    local test_type="$1"
    log_info "开始执行测试: $test_type"
    
    # 准备测试环境
    prepare_test_environment "$test_type"
    
    # 验证测试环境
    if ! validate_test_environment; then
        log_error "测试环境验证失败"
        exit 1
    fi
    
    # 根据测试类型运行相应测试
    case "$test_type" in
        "unit")
            run_unit_tests
            ;;
        "integration")
            run_integration_tests
            ;;
        "performance")
            run_performance_tests
            ;;
        "compatibility")
            run_compatibility_tests
            ;;
        "all")
            run_all_tests
            ;;
        *)
            log_error "未知的测试类型: $test_type"
            exit 1
            ;;
    esac
    
    # 生成测试报告
    generate_test_report "$test_type"
    
    # 生成JSON报告（如果启用）
    if [[ "$GENERATE_JSON_REPORT" == "true" ]]; then
        generate_json_report "$test_type"
    fi
}

# 运行单元测试
run_unit_tests() {
    log_info "=== 运行单元测试 ==="
    
    # 使用统一的测试框架运行单元测试
    local unit_tests=(
        "bash -c 'source \"$PROJECT_ROOT/modules/variable_management.sh\" && ensure_variables'"
        "bash -c 'source \"$PROJECT_ROOT/modules/function_management.sh\" && register_function test_func 1.0.0'"
        "bash -c 'source \"$PROJECT_ROOT/modules/enhanced_config_management.sh\" && validate_ipv4 192.168.1.1'"
        "bash -c 'source \"$PROJECT_ROOT/modules/common_functions.sh\" && log_info \"测试日志功能\"'"
        "bash -c 'source \"$PROJECT_ROOT/modules/resource_monitoring.sh\" && get_memory_usage'"
    )
    
    run_test_group "单元测试" "${unit_tests[@]}"
}

# 运行集成测试
run_integration_tests() {
    log_info "=== 运行集成测试 ==="
    
    # 使用统一的测试框架运行集成测试
    local integration_tests=(
        "bash -c 'source \"$PROJECT_ROOT/modules/enhanced_module_loader.sh\" && load_module_smart common_functions'"
        "bash -c 'source \"$PROJECT_ROOT/modules/dependency_manager.sh\" && check_dependencies'"
        "bash -c 'source \"$PROJECT_ROOT/modules/enhanced_system_compatibility.sh\" && detect_operating_system'"
        "bash -c 'source \"$PROJECT_ROOT/modules/advanced_performance_optimization.sh\" && get_cache_stats'"
        "bash -c 'source \"$PROJECT_ROOT/modules/advanced_error_handling.sh\" && detect_exception_scenario'"
    )
    
    run_test_group "集成测试" "${integration_tests[@]}"
}

# 运行性能测试
run_performance_tests() {
    log_info "=== 运行性能测试 ==="
    
    # 使用统一的测试框架运行性能测试
    local performance_tests=(
        "bash -c 'time source \"$PROJECT_ROOT/ipv6-wireguard-manager.sh\" --help'"
        "bash -c 'source \"$PROJECT_ROOT/modules/advanced_performance_optimization.sh\" && get_cache_stats'"
        "bash -c 'source \"$PROJECT_ROOT/modules/resource_monitoring.sh\" && get_system_health_score'"
        "bash -c 'source \"$PROJECT_ROOT/modules/common_functions.sh\" && cached_command echo test'"
    )
    
    run_test_group "性能测试" "${performance_tests[@]}"
}

# 运行兼容性测试
run_compatibility_tests() {
    log_info "=== 运行兼容性测试 ==="
    
    # 使用统一的测试框架运行兼容性测试
    local compatibility_tests=(
        "bash -c 'source \"$PROJECT_ROOT/modules/enhanced_system_compatibility.sh\" && check_system_compatibility'"
        "bash -c 'bash --version'"
        "bash -c 'uname -a'"
        "bash -c 'source \"$PROJECT_ROOT/modules/enhanced_system_compatibility.sh\" && check_architecture_compatibility'"
    )
    
    run_test_group "兼容性测试" "${compatibility_tests[@]}"
}

# 运行所有测试
run_all_tests() {
    log_info "=== 运行所有测试 ==="
    
    # 依次运行所有测试类型
    run_unit_tests
    run_integration_tests
    run_performance_tests
    run_compatibility_tests
}

# 主函数
main() {
    # 解析参数
    parse_arguments "$@"
    
    # 显示测试信息
    log_info "IPv6 WireGuard Manager 测试运行器 v2.0.0"
    log_info "测试类型: $TEST_TYPE"
    log_info "详细输出: $VERBOSE"
    log_info "模拟运行: $DRY_RUN"
    log_info "超时时间: ${TIMEOUT}秒"
    
    # 设置测试开始时间
    TEST_START_TIME=$(date +%s)
    
    # 运行测试
    run_test_suite "$TEST_TYPE"
    
    # 设置测试结束时间
    TEST_END_TIME=$(date +%s)
    local total_duration=$((TEST_END_TIME - TEST_START_TIME))
    
    # 显示测试结果
    log_info "=== 测试完成 ==="
    log_info "总测试数: ${IPV6WGM_TEST_STATS[total_tests]:-0}"
    log_info "通过测试: ${IPV6WGM_TEST_STATS[passed_tests]:-0}"
    log_info "失败测试: ${IPV6WGM_TEST_STATS[failed_tests]:-0}"
    log_info "跳过测试: ${IPV6WGM_TEST_STATS[skipped_tests]:-0}"
    log_info "总耗时: ${total_duration}秒"
    
    # 返回适当的退出码
    if [[ ${IPV6WGM_TEST_STATS[failed_tests]:-0} -eq 0 ]]; then
        log_success "所有测试通过"
        exit 0
    else
        log_error "部分测试失败"
        exit 1
    fi
}

# 运行主函数
main "$@"