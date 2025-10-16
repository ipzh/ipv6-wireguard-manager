#!/bin/bash

# IPv6 WireGuard Manager - 诊断工具测试脚本
# 测试所有诊断工具是否正常工作

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

log_section() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# 测试结果
TESTS_PASSED=0
TESTS_FAILED=0

# 添加测试结果
add_test_result() {
    local test_name="$1"
    local result="$2"
    
    if [[ "$result" == "PASS" ]]; then
        log_success "✓ $test_name"
        ((TESTS_PASSED++))
    else
        log_error "✗ $test_name"
        ((TESTS_FAILED++))
    fi
}

# 测试脚本存在性
test_script_existence() {
    log_section "测试脚本存在性"
    
    local scripts=(
        "deep_api_diagnosis.sh"
        "deep_code_analysis.py"
        "comprehensive_api_diagnosis.sh"
        "quick_fix_wireguard_permissions.sh"
        "fix_permissions.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            add_test_result "脚本存在: $script" "PASS"
        else
            add_test_result "脚本存在: $script" "FAIL"
        fi
    done
}

# 测试脚本权限
test_script_permissions() {
    log_section "测试脚本权限"
    
    local scripts=(
        "deep_api_diagnosis.sh"
        "comprehensive_api_diagnosis.sh"
        "quick_fix_wireguard_permissions.sh"
        "fix_permissions.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
            if [[ -x "$script" ]]; then
                add_test_result "脚本权限: $script" "PASS"
            else
                add_test_result "脚本权限: $script" "FAIL"
            fi
        fi
    done
}

# 测试Python环境
test_python_environment() {
    log_section "测试Python环境"
    
    if command -v python3 &>/dev/null; then
        local python_version=$(python3 --version 2>&1)
        log_info "Python版本: $python_version"
        add_test_result "Python3可用" "PASS"
        
        # 测试Python脚本
        if [[ -f "deep_code_analysis.py" ]]; then
            if python3 -c "import ast, importlib.util, pathlib, traceback" 2>/dev/null; then
                add_test_result "Python依赖模块" "PASS"
            else
                add_test_result "Python依赖模块" "FAIL"
            fi
        fi
    else
        add_test_result "Python3可用" "FAIL"
    fi
}

# 测试系统命令
test_system_commands() {
    log_section "测试系统命令"
    
    local commands=(
        "systemctl"
        "curl"
        "netstat"
        "mysql"
        "nginx"
    )
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            add_test_result "系统命令: $cmd" "PASS"
        else
            add_test_result "系统命令: $cmd" "FAIL"
        fi
    done
}

# 测试诊断脚本语法
test_script_syntax() {
    log_section "测试脚本语法"
    
    local scripts=(
        "deep_api_diagnosis.sh"
        "comprehensive_api_diagnosis.sh"
        "quick_fix_wireguard_permissions.sh"
        "fix_permissions.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if bash -n "$script" 2>/dev/null; then
                add_test_result "脚本语法: $script" "PASS"
            else
                add_test_result "脚本语法: $script" "FAIL"
            fi
        fi
    done
}

# 测试Python脚本语法
test_python_syntax() {
    log_section "测试Python脚本语法"
    
    if [[ -f "deep_code_analysis.py" ]]; then
        if python3 -m py_compile "deep_code_analysis.py" 2>/dev/null; then
            add_test_result "Python脚本语法: deep_code_analysis.py" "PASS"
        else
            add_test_result "Python脚本语法: deep_code_analysis.py" "FAIL"
        fi
    fi
}

# 测试脚本功能（干运行）
test_script_functionality() {
    log_section "测试脚本功能（干运行）"
    
    # 测试深度诊断脚本（只检查帮助信息）
    if [[ -f "deep_api_diagnosis.sh" ]]; then
        if bash -c "source deep_api_diagnosis.sh; echo 'Script loaded successfully'" 2>/dev/null; then
            add_test_result "深度诊断脚本加载" "PASS"
        else
            add_test_result "深度诊断脚本加载" "FAIL"
        fi
    fi
    
    # 测试综合诊断脚本
    if [[ -f "comprehensive_api_diagnosis.sh" ]]; then
        if bash -c "source comprehensive_api_diagnosis.sh; echo 'Script loaded successfully'" 2>/dev/null; then
            add_test_result "综合诊断脚本加载" "PASS"
        else
            add_test_result "综合诊断脚本加载" "FAIL"
        fi
    fi
    
    # 测试Python脚本导入
    if [[ -f "deep_code_analysis.py" ]]; then
        if python3 -c "import sys; sys.path.insert(0, '.'); import deep_code_analysis; print('Module imported successfully')" 2>/dev/null; then
            add_test_result "Python脚本导入" "PASS"
        else
            add_test_result "Python脚本导入" "FAIL"
        fi
    fi
}

# 测试文档文件
test_documentation() {
    log_section "测试文档文件"
    
    local docs=(
        "README.md"
        "DIAGNOSIS_TOOLS_GUIDE.md"
        "INSTALLATION_GUIDE.md"
    )
    
    for doc in "${docs[@]}"; do
        if [[ -f "$doc" ]]; then
            add_test_result "文档文件: $doc" "PASS"
        else
            add_test_result "文档文件: $doc" "FAIL"
        fi
    done
}

# 显示测试结果
show_test_results() {
    log_section "测试结果汇总"
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    
    echo "测试统计:"
    echo "  总测试数: $total_tests"
    echo "  通过: $TESTS_PASSED"
    echo "  失败: $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "🎉 所有测试通过！"
        echo ""
        log_info "诊断工具已准备就绪，可以开始使用："
        echo ""
        echo "1. 综合诊断（推荐）:"
        echo "   ./comprehensive_api_diagnosis.sh"
        echo ""
        echo "2. 系统诊断:"
        echo "   ./deep_api_diagnosis.sh"
        echo ""
        echo "3. 代码分析:"
        echo "   python3 deep_code_analysis.py"
        echo ""
        echo "4. 权限修复:"
        echo "   ./quick_fix_wireguard_permissions.sh"
        echo ""
        return 0
    else
        log_error "❌ 发现 $TESTS_FAILED 个测试失败"
        echo ""
        log_info "请检查失败的测试项并修复问题"
        return 1
    fi
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 诊断工具测试"
    echo ""
    
    # 运行所有测试
    test_script_existence
    echo ""
    
    test_script_permissions
    echo ""
    
    test_python_environment
    echo ""
    
    test_system_commands
    echo ""
    
    test_script_syntax
    echo ""
    
    test_python_syntax
    echo ""
    
    test_script_functionality
    echo ""
    
    test_documentation
    echo ""
    
    # 显示结果
    show_test_results
}

# 运行主函数
main "$@"
