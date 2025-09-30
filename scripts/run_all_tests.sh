#!/bin/bash

# 统一测试入口脚本
# 整合所有测试功能，提供统一的测试接口

# 设置错误处理
set -euo pipefail

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$PROJECT_ROOT/modules"

# 导入公共函数
if [[ -f "$MODULES_DIR/common_functions.sh" ]]; then
    source "$MODULES_DIR/common_functions.sh"
else
    echo "错误: 无法找到公共函数模块"
    exit 1
fi

# ================================================================
# 测试配置
# ================================================================

# 测试类型
TEST_TYPES=(
    "syntax"      # 语法测试
    "functional"  # 功能测试
    "security"    # 安全测试
    "performance" # 性能测试
    "compatibility" # 兼容性测试
    "all"         # 所有测试
)

# 测试选项
VERBOSE=false
QUIET=false
PARALLEL=false
TIMEOUT=300
RETRY_COUNT=3
TEST_TYPE="all"
OUTPUT_FORMAT="text"  # text, json, html
REPORT_DIR="$PROJECT_ROOT/reports"

# ================================================================
# 帮助信息
# ================================================================

show_help() {
    cat << EOF
IPv6 WireGuard Manager 统一测试脚本

用法: $0 [选项]

选项:
  -h, --help              显示帮助信息
  -v, --verbose           详细输出
  -q, --quiet             静默输出
  -p, --parallel          并行执行测试
  -t, --timeout SECONDS   设置测试超时时间（默认: 300秒）
  -r, --retry COUNT       设置重试次数（默认: 3次）
  -f, --format FORMAT     设置输出格式（text/json/html，默认: text）
  -o, --output DIR        设置报告输出目录（默认: reports/）
  
测试类型:
  --syntax                仅运行语法测试
  --functional            仅运行功能测试
  --security              仅运行安全测试
  --performance           仅运行性能测试
  --compatibility         仅运行兼容性测试
  --all                   运行所有测试（默认）

示例:
  $0 --all --verbose
  $0 --syntax --format json
  $0 --functional --parallel --timeout 600
  $0 --security --output /tmp/reports
EOF
}

# ================================================================
# 参数解析
# ================================================================

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
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -p|--parallel)
                PARALLEL=true
                shift
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -r|--retry)
                RETRY_COUNT="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -o|--output)
                REPORT_DIR="$2"
                shift 2
                ;;
            --syntax)
                TEST_TYPE="syntax"
                shift
                ;;
            --functional)
                TEST_TYPE="functional"
                shift
                ;;
            --security)
                TEST_TYPE="security"
                shift
                ;;
            --performance)
                TEST_TYPE="performance"
                shift
                ;;
            --compatibility)
                TEST_TYPE="compatibility"
                shift
                ;;
            --all)
                TEST_TYPE="all"
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

# ================================================================
# 测试执行函数
# ================================================================

# 运行语法测试
run_syntax_tests() {
    log_info "运行语法测试..."
    
    # 导入Windows兼容性模块
    if [[ -f "$MODULES_DIR/windows_compatibility.sh" ]]; then
        source "$MODULES_DIR/windows_compatibility.sh"
    fi
    
    # 运行自动化测试脚本的语法检查
    if [[ -f "$SCRIPT_DIR/automated-testing.sh" ]]; then
        bash "$SCRIPT_DIR/automated-testing.sh" --syntax-check
    else
        log_error "自动化测试脚本不存在"
        return 1
    fi
}

# 运行功能测试
run_functional_tests() {
    log_info "运行功能测试..."
    
    # 导入功能测试模块
    if [[ -f "$MODULES_DIR/functional_tests.sh" ]]; then
        source "$MODULES_DIR/functional_tests.sh"
        run_all_functional_tests
    else
        log_error "功能测试模块不存在"
        return 1
    fi
}

# 运行安全测试
run_security_tests() {
    log_info "运行安全测试..."
    
    # 导入安全测试模块
    if [[ -f "$MODULES_DIR/security_functions.sh" ]]; then
        source "$MODULES_DIR/security_functions.sh"
        run_security_tests
    else
        log_error "安全测试模块不存在"
        return 1
    fi
}

# 运行性能测试
run_performance_tests() {
    log_info "运行性能测试..."
    
    # 运行自动化测试脚本的性能测试
    if [[ -f "$SCRIPT_DIR/automated-testing.sh" ]]; then
        bash "$SCRIPT_DIR/automated-testing.sh" --performance
    else
        log_error "自动化测试脚本不存在"
        return 1
    fi
}

# 运行兼容性测试
run_compatibility_tests() {
    log_info "运行兼容性测试..."
    
    # 导入Windows兼容性模块
    if [[ -f "$MODULES_DIR/windows_compatibility.sh" ]]; then
        source "$MODULES_DIR/windows_compatibility.sh"
        test_windows_compatibility
    fi
    
    # 运行自动化测试脚本的兼容性测试
    if [[ -f "$SCRIPT_DIR/automated-testing.sh" ]]; then
        bash "$SCRIPT_DIR/automated-testing.sh" --all
    else
        log_error "自动化测试脚本不存在"
        return 1
    fi
}

# ================================================================
# 测试报告生成
# ================================================================

# 生成测试报告
generate_test_report() {
    local test_type="$1"
    local test_result="$2"
    local start_time="$3"
    local end_time="$4"
    
    # 创建报告目录
    mkdir -p "$REPORT_DIR"
    
    local report_file="$REPORT_DIR/test_report_${test_type}_$(date +%Y%m%d_%H%M%S).${OUTPUT_FORMAT}"
    
    case "$OUTPUT_FORMAT" in
        "json")
            generate_json_report "$report_file" "$test_type" "$test_result" "$start_time" "$end_time"
            ;;
        "html")
            generate_html_report "$report_file" "$test_type" "$test_result" "$start_time" "$end_time"
            ;;
        *)
            generate_text_report "$report_file" "$test_type" "$test_result" "$start_time" "$end_time"
            ;;
    esac
    
    log_success "测试报告已生成: $report_file"
}

# 生成JSON报告
generate_json_report() {
    local report_file="$1"
    local test_type="$2"
    local test_result="$3"
    local start_time="$4"
    local end_time="$5"
    
    cat > "$report_file" << EOF
{
    "test_type": "$test_type",
    "test_result": "$test_result",
    "start_time": "$start_time",
    "end_time": "$end_time",
    "duration": $((end_time - start_time)),
    "timestamp": "$(date -Iseconds)"
}
EOF
}

# 生成HTML报告
generate_html_report() {
    local report_file="$1"
    local test_type="$2"
    local test_result="$3"
    local start_time="$4"
    local end_time="$5"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager 测试报告</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .result { padding: 15px; border-radius: 5px; margin: 20px 0; }
        .success { background-color: #d4edda; border-left: 4px solid #28a745; }
        .failure { background-color: #f8d7da; border-left: 4px solid #dc3545; }
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager 测试报告</h1>
        <p>测试类型: $test_type</p>
        <p>生成时间: $(date)</p>
    </div>
    
    <div class="result $test_result">
        <h2>测试结果: $test_result</h2>
        <p>开始时间: $start_time</p>
        <p>结束时间: $end_time</p>
        <p>持续时间: $((end_time - start_time))秒</p>
    </div>
</body>
</html>
EOF
}

# 生成文本报告
generate_text_report() {
    local report_file="$1"
    local test_type="$2"
    local test_result="$3"
    local start_time="$4"
    local end_time="$5"
    
    cat > "$report_file" << EOF
IPv6 WireGuard Manager 测试报告
================================

测试类型: $test_type
测试结果: $test_result
开始时间: $start_time
结束时间: $end_time
持续时间: $((end_time - start_time))秒
生成时间: $(date)
EOF
}

# ================================================================
# 主函数
# ================================================================

main() {
    # 解析命令行参数
    parse_arguments "$@"
    
    # 显示横幅
    if [[ "$QUIET" != "true" ]]; then
        echo "=========================================="
        echo "  IPv6 WireGuard Manager 统一测试"
        echo "=========================================="
        echo
    fi
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 设置测试环境变量
    export IPV6WGM_TEST_VERBOSE="$VERBOSE"
    export IPV6WGM_TEST_QUIET="$QUIET"
    export IPV6WGM_TEST_PARALLEL="$PARALLEL"
    export IPV6WGM_TEST_TIMEOUT="$TIMEOUT"
    export IPV6WGM_TEST_RETRY_COUNT="$RETRY_COUNT"
    
    # 创建报告目录
    mkdir -p "$REPORT_DIR"
    
    # 运行测试
    local test_result="SUCCESS"
    local test_functions=()
    
    case "$TEST_TYPE" in
        "syntax")
            test_functions=("run_syntax_tests")
            ;;
        "functional")
            test_functions=("run_functional_tests")
            ;;
        "security")
            test_functions=("run_security_tests")
            ;;
        "performance")
            test_functions=("run_performance_tests")
            ;;
        "compatibility")
            test_functions=("run_compatibility_tests")
            ;;
        "all")
            test_functions=("run_syntax_tests" "run_functional_tests" "run_security_tests" "run_performance_tests" "run_compatibility_tests")
            ;;
    esac
    
    # 执行测试
    for test_func in "${test_functions[@]}"; do
        if [[ "$VERBOSE" == "true" ]]; then
            log_info "执行测试函数: $test_func"
        fi
        
        if ! $test_func; then
            test_result="FAILURE"
            if [[ "$TEST_TYPE" != "all" ]]; then
                break
            fi
        fi
    done
    
    # 记录结束时间
    local end_time=$(date +%s)
    
    # 生成测试报告
    generate_test_report "$TEST_TYPE" "$test_result" "$start_time" "$end_time"
    
    # 显示测试结果
    if [[ "$QUIET" != "true" ]]; then
        echo
        echo "=========================================="
        echo "  测试结果汇总"
        echo "=========================================="
        echo "测试类型: $TEST_TYPE"
        echo "测试结果: $test_result"
        echo "持续时间: $((end_time - start_time))秒"
        echo "报告目录: $REPORT_DIR"
        echo
    fi
    
    # 根据测试结果设置退出码
    if [[ "$test_result" == "SUCCESS" ]]; then
        log_success "所有测试通过！"
        exit 0
    else
        log_error "部分测试失败！"
        exit 1
    fi
}

# 运行主函数
main "$@"
