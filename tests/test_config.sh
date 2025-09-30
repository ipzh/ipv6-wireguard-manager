#!/bin/bash

# 测试配置文件
# 集中管理所有测试相关配置

# =============================================================================
# 目录配置
# =============================================================================

# 获取测试目录
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
REPORT_DIR="$PROJECT_ROOT/reports"
LOG_DIR="$PROJECT_ROOT/logs"
TEMP_DIR="/tmp/ipv6wgm_test_$$"

# =============================================================================
# 测试参数配置
# =============================================================================

# 超时设置
TEST_TIMEOUT=300  # 5分钟超时
LONG_TEST_TIMEOUT=600  # 10分钟超时
QUICK_TEST_TIMEOUT=60  # 1分钟超时

# 并行设置
PARALLEL_JOBS=4
MAX_CONCURRENT_TESTS=8

# 测试模式
VERBOSE=false
DRY_RUN=false
DEBUG_MODE=false

# 报告设置
GENERATE_JSON_REPORT=true
GENERATE_HTML_REPORT=false
KEEP_OLD_REPORTS=7  # 保留7天的旧报告

# =============================================================================
# 测试套件定义
# =============================================================================

# 基础测试套件
BASIC_TEST_SUITES=(
    "syntax_check"
    "functionality_test"
    "integration_test"
)

# 完整测试套件
FULL_TEST_SUITES=(
    "syntax_check"
    "functionality_test"
    "integration_test"
    "performance_test"
    "security_test"
    "compatibility_test"
    "version_check"
    "module_test"
    "config_test"
    "monitoring_test"
    "business_function_test"
    "client_management_test"
    "exception_handling_test"
    "config_change_test"
)

# 单元测试套件
UNIT_TEST_SUITES=(
    "variable_management_test"
    "function_management_test"
    "config_management_test"
    "error_handling_test"
    "resource_monitoring_test"
)

# 集成测试套件
INTEGRATION_TEST_SUITES=(
    "module_loading_test"
    "dependency_management_test"
    "system_compatibility_test"
    "cache_performance_test"
    "parallel_performance_test"
)

# 性能测试套件
PERFORMANCE_TEST_SUITES=(
    "memory_usage_test"
    "cpu_usage_test"
    "disk_usage_test"
    "network_performance_test"
    "startup_time_test"
)

# 兼容性测试套件
COMPATIBILITY_TEST_SUITES=(
    "shell_compatibility_test"
    "os_compatibility_test"
    "architecture_compatibility_test"
    "version_compatibility_test"
)

# =============================================================================
# 测试文件映射
# =============================================================================

# 测试文件路径映射
declare -A TEST_FILE_MAP=(
    ["syntax_check"]="scripts/automated-testing.sh"
    ["functionality_test"]="scripts/automated-testing.sh"
    ["integration_test"]="scripts/automated-testing.sh"
    ["performance_test"]="scripts/automated-testing.sh"
    ["security_test"]="scripts/automated-testing.sh"
    ["compatibility_test"]="scripts/compatibility_test.sh"
    ["unit"]="tests/comprehensive_test_suite.sh"
    ["integration"]="tests/comprehensive_test_suite.sh"
    ["performance"]="tests/comprehensive_test_suite.sh"
    ["compatibility"]="tests/comprehensive_test_suite.sh"
)

# =============================================================================
# 测试环境配置
# =============================================================================

# 测试环境变量
export IPV6WGM_CONFIG_DIR="$TEMP_DIR/config"
export IPV6WGM_LOG_DIR="$TEMP_DIR/logs"
export IPV6WGM_TEMP_DIR="$TEMP_DIR"
export IPV6WGM_DEBUG_MODE="$DEBUG_MODE"
export IPV6WGM_VERBOSE_MODE="$VERBOSE"

# 测试数据库配置
TEST_DB_FILE="$TEMP_DIR/test.db"
TEST_CONFIG_FILE="$TEMP_DIR/test.conf"

# =============================================================================
# 测试阈值配置
# =============================================================================

# 性能阈值
MAX_MEMORY_USAGE=80  # 最大内存使用率(%)
MAX_CPU_USAGE=90     # 最大CPU使用率(%)
MAX_DISK_USAGE=95    # 最大磁盘使用率(%)
MAX_STARTUP_TIME=10  # 最大启动时间(秒)

# 测试超时阈值
SYNTAX_CHECK_TIMEOUT=60
FUNCTIONALITY_TEST_TIMEOUT=300
INTEGRATION_TEST_TIMEOUT=600
PERFORMANCE_TEST_TIMEOUT=900
SECURITY_TEST_TIMEOUT=300
COMPATIBILITY_TEST_TIMEOUT=600

# =============================================================================
# 测试报告配置
# =============================================================================

# 报告格式
REPORT_FORMATS=("txt" "json")
if [[ "$GENERATE_HTML_REPORT" == "true" ]]; then
    REPORT_FORMATS+=("html")
fi

# 报告模板
REPORT_TEMPLATE_DIR="$TEST_DIR/templates"
REPORT_CSS_FILE="$REPORT_TEMPLATE_DIR/style.css"
REPORT_JS_FILE="$REPORT_TEMPLATE_DIR/script.js"

# =============================================================================
# 测试数据配置
# =============================================================================

# 测试数据目录
TEST_DATA_DIR="$TEST_DIR/data"
SAMPLE_CONFIG_DIR="$TEST_DATA_DIR/sample_configs"
TEST_CERT_DIR="$TEST_DATA_DIR/certificates"

# 测试数据文件
SAMPLE_CONFIG_FILE="$SAMPLE_CONFIG_DIR/manager.conf"
SAMPLE_CLIENT_CONFIG="$SAMPLE_CONFIG_DIR/client.conf"
TEST_CERT_FILE="$TEST_CERT_DIR/test.crt"
TEST_KEY_FILE="$TEST_CERT_DIR/test.key"

# =============================================================================
# 测试工具配置
# =============================================================================

# 外部工具路径
CURL_BIN="curl"
WGET_BIN="wget"
JQ_BIN="jq"
DOCKER_BIN="docker"
SHELLCHECK_BIN="shellcheck"

# 工具参数
CURL_TIMEOUT=30
WGET_TIMEOUT=30
DOCKER_TIMEOUT=300

# =============================================================================
# 测试网络配置
# =============================================================================

# 测试网络设置
TEST_NETWORK="10.0.0.0/24"
TEST_IPV6_NETWORK="fd00:dead:beef::/64"
TEST_DNS_SERVERS="8.8.8.8,2001:4860:4860::8888"

# 测试端口范围
TEST_PORT_START=51820
TEST_PORT_END=51830

# =============================================================================
# 测试清理配置
# =============================================================================

# 清理设置
CLEANUP_TEMP_FILES=true
CLEANUP_OLD_REPORTS=true
CLEANUP_TEST_DATABASES=true
CLEANUP_TEST_CERTIFICATES=true

# 清理时间阈值
CLEANUP_OLD_THRESHOLD=7  # 天
CLEANUP_LARGE_FILE_THRESHOLD=100M  # 大文件阈值

# =============================================================================
# 配置验证函数
# =============================================================================

# 验证测试配置
validate_test_config() {
    local errors=0
    
    log_info "验证测试配置..."
    
    # 检查必要目录
    local required_dirs=("$TEST_DIR" "$PROJECT_ROOT" "$REPORT_DIR")
    for dir in "${required_dirs[@]}"; do
        if ! [[ -d "$dir" ]]; then
            log_error "缺少必要目录: $dir"
            ((errors++))
        fi
    done
    
    # 检查必要文件
    local required_files=("$PROJECT_ROOT/ipv6-wireguard-manager.sh")
    for file in "${required_files[@]}"; do
        if ! [[ -f "$file" ]]; then
            log_error "缺少必要文件: $file"
            ((errors++))
        fi
    done
    
    # 检查工具可用性
    local required_tools=("bash" "curl" "wget")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "缺少必要工具: $tool"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "测试配置验证通过"
        return 0
    else
        log_error "测试配置验证失败: $errors 个错误"
        return 1
    fi
}

# =============================================================================
# 配置加载函数
# =============================================================================

# 加载测试配置
load_test_config() {
    local config_file="${1:-$TEST_DIR/test_config.yml}"
    
    if [[ -f "$config_file" ]]; then
        log_info "加载测试配置文件: $config_file"
        # 这里可以添加YAML解析逻辑
        # 目前使用默认配置
    else
        log_warn "测试配置文件不存在: $config_file，使用默认配置"
    fi
}

# =============================================================================
# 导出变量和函数
# =============================================================================

export TEST_DIR PROJECT_ROOT REPORT_DIR LOG_DIR TEMP_DIR
export TEST_TIMEOUT LONG_TEST_TIMEOUT QUICK_TEST_TIMEOUT
export PARALLEL_JOBS MAX_CONCURRENT_TESTS
export VERBOSE DRY_RUN DEBUG_MODE
export GENERATE_JSON_REPORT GENERATE_HTML_REPORT KEEP_OLD_REPORTS
export IPV6WGM_CONFIG_DIR IPV6WGM_LOG_DIR IPV6WGM_TEMP_DIR
export IPV6WGM_DEBUG_MODE IPV6WGM_VERBOSE_MODE

export -f validate_test_config load_test_config
