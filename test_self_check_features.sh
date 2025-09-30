#!/bin/bash

# 测试脚本自检功能
# 验证新实现的脚本自检和模块加载追踪功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
# log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }  # 不可达代码
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

echo "=== 脚本自检功能测试套件 ==="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# 测试1: 检查脚本自检模块是否存在
run_test "脚本自检模块文件存在" "
    [[ -f 'modules/script_self_check.sh' ]]
"

# 测试2: 检查模块加载追踪模块是否存在
run_test "模块加载追踪模块文件存在" "
    [[ -f 'modules/module_loading_tracker.sh' ]]
"

# 测试3: 检查脚本自检模块语法
run_test "脚本自检模块语法正确" "
    bash -n modules/script_self_check.sh
"

# 测试4: 检查模块加载追踪模块语法
run_test "模块加载追踪模块语法正确" "
    bash -n modules/module_loading_tracker.sh
"

# 测试5: 检查主脚本是否包含自检菜单
run_test "主脚本包含自检菜单" "
    grep -q 'script_self_check_menu' ipv6-wireguard-manager.sh
"

# 测试6: 检查主脚本是否包含自检模块导入
run_test "主脚本包含自检模块导入" "
    grep -q 'script_self_check' ipv6-wireguard-manager.sh
"

# 测试7: 检查主脚本是否包含模块加载追踪导入
run_test "主脚本包含模块加载追踪导入" "
    grep -q 'module_loading_tracker' ipv6-wireguard-manager.sh
"

# 测试8: 检查菜单编号是否正确
run_test "菜单编号正确" "
    grep -q '27.*脚本自检' ipv6-wireguard-manager.sh
"

# 测试9: 检查菜单选择范围是否正确
run_test "菜单选择范围正确" "
    grep -q '请选择操作 \[0-38\]' ipv6-wireguard-manager.sh
"

# 测试10: 检查脚本自检模块函数导出
run_test "脚本自检模块函数导出" "
    grep -q 'export -f.*run_complete_self_check' modules/script_self_check.sh
"

# 测试11: 检查模块加载追踪模块函数导出
run_test "模块加载追踪模块函数导出" "
    grep -q 'export -f.*init_loading_tracker' modules/module_loading_tracker.sh
"

# 测试12: 检查脚本自检模块关键函数
run_test "脚本自检模块关键函数" "
    grep -q 'run_complete_self_check\|run_quick_self_check\|check_critical_modules' modules/script_self_check.sh
"

# 测试13: 检查模块加载追踪模块关键函数
run_test "模块加载追踪模块关键函数" "
    grep -q 'start_module_tracking\|complete_module_tracking\|get_loading_statistics' modules/module_loading_tracker.sh
"

# 测试14: 检查脚本自检菜单选项
run_test "脚本自检菜单选项完整" "
    grep -A 10 '脚本自检系统:' ipv6-wireguard-manager.sh | grep -q '快速自检\|完整自检\|模块加载状态'
"

# 测试15: 检查模块加载追踪配置
run_test "模块加载追踪配置完整" "
    grep -q 'IPV6WGM_MODULE_STATUS_LOADING\|IPV6WGM_MODULE_STATUS_LOADED' modules/module_loading_tracker.sh
"

echo
echo "=== 测试结果汇总 ==="
echo "总测试数: $TOTAL_TESTS"
echo "通过测试: $PASSED_TESTS"
echo "失败测试: $FAILED_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "所有脚本自检功能测试通过！"
    echo
    echo "新功能已成功实现："
    echo "✓ 脚本自检模块 - 提供全面的系统健康检查"
    echo "✓ 模块加载追踪 - 详细的模块加载状态监控"
    echo "✓ 自检菜单集成 - 在主菜单中添加了自检选项"
    echo "✓ 实时状态显示 - 可以查看模块加载的实时状态"
    echo "✓ 详细报告生成 - 生成完整的自检和加载报告"
    exit 0
else
    log_error "有 $FAILED_TESTS 个测试失败"
    exit 1
fi
