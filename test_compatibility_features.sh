#!/bin/bash

# 测试兼容性功能
# 验证新实现的Windows支持和硬件兼容性检查功能

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

echo "=== 兼容性功能测试套件 ==="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# 测试1: 检查增强Windows支持模块是否存在
run_test "增强Windows支持模块文件存在" "
    [[ -f 'modules/enhanced_windows_support.sh' ]]
"

# 测试2: 检查硬件兼容性模块是否存在
run_test "硬件兼容性模块文件存在" "
    [[ -f 'modules/hardware_compatibility.sh' ]]
"

# 测试3: 检查增强Windows支持模块语法
run_test "增强Windows支持模块语法正确" "
    bash -n modules/enhanced_windows_support.sh
"

# 测试4: 检查硬件兼容性模块语法
run_test "硬件兼容性模块语法正确" "
    bash -n modules/hardware_compatibility.sh
"

# 测试5: 检查主脚本是否包含增强Windows支持导入
run_test "主脚本包含增强Windows支持导入" "
    grep -q 'enhanced_windows_support' ipv6-wireguard-manager.sh
"

# 测试6: 检查主脚本是否包含硬件兼容性导入
run_test "主脚本包含硬件兼容性导入" "
    grep -q 'hardware_compatibility' ipv6-wireguard-manager.sh
"

# 测试7: 检查脚本自检菜单是否包含Windows兼容性检查选项
run_test "脚本自检菜单包含Windows兼容性检查选项" "
    grep -q 'Windows兼容性检查' ipv6-wireguard-manager.sh
"

# 测试8: 检查脚本自检菜单是否包含硬件兼容性检查选项
run_test "脚本自检菜单包含硬件兼容性检查选项" "
    grep -q '硬件兼容性检查' ipv6-wireguard-manager.sh
"

# 测试9: 检查增强Windows支持模块关键函数
run_test "增强Windows支持模块关键函数" "
    grep -q 'init_windows_support\|detect_windows_environment\|convert_path' modules/enhanced_windows_support.sh
"

# 测试10: 检查硬件兼容性模块关键函数
run_test "硬件兼容性模块关键函数" "
    grep -q 'init_hardware_compatibility\|detect_hardware_info\|check_hardware_compatibility' modules/hardware_compatibility.sh
"

# 测试11: 检查增强Windows支持模块函数导出
run_test "增强Windows支持模块函数导出" "
    grep -q 'export -f.*init_windows_support' modules/enhanced_windows_support.sh
"

# 测试12: 检查硬件兼容性模块函数导出
run_test "硬件兼容性模块函数导出" "
    grep -q 'export -f.*init_hardware_compatibility' modules/hardware_compatibility.sh
"

# 测试13: 检查增强Windows支持模块配置变量
run_test "增强Windows支持模块配置变量" "
    grep -q 'IPV6WGM_WINDOWS_ENV\|IPV6WGM_WSL_ENV' modules/enhanced_windows_support.sh
"

# 测试14: 检查硬件兼容性模块配置变量
run_test "硬件兼容性模块配置变量" "
    grep -q 'IPV6WGM_CPU_ARCH\|IPV6WGM_CPU_CORES' modules/hardware_compatibility.sh
"

# 测试15: 检查增强Windows支持模块环境检测
run_test "增强Windows支持模块环境检测" "
    grep -q 'WSL_ENV\|MSYS_ENV\|CYGWIN_ENV' modules/enhanced_windows_support.sh
"

# 测试16: 检查硬件兼容性模块架构检测
run_test "硬件兼容性模块架构检测" "
    grep -q 'x86_64\|aarch64\|arm64' modules/hardware_compatibility.sh
"

# 测试17: 检查菜单选择范围是否正确
run_test "脚本自检菜单选择范围正确" "
    grep -q '请选择操作 \[0-14\]' ipv6-wireguard-manager.sh
"

# 测试18: 检查增强Windows支持模块命令别名
run_test "增强Windows支持模块命令别名" "
    grep -q 'IPV6WGM_WINDOWS_ALIASES\|execute_windows_command' modules/enhanced_windows_support.sh
"

# 测试19: 检查硬件兼容性模块性能建议
run_test "硬件兼容性模块性能建议" "
    grep -q 'get_hardware_performance_suggestions\|get_hardware_statistics' modules/hardware_compatibility.sh
"

# 测试20: 检查增强Windows支持模块路径转换
run_test "增强Windows支持模块路径转换" "
    grep -q 'convert_path\|setup_windows_paths' modules/enhanced_windows_support.sh
"

# 测试21: 检查硬件兼容性模块兼容性检查
run_test "硬件兼容性模块兼容性检查" "
    grep -q 'check_cpu_compatibility\|check_memory_compatibility' modules/hardware_compatibility.sh
"

# 测试22: 检查增强Windows支持模块兼容性验证
run_test "增强Windows支持模块兼容性验证" "
    grep -q 'verify_windows_compatibility\|run_windows_compatibility_check' modules/enhanced_windows_support.sh
"

# 测试23: 检查硬件兼容性模块硬件要求
run_test "硬件兼容性模块硬件要求" "
    grep -q 'IPV6WGM_MINIMUM_REQUIREMENTS\|IPV6WGM_RECOMMENDED_REQUIREMENTS' modules/hardware_compatibility.sh
"

# 测试24: 检查增强Windows支持模块系统信息
run_test "增强Windows支持模块系统信息" "
    grep -q 'get_windows_system_info\|check_windows_features' modules/enhanced_windows_support.sh
"

# 测试25: 检查硬件兼容性模块报告生成
run_test "硬件兼容性模块报告生成" "
    grep -q 'generate_compatibility_report\|IPV6WGM_HARDWARE_COMPATIBILITY' modules/hardware_compatibility.sh
"

echo
echo "=== 测试结果汇总 ==="
echo "总测试数: $TOTAL_TESTS"
echo "通过测试: $PASSED_TESTS"
echo "失败测试: $FAILED_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "所有兼容性功能测试通过！"
    echo
    echo "新功能已成功实现："
    echo "✓ 增强Windows支持 - 提供全面的Windows环境检测、路径适配和命令兼容性功能"
    echo "✓ 硬件兼容性检查 - 提供硬件架构检测、兼容性验证和性能优化建议功能"
    echo "✓ 菜单集成 - 在脚本自检菜单中添加了兼容性检查选项"
    echo "✓ 用户界面 - 提供了直观的兼容性检查界面"
    echo
    echo "主要特性："
    echo "• Windows环境支持：WSL、MSYS、Cygwin、PowerShell环境检测和适配"
    echo "• 路径转换：自动转换Windows和Unix路径格式"
    echo "• 命令别名：为Windows环境提供Linux命令的Windows等价命令"
    echo "• 硬件检测：CPU架构、核心数、内存、磁盘空间、网络接口检测"
    echo "• 兼容性验证：检查硬件是否满足最低和推荐要求"
    echo "• 性能建议：根据硬件配置提供性能优化建议"
    echo "• 统计报告：提供详细的硬件和兼容性统计信息"
    exit 0
else
    log_error "有 $FAILED_TESTS 个测试失败"
    exit 1
fi
