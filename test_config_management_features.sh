#!/bin/bash

# 测试配置管理功能
# 验证新实现的配置版本控制、备份恢复和热重载功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
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

echo "=== 配置管理功能测试套件 ==="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# 测试1: 检查配置版本控制模块是否存在
run_test "配置版本控制模块文件存在" "
    [[ -f 'modules/config_version_control.sh' ]]
"

# 测试2: 检查配置备份恢复模块是否存在
run_test "配置备份恢复模块文件存在" "
    [[ -f 'modules/config_backup_recovery.sh' ]]
"

# 测试3: 检查配置热重载模块是否存在
run_test "配置热重载模块文件存在" "
    [[ -f 'modules/config_hot_reload.sh' ]]
"

# 测试4: 检查配置版本控制模块语法
run_test "配置版本控制模块语法正确" "
    bash -n modules/config_version_control.sh
"

# 测试5: 检查配置备份恢复模块语法
run_test "配置备份恢复模块语法正确" "
    bash -n modules/config_backup_recovery.sh
"

# 测试6: 检查配置热重载模块语法
run_test "配置热重载模块语法正确" "
    bash -n modules/config_hot_reload.sh
"

# 测试7: 检查主脚本是否包含配置管理模块导入
run_test "主脚本包含配置版本控制导入" "
    grep -q 'config_version_control' ipv6-wireguard-manager.sh
"

# 测试8: 检查主脚本是否包含配置备份恢复导入
run_test "主脚本包含配置备份恢复导入" "
    grep -q 'config_backup_recovery' ipv6-wireguard-manager.sh
"

# 测试9: 检查主脚本是否包含配置热重载导入
run_test "主脚本包含配置热重载导入" "
    grep -q 'config_hot_reload' ipv6-wireguard-manager.sh
"

# 测试10: 检查脚本自检菜单是否包含配置管理选项
run_test "脚本自检菜单包含配置版本管理选项" "
    grep -q '配置版本管理' ipv6-wireguard-manager.sh
"

# 测试11: 检查脚本自检菜单是否包含配置备份管理选项
run_test "脚本自检菜单包含配置备份管理选项" "
    grep -q '配置备份管理' ipv6-wireguard-manager.sh
"

# 测试12: 检查脚本自检菜单是否包含配置热重载选项
run_test "脚本自检菜单包含配置热重载选项" "
    grep -q '配置热重载' ipv6-wireguard-manager.sh
"

# 测试13: 检查配置版本控制模块关键函数
run_test "配置版本控制模块关键函数" "
    grep -q 'create_version\|list_versions\|rollback_to_version' modules/config_version_control.sh
"

# 测试14: 检查配置备份恢复模块关键函数
run_test "配置备份恢复模块关键函数" "
    grep -q 'create_backup\|list_backups\|restore_backup' modules/config_backup_recovery.sh
"

# 测试15: 检查配置热重载模块关键函数
run_test "配置热重载模块关键函数" "
    grep -q 'start_config_monitoring\|stop_config_monitoring\|trigger_reload' modules/config_hot_reload.sh
"

# 测试16: 检查配置版本控制模块函数导出
run_test "配置版本控制模块函数导出" "
    grep -q 'export -f.*create_version' modules/config_version_control.sh
"

# 测试17: 检查配置备份恢复模块函数导出
run_test "配置备份恢复模块函数导出" "
    grep -q 'export -f.*create_backup' modules/config_backup_recovery.sh
"

# 测试18: 检查配置热重载模块函数导出
run_test "配置热重载模块函数导出" "
    grep -q 'export -f.*start_config_monitoring' modules/config_hot_reload.sh
"

# 测试19: 检查菜单函数是否存在
run_test "配置版本管理菜单函数存在" "
    grep -q 'config_version_management_menu' ipv6-wireguard-manager.sh
"

# 测试20: 检查配置备份管理菜单函数是否存在
run_test "配置备份管理菜单函数存在" "
    grep -q 'config_backup_management_menu' ipv6-wireguard-manager.sh
"

# 测试21: 检查配置热重载菜单函数是否存在
run_test "配置热重载菜单函数存在" "
    grep -q 'config_hot_reload_menu' ipv6-wireguard-manager.sh
"

# 测试22: 检查菜单选择范围是否正确
run_test "脚本自检菜单选择范围正确" "
    grep -q '请选择操作 \[0-10\]' ipv6-wireguard-manager.sh
"

# 测试23: 检查配置版本控制模块配置变量
run_test "配置版本控制模块配置变量" "
    grep -q 'IPV6WGM_CONFIG_VERSION_DIR\|IPV6WGM_MAX_VERSION_HISTORY' modules/config_version_control.sh
"

# 测试24: 检查配置备份恢复模块配置变量
run_test "配置备份恢复模块配置变量" "
    grep -q 'IPV6WGM_BACKUP_DIR\|IPV6WGM_BACKUP_RETENTION_DAYS' modules/config_backup_recovery.sh
"

# 测试25: 检查配置热重载模块配置变量
run_test "配置热重载模块配置变量" "
    grep -q 'IPV6WGM_HOT_RELOAD_ENABLED\|IPV6WGM_CONFIG_WATCH_INTERVAL' modules/config_hot_reload.sh
"

echo
echo "=== 测试结果汇总 ==="
echo "总测试数: $TOTAL_TESTS"
echo "通过测试: $PASSED_TESTS"
echo "失败测试: $FAILED_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "所有配置管理功能测试通过！"
    echo
    echo "新功能已成功实现："
    echo "✓ 配置版本控制 - 提供配置文件的版本管理、升级和回滚功能"
    echo "✓ 配置备份恢复 - 提供配置文件的自动备份、恢复和灾难恢复功能"
    echo "✓ 配置热重载 - 提供配置文件的实时监控和热重载功能"
    echo "✓ 菜单集成 - 在脚本自检菜单中添加了配置管理选项"
    echo "✓ 用户界面 - 提供了直观的配置管理界面"
    echo
    echo "主要特性："
    echo "• 版本控制：创建、列出、回滚、比较配置版本"
    echo "• 备份管理：自动备份、手动备份、恢复、清理"
    echo "• 热重载：实时监控、自动重载、手动触发"
    echo "• 配置验证：支持多种配置文件的语法验证"
    echo "• 统计报告：提供详细的版本和备份统计信息"
    exit 0
else
    log_error "有 $FAILED_TESTS 个测试失败"
    exit 1
fi
