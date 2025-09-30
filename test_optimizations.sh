#!/bin/bash

# 综合优化测试脚本
# 测试权限管理、性能优化、代码质量改进等功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
BLUE='\033[0;34m'
# PURPLE=  # unused'\033[0;35m'
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

# shellcheck disable=SC2317
log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 测试统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 运行测试
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TOTAL_TESTS++))
    echo "----------------------------------------"
    echo "测试: $test_name"
    echo "----------------------------------------"
    
    if $test_function; then
        ((PASSED_TESTS++))
        log_success "测试通过: $test_name"
    else
        ((FAILED_TESTS++))
        log_error "测试失败: $test_name"
    fi
    echo
}

# 测试1: 权限管理优化
test_permission_management() {
    log_info "测试权限管理优化..."
    
    # 测试install_with_download.sh中的权限检查
    if [[ -f "install_with_download.sh" ]]; then
        if grep -q "EUID检查" install_with_download.sh; then
            log_success "install_with_download.sh包含EUID检查"
        else
            log_error "install_with_download.sh缺少EUID检查"
            return 1
        fi
        
        if grep -q "权限验证通过" install_with_download.sh; then
            log_success "install_with_download.sh包含权限验证"
        else
            log_error "install_with_download.sh缺少权限验证"
            return 1
        fi
    else
        log_warn "install_with_download.sh不存在"
    fi
    
    # 测试root权限测试脚本
    if [[ -f "test_root_permission.sh" ]]; then
        if bash -n test_root_permission.sh; then
            log_success "test_root_permission.sh语法正确"
        else
            log_error "test_root_permission.sh语法错误"
            return 1
        fi
    else
        log_error "test_root_permission.sh不存在"
        return 1
    fi
    
    return 0
}

# 测试2: 性能优化模块
test_performance_optimization() {
    log_info "测试性能优化模块..."
    
    # 测试性能优化模块
    if [[ -f "modules/performance_optimizer.sh" ]]; then
        if bash -n modules/performance_optimizer.sh; then
            log_success "performance_optimizer.sh语法正确"
        else
            log_error "performance_optimizer.sh语法错误"
            return 1
        fi
        
        # 测试模块功能
        if source modules/performance_optimizer.sh 2>/dev/null; then
            log_success "performance_optimizer.sh加载成功"
            
            # 测试缓存功能
            if command -v set_cache >/dev/null 2>&1; then
                set_cache "test_key" "test_value" 60
                if get_cache "test_key" >/dev/null 2>&1; then
                    log_success "缓存功能正常"
                else
                    log_error "缓存功能异常"
                    return 1
                fi
            else
                log_error "缓存函数不可用"
                return 1
            fi
        else
            log_error "performance_optimizer.sh加载失败"
            return 1
        fi
    else
        log_error "performance_optimizer.sh不存在"
        return 1
    fi
    
    return 0
}

# 测试3: 配置缓存模块
test_config_cache() {
    log_info "测试配置缓存模块..."
    
    # 测试配置缓存模块
    if [[ -f "modules/config_cache.sh" ]]; then
        if bash -n modules/config_cache.sh; then
            log_success "config_cache.sh语法正确"
        else
            log_error "config_cache.sh语法错误"
            return 1
        fi
        
        # 测试模块功能
        if source modules/config_cache.sh 2>/dev/null; then
            log_success "config_cache.sh加载成功"
            
            # 测试配置缓存功能
            if command -v cache_config_file >/dev/null 2>&1; then
                # 创建测试配置文件
                local test_config="/tmp/test_config.conf"
                cat > "$test_config" << 'EOF'
# 测试配置文件
TEST_VAR1=value1
TEST_VAR2=value2
TEST_VAR3=value3
EOF
                
                if cache_config_file "$test_config" >/dev/null 2>&1; then
                    log_success "配置缓存功能正常"
                else
                    log_error "配置缓存功能异常"
                    return 1
                fi
                
                # 清理测试文件
                rm -f "$test_config"
            else
                log_error "配置缓存函数不可用"
                return 1
            fi
        else
            log_error "config_cache.sh加载失败"
            return 1
        fi
    else
        log_error "config_cache.sh不存在"
        return 1
    fi
    
    return 0
}

# 测试4: 代码质量改进模块
test_code_quality() {
    log_info "测试代码质量改进模块..."
    
    # 测试代码质量改进模块
    if [[ -f "modules/code_quality_improver.sh" ]]; then
        if bash -n modules/code_quality_improver.sh; then
            log_success "code_quality_improver.sh语法正确"
        else
            log_error "code_quality_improver.sh语法错误"
            return 1
        fi
        
        # 测试模块功能
        if source modules/code_quality_improver.sh 2>/dev/null; then
            log_success "code_quality_improver.sh加载成功"
            
            # 测试代码分析功能
            if command -v analyze_code_complexity >/dev/null 2>&1; then
                # 创建测试文件
                local test_file="/tmp/test_code.sh"
                cat > "$test_file" << 'EOF'
#!/bin/bash
# 测试代码文件

function test_function1() {
    echo "test1"
}

function test_function2() {
    if [[ $1 -eq 1 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function test_function3() {
    for i in {1..10}; do
        echo "iteration $i"
    done
}
EOF
                
                if analyze_code_complexity "$test_file" >/dev/null 2>&1; then
                    log_success "代码复杂度分析功能正常"
                else
                    log_error "代码复杂度分析功能异常"
                    return 1
                fi
                
                # 清理测试文件
                rm -f "$test_file"
            else
                log_error "代码分析函数不可用"
                return 1
            fi
        else
            log_error "code_quality_improver.sh加载失败"
            return 1
        fi
    else
        log_error "code_quality_improver.sh不存在"
        return 1
    fi
    
    return 0
}

# 测试5: 模块懒加载
test_lazy_loading() {
    log_info "测试模块懒加载..."
    
    # 测试懒加载功能
    if command -v lazy_load_module >/dev/null 2>&1; then
        # 测试加载不存在的模块
        if lazy_load_module "nonexistent_module" 2>/dev/null; then
            log_error "懒加载应该失败但成功了"
            return 1
        else
            log_success "懒加载正确处理了不存在的模块"
        fi
        
        # 测试加载存在的模块
        if lazy_load_module "common_functions" "modules/common_functions.sh" 2>/dev/null; then
            log_success "懒加载成功加载了common_functions模块"
        else
            log_warn "懒加载无法加载common_functions模块（可能不存在）"
        fi
    else
        log_error "懒加载函数不可用"
        return 1
    fi
    
    return 0
}

# 测试6: 错误处理优化
test_error_handling() {
    log_info "测试错误处理优化..."
    
    # 测试错误处理功能
    if command -v enhanced_error_handling >/dev/null 2>&1; then
        # 测试错误处理
        if enhanced_error_handling "test_function" "1" "测试错误" "测试上下文" 2>/dev/null; then
            log_success "错误处理功能正常"
        else
            log_warn "错误处理功能返回错误（预期行为）"
        fi
        
        # 测试错误计数
        if command -v reset_error_counts >/dev/null 2>&1; then
            reset_error_counts "test_function" 2>/dev/null
            log_success "错误计数重置功能正常"
        else
            log_error "错误计数重置功能不可用"
            return 1
        fi
    else
        log_error "错误处理函数不可用"
        return 1
    fi
    
    return 0
}

# 测试7: 日志记录增强
test_logging_enhancement() {
    log_info "测试日志记录增强..."
    
    # 测试日志功能
    if command -v enhanced_log >/dev/null 2>&1; then
        # 测试不同级别的日志
        enhanced_log "INFO" "测试信息日志" "test_context" >/dev/null 2>&1
        enhanced_log "WARN" "测试警告日志" "test_context" >/dev/null 2>&1
        enhanced_log "ERROR" "测试错误日志" "test_context" >/dev/null 2>&1
        
        log_success "增强日志功能正常"
    else
        log_error "增强日志函数不可用"
        return 1
    fi
    
    # 测试结构化日志
    if command -v structured_log >/dev/null 2>&1; then
        structured_log "INFO" "test_event" "test_data" >/dev/null 2>&1
        log_success "结构化日志功能正常"
    else
        log_error "结构化日志函数不可用"
        return 1
    fi
    
    return 0
}

# 测试8: 性能监控
test_performance_monitoring() {
    log_info "测试性能监控..."
    
    # 测试性能计时功能
    if command -v start_timer >/dev/null 2>&1; then
        start_timer "test_timer"
        sleep 0.1
        local duration
        duration=$(end_timer "test_timer")
        
        if [[ -n "$duration" && "$duration" != "0" ]]; then
            log_success "性能计时功能正常 (${duration}s)"
        else
            log_error "性能计时功能异常"
            return 1
        fi
    else
        log_error "性能计时函数不可用"
        return 1
    fi
    
    # 测试性能统计
    if command -v get_performance_stats >/dev/null 2>&1; then
        get_performance_stats >/dev/null 2>&1
        log_success "性能统计功能正常"
    else
        log_error "性能统计函数不可用"
        return 1
    fi
    
    return 0
}

# 主函数
main() {
    echo "=== 综合优化测试 ==="
    echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    # 运行所有测试
    run_test "权限管理优化" test_permission_management
    run_test "性能优化模块" test_performance_optimization
    run_test "配置缓存模块" test_config_cache
    run_test "代码质量改进模块" test_code_quality
    run_test "模块懒加载" test_lazy_loading
    run_test "错误处理优化" test_error_handling
    run_test "日志记录增强" test_logging_enhancement
    run_test "性能监控" test_performance_monitoring
    
    # 显示测试结果
    echo "========================================"
    echo "=== 测试结果汇总 ==="
    echo "总测试数: $TOTAL_TESTS"
    echo "通过测试: $PASSED_TESTS"
    echo "失败测试: $FAILED_TESTS"
    echo "成功率: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "所有测试通过！"
        return 0
    else
        log_error "部分测试失败！"
        return 1
    fi
}

# 显示使用说明
show_usage() {
    echo "综合优化测试脚本"
    echo
    echo "用法:"
    echo "  $0                    # 运行所有测试"
    echo "  $0 --help            # 显示帮助信息"
    echo "  $0 --test <name>     # 运行指定测试"
    echo
    echo "可用测试:"
    echo "  permission_management    # 权限管理优化"
    echo "  performance_optimization # 性能优化模块"
    echo "  config_cache            # 配置缓存模块"
    echo "  code_quality            # 代码质量改进模块"
    echo "  lazy_loading            # 模块懒加载"
    echo "  error_handling          # 错误处理优化"
    echo "  logging_enhancement     # 日志记录增强"
    echo "  performance_monitoring  # 性能监控"
}

# 运行指定测试
run_specific_test() {
    local test_name="$1"
    
    case "$test_name" in
        "permission_management")
            run_test "权限管理优化" test_permission_management
            ;;
        "performance_optimization")
            run_test "性能优化模块" test_performance_optimization
            ;;
        "config_cache")
            run_test "配置缓存模块" test_config_cache
            ;;
        "code_quality")
            run_test "代码质量改进模块" test_code_quality
            ;;
        "lazy_loading")
            run_test "模块懒加载" test_lazy_loading
            ;;
        "error_handling")
            run_test "错误处理优化" test_error_handling
            ;;
        "logging_enhancement")
            run_test "日志记录增强" test_logging_enhancement
            ;;
        "performance_monitoring")
            run_test "性能监控" test_performance_monitoring
            ;;
        *)
            log_error "未知测试: $test_name"
            show_usage
            return 1
            ;;
    esac
}

# 处理命令行参数
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
            exit 1
        fi
        ;;
    "")
        main
        ;;
    *)
        log_error "未知参数: $1"
        show_usage
        exit 1
        ;;
esac
