# 自动化测试流程

#!/bin/bash

# 自动化测试脚本
# 用于CI/CD流水线中的自动化测试

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
TEST_ENV=${TEST_ENV:-"test"}
PYTHON_VERSION=${PYTHON_VERSION:-"3.11"}
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-80}
PARALLEL_WORKERS=${PARALLEL_WORKERS:-4}

# 项目目录
PROJECT_ROOT=$(pwd)
BACKEND_DIR="$PROJECT_ROOT/backend"
TESTS_DIR="$PROJECT_ROOT/tests"
REPORTS_DIR="$PROJECT_ROOT/test-reports"

# 创建报告目录
mkdir -p "$REPORTS_DIR"

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# 清理函数
cleanup() {
    log_info "清理测试环境..."
    
    # 停止测试数据库
    if [ -n "$TEST_DB_PID" ]; then
        kill $TEST_DB_PID 2>/dev/null || true
    fi
    
    # 清理临时文件
    rm -rf /tmp/test_*
    
    log_success "清理完成"
}

# 设置清理陷阱
trap cleanup EXIT

# 检查依赖
check_dependencies() {
    log_info "检查测试依赖..."
    
    # 检查Python版本
    if ! python$PYTHON_VERSION --version >/dev/null 2>&1; then
        log_error "Python $PYTHON_VERSION 未安装"
        exit 1
    fi
    
    # 检查pip
    if ! pip --version >/dev/null 2>&1; then
        log_error "pip 未安装"
        exit 1
    fi
    
    # 检查pytest
    if ! python$PYTHON_VERSION -m pytest --version >/dev/null 2>&1; then
        log_warning "pytest 未安装，正在安装..."
        pip install pytest pytest-cov pytest-xdist pytest-html pytest-mock
    fi
    
    log_success "依赖检查完成"
}

# 设置测试环境
setup_test_environment() {
    log_info "设置测试环境..."
    
    # 创建虚拟环境
    if [ ! -d "venv-test" ]; then
        python$PYTHON_VERSION -m venv venv-test
    fi
    
    # 激活虚拟环境
    source venv-test/bin/activate
    
    # 安装依赖
    pip install --upgrade pip
    pip install -r "$BACKEND_DIR/requirements.txt"
    pip install pytest pytest-cov pytest-xdist pytest-html pytest-mock pytest-asyncio
    
    # 设置环境变量
    export TESTING=true
    export DATABASE_URL="sqlite:///./test.db"
    export SECRET_KEY="test-secret-key"
    export LOG_LEVEL="WARNING"
    
    log_success "测试环境设置完成"
}

# 启动测试数据库
start_test_database() {
    log_info "启动测试数据库..."
    
    # 使用SQLite进行测试（无需额外启动）
    log_success "测试数据库准备就绪"
}

# 运行单元测试
run_unit_tests() {
    log_info "运行单元测试..."
    
    cd "$BACKEND_DIR"
    
    # 运行单元测试
    python -m pytest tests/unit/ \
        --verbose \
        --tb=short \
        --cov=app \
        --cov-report=term-missing \
        --cov-report=html:"$REPORTS_DIR/unit-coverage" \
        --cov-report=xml:"$REPORTS_DIR/unit-coverage.xml" \
        --html="$REPORTS_DIR/unit-report.html" \
        --self-contained-html \
        --junit-xml="$REPORTS_DIR/unit-results.xml" \
        -n $PARALLEL_WORKERS \
        --maxfail=10
    
    if [ $? -eq 0 ]; then
        log_success "单元测试通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "单元测试失败"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# 运行集成测试
run_integration_tests() {
    log_info "运行集成测试..."
    
    cd "$BACKEND_DIR"
    
    # 运行集成测试
    python -m pytest tests/integration/ \
        --verbose \
        --tb=short \
        --cov=app \
        --cov-report=term-missing \
        --cov-report=html:"$REPORTS_DIR/integration-coverage" \
        --cov-report=xml:"$REPORTS_DIR/integration-coverage.xml" \
        --html="$REPORTS_DIR/integration-report.html" \
        --self-contained-html \
        --junit-xml="$REPORTS_DIR/integration-results.xml" \
        --maxfail=5
    
    if [ $? -eq 0 ]; then
        log_success "集成测试通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "集成测试失败"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# 运行API测试
run_api_tests() {
    log_info "运行API测试..."
    
    cd "$BACKEND_DIR"
    
    # 启动测试服务器
    python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 &
    SERVER_PID=$!
    
    # 等待服务器启动
    sleep 5
    
    # 运行API测试
    python -m pytest tests/api/ \
        --verbose \
        --tb=short \
        --html="$REPORTS_DIR/api-report.html" \
        --self-contained-html \
        --junit-xml="$REPORTS_DIR/api-results.xml" \
        --maxfail=5
    
    API_TEST_RESULT=$?
    
    # 停止测试服务器
    kill $SERVER_PID 2>/dev/null || true
    
    if [ $API_TEST_RESULT -eq 0 ]; then
        log_success "API测试通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "API测试失败"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# 运行性能测试
run_performance_tests() {
    log_info "运行性能测试..."
    
    cd "$BACKEND_DIR"
    
    # 运行性能测试
    python -m pytest tests/performance/ \
        --verbose \
        --tb=short \
        --html="$REPORTS_DIR/performance-report.html" \
        --self-contained-html \
        --junit-xml="$REPORTS_DIR/performance-results.xml" \
        --maxfail=3
    
    if [ $? -eq 0 ]; then
        log_success "性能测试通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "性能测试失败"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# 运行安全测试
run_security_tests() {
    log_info "运行安全测试..."
    
    cd "$BACKEND_DIR"
    
    # 运行安全测试
    python -m pytest tests/security/ \
        --verbose \
        --tb=short \
        --html="$REPORTS_DIR/security-report.html" \
        --self-contained-html \
        --junit-xml="$REPORTS_DIR/security-results.xml" \
        --maxfail=3
    
    if [ $? -eq 0 ]; then
        log_success "安全测试通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "安全测试失败"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# 运行代码质量检查
run_code_quality_checks() {
    log_info "运行代码质量检查..."
    
    cd "$BACKEND_DIR"
    
    # 安装代码质量工具
    pip install flake8 black isort mypy
    
    # 代码格式检查
    log_info "检查代码格式..."
    black --check app/ tests/ || {
        log_warning "代码格式不符合要求，正在自动格式化..."
        black app/ tests/
    }
    
    # 导入排序检查
    log_info "检查导入排序..."
    isort --check-only app/ tests/ || {
        log_warning "导入排序不符合要求，正在自动排序..."
        isort app/ tests/
    }
    
    # 代码风格检查
    log_info "检查代码风格..."
    flake8 app/ tests/ --max-line-length=100 --ignore=E203,W503 || {
        log_warning "代码风格检查发现问题"
    }
    
    # 类型检查
    log_info "检查类型注解..."
    mypy app/ --ignore-missing-imports || {
        log_warning "类型检查发现问题"
    }
    
    log_success "代码质量检查完成"
}

# 生成测试报告
generate_test_report() {
    log_info "生成测试报告..."
    
    # 合并覆盖率报告
    if [ -f "$REPORTS_DIR/unit-coverage.xml" ] && [ -f "$REPORTS_DIR/integration-coverage.xml" ]; then
        python -c "
import xml.etree.ElementTree as ET
import sys

# 合并覆盖率报告
unit_tree = ET.parse('$REPORTS_DIR/unit-coverage.xml')
unit_root = unit_tree.getroot()

integration_tree = ET.parse('$REPORTS_DIR/integration-coverage.xml')
integration_root = integration_tree.getroot()

# 这里可以实现更复杂的覆盖率合并逻辑
unit_tree.write('$REPORTS_DIR/combined-coverage.xml')
"
    fi
    
    # 生成测试总结
    cat > "$REPORTS_DIR/test-summary.md" << EOF
# 测试报告总结

## 测试统计
- 总测试套件: $TOTAL_TESTS
- 通过: $PASSED_TESTS
- 失败: $FAILED_TESTS
- 跳过: $SKIPPED_TESTS

## 测试结果
EOF
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo "- ✅ 所有测试通过" >> "$REPORTS_DIR/test-summary.md"
    else
        echo "- ❌ $FAILED_TESTS 个测试失败" >> "$REPORTS_DIR/test-summary.md"
    fi
    
    cat >> "$REPORTS_DIR/test-summary.md" << EOF

## 报告文件
- 单元测试报告: unit-report.html
- 集成测试报告: integration-report.html
- API测试报告: api-report.html
- 性能测试报告: performance-report.html
- 安全测试报告: security-report.html
- 覆盖率报告: combined-coverage.xml

## 生成时间
$(date)
EOF
    
    log_success "测试报告生成完成"
}

# 发送测试通知
send_test_notification() {
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        log_info "发送测试通知..."
        
        if [ $FAILED_TESTS -eq 0 ]; then
            STATUS="✅ 通过"
            COLOR="good"
        else
            STATUS="❌ 失败"
            COLOR="danger"
        fi
        
        curl -X POST -H 'Content-type: application/json' \
            --data "{
                \"text\": \"测试结果通知\",
                \"attachments\": [{
                    \"color\": \"$COLOR\",
                    \"fields\": [{
                        \"title\": \"状态\",
                        \"value\": \"$STATUS\",
                        \"short\": true
                    }, {
                        \"title\": \"总测试\",
                        \"value\": \"$TOTAL_TESTS\",
                        \"short\": true
                    }, {
                        \"title\": \"通过\",
                        \"value\": \"$PASSED_TESTS\",
                        \"short\": true
                    }, {
                        \"title\": \"失败\",
                        \"value\": \"$FAILED_TESTS\",
                        \"short\": true
                    }]
                }]
            }" \
            "$SLACK_WEBHOOK_URL"
        
        log_success "测试通知发送完成"
    fi
}

# 主函数
main() {
    log_info "开始自动化测试流程..."
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit-only)
                UNIT_ONLY=true
                shift
                ;;
            --integration-only)
                INTEGRATION_ONLY=true
                shift
                ;;
            --api-only)
                API_ONLY=true
                shift
                ;;
            --performance-only)
                PERFORMANCE_ONLY=true
                shift
                ;;
            --security-only)
                SECURITY_ONLY=true
                shift
                ;;
            --skip-quality)
                SKIP_QUALITY=true
                shift
                ;;
            --coverage-threshold)
                COVERAGE_THRESHOLD="$2"
                shift 2
                ;;
            --parallel-workers)
                PARALLEL_WORKERS="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    # 执行测试流程
    check_dependencies
    setup_test_environment
    start_test_database
    
    # 根据参数运行相应的测试
    if [ "$UNIT_ONLY" = true ]; then
        run_unit_tests
    elif [ "$INTEGRATION_ONLY" = true ]; then
        run_integration_tests
    elif [ "$API_ONLY" = true ]; then
        run_api_tests
    elif [ "$PERFORMANCE_ONLY" = true ]; then
        run_performance_tests
    elif [ "$SECURITY_ONLY" = true ]; then
        run_security_tests
    else
        # 运行所有测试
        run_unit_tests
        run_integration_tests
        run_api_tests
        run_performance_tests
        run_security_tests
    fi
    
    # 代码质量检查
    if [ "$SKIP_QUALITY" != true ]; then
        run_code_quality_checks
    fi
    
    # 生成报告
    generate_test_report
    
    # 发送通知
    send_test_notification
    
    # 输出结果
    log_info "测试流程完成"
    log_info "总测试: $TOTAL_TESTS, 通过: $PASSED_TESTS, 失败: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "所有测试通过！"
        exit 0
    else
        log_error "有 $FAILED_TESTS 个测试失败"
        exit 1
    fi
}

# 运行主函数
main "$@"
