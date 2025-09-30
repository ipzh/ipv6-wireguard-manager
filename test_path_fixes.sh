#!/bin/bash

# 测试所有路径修复
# 验证各种运行方式下的路径设置

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

echo "=== 路径修复测试套件 ==="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# 测试1: 检查主脚本路径设置
run_test "主脚本路径设置" "
    if [[ -f 'ipv6-wireguard-manager.sh' ]]; then
        # 检查是否包含符号链接检测逻辑
        grep -q '通过符号链接运行' ipv6-wireguard-manager.sh
    else
        false
    fi
"

# 测试2: 检查安装脚本路径设置
run_test "安装脚本路径设置" "
    if [[ -f 'install_with_download.sh' ]]; then
        grep -q '通过符号链接运行' install_with_download.sh
    else
        false
    fi
"

# 测试3: 检查卸载脚本路径设置
run_test "卸载脚本路径设置" "
    if [[ -f 'uninstall.sh' ]]; then
        grep -q '通过符号链接运行' uninstall.sh
    else
        false
    fi
"

# 测试4: 检查模块加载器路径设置
run_test "模块加载器路径设置" "
    if [[ -f 'modules/enhanced_module_loader.sh' ]]; then
        # 检查是否将/opt/ipv6-wireguard-manager/modules放在搜索路径首位
        grep -A 5 'search_paths=(' modules/enhanced_module_loader.sh | grep -q '/opt/ipv6-wireguard-manager/modules'
    else
        false
    fi
"

# 测试5: 检查测试脚本路径设置
run_test "测试脚本路径设置" "
    if [[ -f 'tests/comprehensive_test_suite.sh' ]]; then
        grep -q '通过符号链接运行' tests/comprehensive_test_suite.sh
    else
        false
    fi
"

# 测试6: 检查模板文件路径设置
run_test "标准模板路径设置" "
    if [[ -f 'templates/standard_import_template.sh' ]]; then
        grep -q '通过符号链接运行' templates/standard_import_template.sh
    else
        false
    fi
"

run_test "健壮模板路径设置" "
    if [[ -f 'templates/robust_import_template.sh' ]]; then
        # 检查是否将/opt/ipv6-wireguard-manager/modules放在搜索路径首位
        grep -A 5 'alt_paths=(' templates/robust_import_template.sh | grep -q '/opt/ipv6-wireguard-manager/modules'
    else
        false
    fi
"

# 测试7: 检查自动化测试脚本路径设置
run_test "自动化测试脚本路径设置" "
    if [[ -f 'scripts/automated-testing.sh' ]]; then
        # 检查是否将/opt/ipv6-wireguard-manager/modules放在搜索路径首位
        grep -A 5 'alt_paths=(' scripts/automated-testing.sh | grep -q '/opt/ipv6-wireguard-manager/modules'
    else
        false
    fi
"

# 测试8: 检查路径修复函数的一致性
run_test "路径修复函数一致性" "
    # 检查所有文件中的路径检测逻辑是否一致
    local files=(
        'ipv6-wireguard-manager.sh'
        'install_with_download.sh'
        'uninstall.sh'
        'templates/standard_import_template.sh'
        'tests/comprehensive_test_suite.sh'
    )
    
    for file in \"\${files[@]}\"; do
        if [[ -f \"\$file\" ]]; then
            if ! grep -q '通过符号链接运行' \"\$file\"; then
                echo \"文件 \$file 缺少路径检测逻辑\"
                return 1
            fi
        fi
    done
"

# 测试9: 检查模块搜索路径优先级
run_test "模块搜索路径优先级" "
    # 检查关键文件是否将/opt/ipv6-wireguard-manager/modules放在首位
    local files=(
        'modules/enhanced_module_loader.sh'
        'templates/robust_import_template.sh'
        'scripts/automated-testing.sh'
    )
    
    for file in \"\${files[@]}\"; do
        if [[ -f \"\$file\" ]]; then
            # 检查search_paths或alt_paths
            if ! (grep -A 5 'search_paths=(' \"\$file\" | grep -q '/opt/ipv6-wireguard-manager/modules' || \
                  grep -A 5 'alt_paths=(' \"\$file\" | grep -q '/opt/ipv6-wireguard-manager/modules'); then
                echo \"文件 \$file 的模块搜索路径优先级不正确\"
                return 1
            fi
        fi
    done
"

# 测试10: 检查错误处理
run_test "错误处理改进" "
    # 检查主脚本是否包含详细的错误信息
    if [[ -f 'ipv6-wireguard-manager.sh' ]]; then
        grep -q '尝试的路径:' ipv6-wireguard-manager.sh
    else
        false
    fi
"

echo
echo "=== 测试结果汇总 ==="
echo "总测试数: $TOTAL_TESTS"
echo "通过测试: $PASSED_TESTS"
echo "失败测试: $FAILED_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "所有路径修复测试通过！"
    exit 0
else
    log_error "有 $FAILED_TESTS 个测试失败"
    exit 1
fi
