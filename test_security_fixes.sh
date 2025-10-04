#!/bin/bash

# 安全修复验证测试脚本
# 验证所有安全修复是否正常工作

# 统一错误处理设置
set -Eeuo pipefail

# 导入统一安全修复模块
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/modules/unified_security_fixes.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/modules/unified_security_fixes.sh"
fi

# 设置统一的错误处理
trap 'handle_error $? "测试脚本执行错误" "security_test.sh" $LINENO' ERR

# 测试结果统计
declare -A TEST_RESULTS=(
    ["total"]=0
    ["passed"]=0
    ["failed"]=0
)

# 测试函数
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo "运行测试: $test_name"
    TEST_RESULTS["total"]=$((TEST_RESULTS["total"] + 1))
    
    if $test_function; then
        echo "✓ 测试通过: $test_name"
        TEST_RESULTS["passed"]=$((TEST_RESULTS["passed"] + 1))
        return 0
    else
        echo "✗ 测试失败: $test_name"
        TEST_RESULTS["failed"]=$((TEST_RESULTS["failed"] + 1))
        return 1
    fi
}

# =============================================================================
# 错误处理测试
# =============================================================================

test_error_handling() {
    echo "测试错误处理..."
    
    # 测试handle_error函数是否存在
    if ! declare -f handle_error >/dev/null 2>&1; then
        echo "错误: handle_error函数不存在"
        return 1
    fi
    
    # 测试cleanup_on_error函数是否存在
    if ! declare -f cleanup_on_error >/dev/null 2>&1; then
        echo "错误: cleanup_on_error函数不存在"
        return 1
    fi
    
    echo "错误处理函数存在"
    return 0
}

# =============================================================================
# 安全文件删除测试
# =============================================================================

test_safe_rm() {
    echo "测试安全文件删除..."
    
    # 测试safe_rm函数是否存在
    if ! declare -f safe_rm >/dev/null 2>&1; then
        echo "错误: safe_rm函数不存在"
        return 1
    fi
    
    # 创建测试文件
    local test_file="/tmp/security_test_$$"
    echo "test content" > "$test_file"
    
    # 测试正常删除
    if safe_rm "$test_file" true false; then
        echo "正常删除测试通过"
    else
        echo "正常删除测试失败"
        return 1
    fi
    
    # 测试拒绝删除根目录
    if safe_rm "/" true false 2>/dev/null; then
        echo "错误: 应该拒绝删除根目录"
        return 1
    else
        echo "根目录保护测试通过"
    fi
    
    # 测试拒绝删除系统目录
    if safe_rm "/etc" true false 2>/dev/null; then
        echo "错误: 应该拒绝删除系统目录"
        return 1
    else
        echo "系统目录保护测试通过"
    fi
    
    # 测试空参数
    if safe_rm "" true false 2>/dev/null; then
        echo "错误: 应该拒绝空参数"
        return 1
    else
        echo "空参数保护测试通过"
    fi
    
    return 0
}

# =============================================================================
# 安全命令执行测试
# =============================================================================

test_safe_execute() {
    echo "测试安全命令执行..."
    
    # 测试safe_execute函数是否存在
    if ! declare -f safe_execute >/dev/null 2>&1; then
        echo "错误: safe_execute函数不存在"
        return 1
    fi
    
    # 测试正常命令执行
    if safe_execute "测试命令" "false" echo "hello world" >/dev/null; then
        echo "正常命令执行测试通过"
    else
        echo "正常命令执行测试失败"
        return 1
    fi
    
    # 测试失败命令处理
    if safe_execute "失败命令" "true" false >/dev/null; then
        echo "失败命令处理测试通过"
    else
        echo "失败命令处理测试失败"
        return 1
    fi
    
    return 0
}

test_safe_bash_exec() {
    echo "测试安全bash执行..."
    
    # 测试safe_bash_exec函数是否存在
    if ! declare -f safe_bash_exec >/dev/null 2>&1; then
        echo "错误: safe_bash_exec函数不存在"
        return 1
    fi
    
    # 测试正常模板执行
    if safe_bash_exec "echo 'hello world'" "测试模板" "false" >/dev/null; then
        echo "正常模板执行测试通过"
    else
        echo "正常模板执行测试失败"
        return 1
    fi
    
    # 测试危险字符拒绝
    if safe_bash_exec "echo 'hello'; rm -rf /" "危险模板" "false" 2>/dev/null; then
        echo "错误: 应该拒绝危险字符"
        return 1
    else
        echo "危险字符保护测试通过"
    fi
    
    return 0
}

# =============================================================================
# 安全下载测试
# =============================================================================

test_safe_download() {
    echo "测试安全下载..."
    
    # 测试safe_download函数是否存在
    if ! declare -f safe_download >/dev/null 2>&1; then
        echo "错误: safe_download函数不存在"
        return 1
    fi
    
    # 测试verify_file_hash函数是否存在
    if ! declare -f verify_file_hash >/dev/null 2>&1; then
        echo "错误: verify_file_hash函数不存在"
        return 1
    fi
    
    # 测试空参数
    if safe_download "" "" 2>/dev/null; then
        echo "错误: 应该拒绝空参数"
        return 1
    else
        echo "空参数保护测试通过"
    fi
    
    # 测试无效URL
    if safe_download "invalid://url" "/tmp/test" 2>/dev/null; then
        echo "错误: 应该拒绝无效URL"
        return 1
    else
        echo "无效URL保护测试通过"
    fi
    
    return 0
}

# =============================================================================
# Windows兼容性测试
# =============================================================================

test_windows_compatibility() {
    echo "测试Windows兼容性..."
    
    # 测试detect_unified_windows_env函数是否存在
    if ! declare -f detect_unified_windows_env >/dev/null 2>&1; then
        echo "错误: detect_unified_windows_env函数不存在"
        return 1
    fi
    
    # 测试convert_unified_path函数是否存在
    if ! declare -f convert_unified_path >/dev/null 2>&1; then
        echo "错误: convert_unified_path函数不存在"
        return 1
    fi
    
    # 测试环境检测
    if detect_unified_windows_env; then
        echo "Windows环境检测测试通过"
    else
        echo "Linux环境检测测试通过"
    fi
    
    # 测试路径转换
    local test_path="/tmp/test"
    local converted_path=$(convert_unified_path "$test_path")
    if [[ -n "$converted_path" ]]; then
        echo "路径转换测试通过: $test_path -> $converted_path"
    else
        echo "路径转换测试失败"
        return 1
    fi
    
    return 0
}

# =============================================================================
# 模块加载测试
# =============================================================================

test_module_loading() {
    echo "测试模块加载..."
    
    # 测试load_module_unified函数是否存在
    if ! declare -f load_module_unified >/dev/null 2>&1; then
        echo "错误: load_module_unified函数不存在"
        return 1
    fi
    
    # 测试import_module兼容性函数是否存在
    if ! declare -f import_module >/dev/null 2>&1; then
        echo "错误: import_module兼容性函数不存在"
        return 1
    fi
    
    # 测试加载不存在的模块
    if load_module_unified "nonexistent_module" 2>/dev/null; then
        echo "错误: 应该拒绝加载不存在的模块"
        return 1
    else
        echo "不存在模块保护测试通过"
    fi
    
    return 0
}

# =============================================================================
# eval使用检查测试
# =============================================================================

test_eval_usage() {
    echo "测试eval使用检查..."
    
    local eval_count=0
    local files_with_eval=()
    
    # 检查所有.sh文件中的eval使用
    while IFS= read -r -d '' file; do
        if grep -q "eval" "$file"; then
            local count
            count=$(grep -c "eval" "$file")
            eval_count=$((eval_count + count))
            files_with_eval+=("$file")
        fi
    done < <(find . -name "*.sh" -type f -print0)
    
    if [[ $eval_count -gt 0 ]]; then
        echo "警告: 发现 $eval_count 个eval使用"
        for file in "${files_with_eval[@]}"; do
            echo "  - $file"
        done
        echo "建议: 使用safe_execute或safe_bash_exec替代eval"
        return 1
    else
        echo "eval使用检查通过"
        return 0
    fi
}

# =============================================================================
# rm -rf使用检查测试
# =============================================================================

test_rm_usage() {
    echo "测试rm -rf使用检查..."
    
    local rm_count=0
    local files_with_rm=()
    
    # 检查所有.sh文件中的rm -rf使用
    while IFS= read -r -d '' file; do
        if grep -q "rm -rf" "$file"; then
            local count
            count=$(grep -c "rm -rf" "$file")
            rm_count=$((rm_count + count))
            files_with_rm+=("$file")
        fi
    done < <(find . -name "*.sh" -type f -print0)
    
    if [[ $rm_count -gt 0 ]]; then
        echo "警告: 发现 $rm_count 个rm -rf使用"
        for file in "${files_with_rm[@]}"; do
            echo "  - $file"
        done
        echo "建议: 使用safe_rm替代rm -rf"
        return 1
    else
        echo "rm -rf使用检查通过"
        return 0
    fi
}

# =============================================================================
# curl | bash使用检查测试
# =============================================================================

test_curl_bash_usage() {
    echo "测试curl | bash使用检查..."
    
    local curl_bash_count=0
    local files_with_curl_bash=()
    
    # 检查所有文件中的curl | bash使用
    while IFS= read -r -d '' file; do
        if grep -q "curl.*bash" "$file"; then
            local count
            count=$(grep -c "curl.*bash" "$file")
            curl_bash_count=$((curl_bash_count + count))
            files_with_curl_bash+=("$file")
        fi
    done < <(find . -name "*.sh" -o -name "*.md" -type f -print0)
    
    if [[ $curl_bash_count -gt 0 ]]; then
        echo "警告: 发现 $curl_bash_count 个curl | bash使用"
        for file in "${files_with_curl_bash[@]}"; do
            echo "  - $file"
        done
        echo "建议: 使用safe_download替代curl | bash"
        return 1
    else
        echo "curl | bash使用检查通过"
        return 0
    fi
}

# =============================================================================
# 主测试函数
# =============================================================================

main() {
    echo "开始安全修复验证测试..."
    echo "=================================="
    
    # 运行所有测试
    run_test "错误处理" test_error_handling
    run_test "安全文件删除" test_safe_rm
    run_test "安全命令执行" test_safe_execute
    run_test "安全bash执行" test_safe_bash_exec
    run_test "安全下载" test_safe_download
    run_test "Windows兼容性" test_windows_compatibility
    run_test "模块加载" test_module_loading
    run_test "eval使用检查" test_eval_usage
    run_test "rm -rf使用检查" test_rm_usage
    run_test "curl | bash使用检查" test_curl_bash_usage
    
    echo "=================================="
    echo "测试结果汇总:"
    echo "总测试数: ${TEST_RESULTS["total"]}"
    echo "通过: ${TEST_RESULTS["passed"]}"
    echo "失败: ${TEST_RESULTS["failed"]}"
    
    if [[ ${TEST_RESULTS["failed"]} -eq 0 ]]; then
        echo "✓ 所有安全修复测试通过！"
        return 0
    else
        echo "✗ 部分测试失败，请检查上述警告"
        return 1
    fi
}

# 运行主函数
main "$@"
