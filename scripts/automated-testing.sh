#!/bin/bash

# IPv6 WireGuard Manager 自动化测试脚本
# 版本: 1.0.0

set -euo pipefail

# 统一的导入机制
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="${MODULES_DIR:-${PROJECT_ROOT}/modules}"

# 导入公共函数库
if [[ -f "${MODULES_DIR}/common_functions.sh" ]]; then
    source "${MODULES_DIR}/common_functions.sh"
    # 验证导入是否成功
    if ! command -v log_info &> /dev/null; then
        echo -e "${RED}错误: 公共函数库导入失败，log_info函数不可用${NC}" >&2
        exit 1
    fi
else
    echo -e "${RED}错误: 公共函数库文件不存在: ${MODULES_DIR}/common_functions.sh${NC}" >&2
    exit 1
fi

# 导入模块加载器
if [[ -f "${MODULES_DIR}/module_loader.sh" ]]; then
    source "${MODULES_DIR}/module_loader.sh"
    log_info "模块加载器已导入"
else
    log_error "模块加载器文件不存在: ${MODULES_DIR}/module_loader.sh"
    exit 1
fi

# 配置
TEST_DIR="$PROJECT_ROOT/tests"
REPORT_DIR="$PROJECT_ROOT/reports"
LOG_DIR="$PROJECT_ROOT/logs"

# 统一的命令执行函数
execute_command() {
    local command="$1"
    local description="$2"
    local allow_failure="${3:-false}"
    local timeout="${4:-300}"  # 默认5分钟超时
    
    log_info "${description}..."
    
    # 使用timeout命令限制执行时间
    if command -v timeout >/dev/null 2>&1; then
        if timeout "$timeout" bash -c "$command"; then
            log_success "${description}完成"
            return 0
        else
            local exit_code=$?
            if [[ "$allow_failure" == "true" ]]; then
                log_warn "${description}执行失败，继续执行 (退出码: $exit_code)"
                return 1
            else
                log_error "${description}执行失败: 命令 '${command}' 返回非零状态 (退出码: $exit_code)"
                exit 1
            fi
        fi
    else
        # 如果没有timeout命令，直接执行
        if eval "$command"; then
            log_success "${description}完成"
            return 0
        else
            local exit_code=$?
            if [[ "$allow_failure" == "true" ]]; then
                log_warn "${description}执行失败，继续执行 (退出码: $exit_code)"
                return 1
            else
                log_error "${description}执行失败: 命令 '${command}' 返回非零状态 (退出码: $exit_code)"
                exit 1
            fi
        fi
    fi
}

# 测试配置
TEST_TIMEOUT=300  # 5分钟超时
PARALLEL_JOBS=4   # 并行任务数
VERBOSE=false
DRY_RUN=false

# 创建必要目录
mkdir -p "$REPORT_DIR" "$LOG_DIR"

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "=========================================="
    echo "  IPv6 WireGuard Manager 自动化测试"
    echo "=========================================="
    echo -e "${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
  -h, --help              显示帮助信息
  -v, --verbose           详细输出
  -d, --dry-run           模拟运行（不执行实际测试）
  -t, --timeout SECONDS   设置测试超时时间（默认: 300秒）
  -j, --jobs NUMBER       设置并行任务数（默认: 4）
  --basic                 仅运行基础测试
  --advanced              仅运行高级测试
  --security              仅运行安全测试
  --performance           仅运行性能测试
  --all                   运行所有测试（默认）

示例:
  $0 --basic --verbose
  $0 --security --timeout 600
  $0 --all --jobs 8
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
                TEST_TIMEOUT="$2"
                shift 2
                ;;
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            --basic)
                TEST_TYPE="basic"
                shift
                ;;
            --advanced)
                TEST_TYPE="advanced"
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
            --all)
                TEST_TYPE="all"
                shift
                ;;
            *)
                echo "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

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

# 检查依赖
check_dependencies() {
    log_info "检查测试依赖..."
    
    local missing_deps=()
    
    # 检查必要命令
    local required_commands=(
        "bash" "curl" "wget" "git" "sqlite3"
    )
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # 检查Python依赖
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # 检查测试工具
    if ! command -v shellcheck &> /dev/null; then
        log_warning "ShellCheck未安装，静态分析功能受限"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少必要依赖: ${missing_deps[*]}"
        log_info "请安装缺少的依赖后重试"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 环境准备
prepare_environment() {
    log_info "准备测试环境..."
    
    # 设置测试环境变量
    export TEST_MODE=true
    export TEST_TIMEOUT="$TEST_TIMEOUT"
    export VERBOSE="$VERBOSE"
    
    # 创建测试目录
    local test_dirs=(
        "$PROJECT_ROOT/test_data"
        "$PROJECT_ROOT/test_config"
        "$PROJECT_ROOT/test_logs"
    )
    
    for dir in "${test_dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    # 清理旧的测试数据
    if [[ -d "$PROJECT_ROOT/test_data" ]]; then
        rm -rf "$PROJECT_ROOT/test_data"/*
    fi
    
    log_success "测试环境准备完成"
}

# 运行语法检查
run_syntax_check() {
    log_info "运行语法检查..."
    
    local syntax_errors=0
    
    # 检查Shell脚本语法
    while IFS= read -r -d '' file; do
        if ! bash -n "$file" 2>/dev/null; then
            log_error "语法错误: $file"
            syntax_errors=$((syntax_errors + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -print0)
    
    # 检查配置文件语法
    while IFS= read -r -d '' file; do
        if ! bash -n "$file" 2>/dev/null; then
            log_error "配置文件语法错误: $file"
            syntax_errors=$((syntax_errors + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.conf" -type f -print0)
    
    if [[ $syntax_errors -eq 0 ]]; then
        log_success "语法检查通过"
        return 0
    else
        log_error "发现 $syntax_errors 个语法错误"
        return 1
    fi
}

# 运行静态分析
run_static_analysis() {
    log_info "运行静态分析..."
    
    if ! command -v shellcheck &> /dev/null; then
        log_warning "ShellCheck未安装，跳过静态分析"
        return 0
    fi
    
    local analysis_errors=0
    
    # 运行ShellCheck
    while IFS= read -r -d '' file; do
        if ! shellcheck "$file" 2>/dev/null; then
            log_error "静态分析发现问题: $file"
            analysis_errors=$((analysis_errors + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -print0)
    
    if [[ $analysis_errors -eq 0 ]]; then
        log_success "静态分析通过"
        return 0
    else
        log_error "发现 $analysis_errors 个静态分析问题"
        return 1
    fi
}

# 运行单元测试
run_unit_tests() {
    log_info "运行单元测试..."
    
    if [[ ! -f "$TEST_DIR/run_tests.sh" ]]; then
        log_error "测试脚本不存在: $TEST_DIR/run_tests.sh"
        return 1
    fi
    
    # 设置测试权限
    chmod +x "$TEST_DIR/run_tests.sh"
    
    # 运行测试
    local test_args=""
    case "$TEST_TYPE" in
        "basic")
            test_args="--basic"
            ;;
        "advanced")
            test_args="--advanced"
            ;;
        "all")
            test_args=""
            ;;
    esac
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "模拟运行单元测试: $TEST_DIR/run_tests.sh $test_args"
        return 0
    fi
    
    # 设置超时
    if timeout "$TEST_TIMEOUT" "$TEST_DIR/run_tests.sh" $test_args; then
        log_success "单元测试通过"
        return 0
    else
        log_error "单元测试失败"
        return 1
    fi
}

# 运行安全测试
run_security_tests() {
    log_info "运行安全测试..."
    
    local security_issues=0
    
    # 检查硬编码凭据
    if grep -r -i "password.*=" "$PROJECT_ROOT" --include="*.sh" --include="*.conf" | grep -v "PASSWORD.*="; then
        log_error "发现硬编码凭据"
        security_issues=$((security_issues + 1))
    fi
    
    # 检查敏感文件权限
    while IFS= read -r -d '' file; do
        local perms=$(stat -c "%a" "$file")
        if [[ "$perms" != "600" ]]; then
            log_error "敏感文件权限不当: $file ($perms)"
            security_issues=$((security_issues + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.key" -o -name "*.pem" -o -name "*.p12" -type f -print0)
    
    # 检查输入验证
    local validation_functions=$(grep -r "sanitize_input\|validate_" "$PROJECT_ROOT/modules/" | wc -l)
    if [[ $validation_functions -lt 5 ]]; then
        log_warning "输入验证函数较少: $validation_functions"
    fi
    
    if [[ $security_issues -eq 0 ]]; then
        log_success "安全测试通过"
        return 0
    else
        log_error "发现 $security_issues 个安全问题"
        return 1
    fi
}

# 运行性能测试
run_performance_tests() {
    log_info "运行性能测试..."
    
    # 测试脚本启动时间
    local start_time=$(date +%s.%N)
    timeout 10s "$PROJECT_ROOT/ipv6-wireguard-manager.sh" --help &>/dev/null || true
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    if (( $(echo "$duration < 5.0" | bc -l) )); then
        log_success "启动时间正常: ${duration}s"
    else
        log_warning "启动时间较慢: ${duration}s"
    fi
    
    # 测试内存使用
    local memory_usage=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    if [[ $memory_usage -lt 100000 ]]; then  # 100MB
        log_success "内存使用正常: ${memory_usage}KB"
    else
        log_warning "内存使用较高: ${memory_usage}KB"
    fi
    
    log_success "性能测试完成"
    return 0
}

# 运行集成测试
run_integration_tests() {
    log_info "运行集成测试..."
    
    # 测试模块加载
    if [[ -f "$PROJECT_ROOT/modules/module_loader.sh" ]]; then
        source "$PROJECT_ROOT/modules/module_loader.sh"
        log_success "模块加载器正常"
    else
        log_error "模块加载器不存在"
        return 1
    fi
    
    # 测试配置管理
    if [[ -f "$PROJECT_ROOT/config/manager.conf" ]]; then
        log_success "配置文件存在"
    else
        log_error "配置文件不存在"
        return 1
    fi
    
    # 测试数据库操作
    local test_db="$PROJECT_ROOT/test_data/test.db"
    sqlite3 "$test_db" "CREATE TABLE test (id INTEGER, name TEXT);"
    sqlite3 "$test_db" "INSERT INTO test VALUES (1, 'test');"
    local count=$(sqlite3 "$test_db" "SELECT COUNT(*) FROM test;")
    
    if [[ "$count" -eq 1 ]]; then
        log_success "数据库操作正常"
    else
        log_error "数据库操作失败"
        return 1
    fi
    
    # 清理测试数据
    rm -f "$test_db"
    
    log_success "集成测试通过"
    return 0
}

# 生成测试报告
generate_test_report() {
    log_info "生成测试报告..."
    
    local report_file="$REPORT_DIR/test-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# IPv6 WireGuard Manager 测试报告

**生成时间**: $(date)
**测试类型**: $TEST_TYPE
**测试超时**: ${TEST_TIMEOUT}秒
**并行任务**: $PARALLEL_JOBS

## 测试环境
- **操作系统**: $(uname -s)
- **内核版本**: $(uname -r)
- **Shell版本**: $BASH_VERSION
- **Python版本**: $(python3 --version 2>/dev/null || echo "未安装")

## 测试结果
EOF

    # 添加测试结果
    if [[ -f "$LOG_DIR/test-results.log" ]]; then
        cat "$LOG_DIR/test-results.log" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## 测试统计
- **总测试数**: $TOTAL_TESTS
- **通过测试**: $PASSED_TESTS
- **失败测试**: $FAILED_TESTS
- **跳过测试**: $SKIPPED_TESTS

## 建议
EOF

    # 添加改进建议
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "- 修复失败的测试用例" >> "$report_file"
    fi
    
    if [[ $SKIPPED_TESTS -gt 0 ]]; then
        echo "- 补充跳过的测试用例" >> "$report_file"
    fi
    
    echo "- 定期运行自动化测试" >> "$report_file"
    echo "- 持续改进测试覆盖率" >> "$report_file"
    
    log_success "测试报告生成完成: $report_file"
}

# 清理测试环境
cleanup_environment() {
    log_info "清理测试环境..."
    
    # 清理测试数据
    rm -rf "$PROJECT_ROOT/test_data"
    rm -rf "$PROJECT_ROOT/test_config"
    rm -rf "$PROJECT_ROOT/test_logs"
    
    # 清理临时文件
    find "$PROJECT_ROOT" -name "*.tmp" -type f -delete 2>/dev/null || true
    
    log_success "测试环境清理完成"
}

# 主函数
main() {
    # 默认测试类型
    TEST_TYPE="${TEST_TYPE:-all}"
    
    # 解析参数
    parse_arguments "$@"
    
    show_banner
    
    log_info "开始自动化测试..."
    log_info "测试类型: $TEST_TYPE"
    log_info "超时时间: ${TEST_TIMEOUT}秒"
    log_info "并行任务: $PARALLEL_JOBS"
    log_info "详细输出: $VERBOSE"
    log_info "模拟运行: $DRY_RUN"
    echo
    
    # 初始化测试统计
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    SKIPPED_TESTS=0
    
    # 运行测试
    local test_functions=()
    
    case "$TEST_TYPE" in
        "basic")
            test_functions=("run_syntax_check" "run_unit_tests")
            ;;
        "advanced")
            test_functions=("run_syntax_check" "run_static_analysis" "run_unit_tests" "run_integration_tests")
            ;;
        "security")
            test_functions=("run_security_tests")
            ;;
        "performance")
            test_functions=("run_performance_tests")
            ;;
        "all")
            test_functions=("run_syntax_check" "run_static_analysis" "run_unit_tests" "run_security_tests" "run_performance_tests" "run_integration_tests")
            ;;
    esac
    
    # 检查依赖
    check_dependencies
    
    # 准备环境
    prepare_environment
    
    # 运行测试
    for test_func in "${test_functions[@]}"; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        
        if $test_func; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log_success "测试通过: $test_func"
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log_error "测试失败: $test_func"
        fi
    done
    
    # 生成报告
    generate_test_report
    
    # 清理环境
    cleanup_environment
    
    # 显示结果
    echo
    echo -e "${CYAN}=========================================="
    echo "  测试结果汇总"
    echo "==========================================${NC}"
    echo
    echo -e "总测试数: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"
    echo -e "跳过测试: ${YELLOW}$SKIPPED_TESTS${NC}"
    echo
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "🎉 所有测试通过！"
        exit 0
    else
        log_error "❌ 有 $FAILED_TESTS 个测试失败"
        exit 1
    fi
}

# 运行主函数
main "$@"
