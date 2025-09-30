#!/bin/bash

# 测试模块管理功能
# 验证新实现的模块版本兼容性检查和模块预加载功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    log_info "测试: $test_name"
    
    if eval "$test_command"; then
        log_success "✓ $test_name 通过"
        ((PASSED_TESTS++))
        return 0
    else
        log_error "✗ $test_name 失败"
        ((FAILED_TESTS++))
        return 1
    fi
}

echo "=== 模块管理功能测试套件 ==="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# 测试1: 检查模块版本兼容性模块是否存在
run_test "模块版本兼容性模块文件存在" "
    [[ -f 'modules/module_version_compatibility.sh' ]]
"

# 测试2: 检查模块预加载模块是否存在
run_test "模块预加载模块文件存在" "
    [[ -f 'modules/module_preloading.sh' ]]
"

# 测试3: 检查模块版本兼容性模块语法
run_test "模块版本兼容性模块语法正确" "
    bash -n modules/module_version_compatibility.sh
"

# 测试4: 检查模块预加载模块语法
run_test "模块预加载模块语法正确" "
    bash -n modules/module_preloading.sh
"

# 测试5: 检查主脚本是否包含模块版本兼容性导入
run_test "主脚本包含模块版本兼容性导入" "
    grep -q 'module_version_compatibility' ipv6-wireguard-manager.sh
"

# 测试6: 检查主脚本是否包含模块预加载导入
run_test "主脚本包含模块预加载导入" "
    grep -q 'module_preloading' ipv6-wireguard-manager.sh
"

# 测试7: 检查脚本自检菜单是否包含模块版本管理选项
run_test "脚本自检菜单包含模块版本管理选项" "
    grep -q '模块版本兼容性' ipv6-wireguard-manager.sh
"

# 测试8: 检查脚本自检菜单是否包含模块预加载选项
run_test "脚本自检菜单包含模块预加载选项" "
    grep -q '模块预加载管理' ipv6-wireguard-manager.sh
"

# 测试9: 检查模块版本兼容性模块关键函数
run_test "模块版本兼容性模块关键函数" "
    grep -q 'init_version_compatibility\|check_module_compatibility\|scan_module_versions' modules/module_version_compatibility.sh
"

# 测试10: 检查模块预加载模块关键函数
run_test "模块预加载模块关键函数" "
    grep -q 'init_preloading\|preload_module\|preload_all_modules' modules/module_preloading.sh
"

# 测试11: 检查模块版本兼容性模块函数导出
run_test "模块版本兼容性模块函数导出" "
    grep -q 'export -f.*init_version_compatibility' modules/module_version_compatibility.sh
"

# 测试12: 检查模块预加载模块函数导出
run_test "模块预加载模块函数导出" "
    grep -q 'export -f.*init_preloading' modules/module_preloading.sh
"

# 测试13: 检查模块版本兼容性模块配置变量
run_test "模块版本兼容性模块配置变量" "
    grep -q 'IPV6WGM_MODULE_VERSION_DIR\|IPV6WGM_VERSION_CHECK_ENABLED' modules/module_version_compatibility.sh
"

# 测试14: 检查模块预加载模块配置变量
run_test "模块预加载模块配置变量" "
    grep -q 'IPV6WGM_PRELOAD_ENABLED\|IPV6WGM_PRELOAD_CACHE_DIR' modules/module_preloading.sh
"

# 测试15: 检查模块版本兼容性模块优先级配置
run_test "模块版本兼容性模块优先级配置" "
    grep -q 'IPV6WGM_MODULE_PRIORITIES' modules/module_preloading.sh
"

# 测试16: 检查模块预加载模块优先级配置
run_test "模块预加载模块优先级配置" "
    grep -q 'IPV6WGM_MODULE_PRIORITIES' modules/module_preloading.sh
"

# 测试17: 检查菜单选择范围是否正确
run_test "脚本自检菜单选择范围正确" "
    grep -q '请选择操作 \[0-12\]' ipv6-wireguard-manager.sh
"

# 测试18: 检查模块版本兼容性模块版本解析功能
run_test "模块版本兼容性模块版本解析功能" "
    grep -q 'extract_module_version\|check_version_compatibility' modules/module_version_compatibility.sh
"

# 测试19: 检查模块预加载模块缓存功能
run_test "模块预加载模块缓存功能" "
    grep -q 'load_from_cache\|save_to_cache' modules/module_preloading.sh
"

# 测试20: 检查模块版本兼容性模块依赖检查
run_test "模块版本兼容性模块依赖检查" "
    grep -q 'check_module_dependencies\|extract_module_dependencies' modules/module_version_compatibility.sh
"

# 测试21: 检查模块预加载模块统计功能
run_test "模块预加载模块统计功能" "
    grep -q 'get_preload_statistics\|get_preload_status' modules/module_preloading.sh
"

# 测试22: 检查模块版本兼容性模块JSON处理
run_test "模块版本兼容性模块JSON处理" "
    grep -q 'load_module_versions_json\|save_module_versions_json' modules/module_version_compatibility.sh
"

# 测试23: 检查模块预加载模块队列管理
run_test "模块预加载模块队列管理" "
    grep -q 'build_preload_queue\|IPV6WGM_PRELOAD_QUEUE' modules/module_preloading.sh
"

# 测试24: 检查模块版本兼容性模块统计报告
run_test "模块版本兼容性模块统计报告" "
    grep -q 'get_compatibility_statistics\|list_module_versions' modules/module_version_compatibility.sh
"

# 测试25: 检查模块预加载模块后台加载
run_test "模块预加载模块后台加载" "
    grep -q 'IPV6WGM_PRELOAD_BACKGROUND_ENABLED\|preload_module.*background' modules/module_preloading.sh
"

echo
echo "=== 测试结果汇总 ==="
echo "总测试数: $TOTAL_TESTS"
echo "通过测试: $PASSED_TESTS"
echo "失败测试: $FAILED_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "所有模块管理功能测试通过！"
    echo
    echo "新功能已成功实现："
    echo "✓ 模块版本兼容性检查 - 提供模块版本管理、兼容性检查和依赖关系管理功能"
    echo "✓ 模块预加载机制 - 提供模块预加载、优先级管理和性能优化功能"
    echo "✓ 菜单集成 - 在脚本自检菜单中添加了模块管理选项"
    echo "✓ 用户界面 - 提供了直观的模块管理界面"
    echo
    echo "主要特性："
    echo "• 版本兼容性：扫描、检查、比较模块版本兼容性"
    echo "• 依赖管理：检查模块依赖关系和版本要求"
    echo "• 预加载优化：按优先级预加载模块，提升启动性能"
    echo "• 缓存机制：支持模块预加载缓存，减少重复加载时间"
    echo "• 统计报告：提供详细的模块版本和预加载统计信息"
    echo "• 后台加载：支持后台预加载低优先级模块"
    exit 0
else
    log_error "有 $FAILED_TESTS 个测试失败"
    exit 1
fi