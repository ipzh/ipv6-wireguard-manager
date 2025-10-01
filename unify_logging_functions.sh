#!/bin/bash

# 统一日志函数脚本
# 移除重复的日志函数定义，统一使用 common_functions.sh 中的版本

echo "开始统一日志函数..."

# 需要处理的文件列表（排除 common_functions.sh 本身）
files=(
    "ipv6-wireguard-manager.sh"
    "scripts/automated-testing.sh"
    "install.sh"
    "uninstall.sh"
    "scripts/deploy.sh"
    "tests/comprehensive_test_suite.sh"
    "tests/windows_compatibility_test_suite.sh"
    "modules/security_functions.sh"
    "modules/security_audit_monitoring.sh"
    "modules/resource_monitoring.sh"
    "modules/oauth_authentication.sh"
    "modules/update_management.sh"
    "modules/unified_error_handling.sh"
    "modules/client_auto_install.sh"
    "modules/module_preloading.sh"
)

# 日志函数模式
log_functions=(
    "log_debug"
    "log_info"
    "log_warn"
    "log_error"
    "log_success"
    "log_fatal"
)

# 颜色变量模式
color_variables=(
    "RED="
    "GREEN="
    "YELLOW="
    "BLUE="
    "PURPLE="
    "CYAN="
    "WHITE="
    "NC="
)

# 处理每个文件
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "处理文件: $file"
        
        # 创建备份
        cp "$file" "${file}.backup"
        
        # 移除重复的日志函数定义
        for func in "${log_functions[@]}"; do
            # 移除函数定义（从 ^func() { 到对应的 }）
            sed -i "/^${func}() {/,/^}/d" "$file"
        done
        
        # 移除重复的颜色变量定义
        for color in "${color_variables[@]}"; do
            # 移除颜色变量定义行
            sed -i "/^${color}.*\\033/d" "$file"
        done
        
        # 确保文件导入了 common_functions.sh
        if ! grep -q "source.*common_functions.sh" "$file"; then
            # 在文件开头添加导入语句
            sed -i '1i\# 导入公共函数库\nif [[ -f "${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/modules/common_functions.sh" ]]; then\n    source "${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/modules/common_functions.sh"\nfi\n' "$file"
        fi
        
        echo "✓ 已处理: $file"
    else
        echo "⚠ 文件不存在: $file"
    fi
done

echo "日志函数统一完成！"

# 验证结果
echo "验证统一结果..."
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        duplicate_logs=$(grep -c "^log_[a-z_]*() {" "$file" 2>/dev/null || echo "0")
        duplicate_colors=$(grep -c "^[A-Z_]*=.*\\033" "$file" 2>/dev/null || echo "0")
        
        if [[ $duplicate_logs -gt 0 || $duplicate_colors -gt 0 ]]; then
            echo "⚠ $file 仍有重复定义: 日志函数($duplicate_logs), 颜色变量($duplicate_colors)"
        else
            echo "✓ $file 已清理完成"
        fi
    fi
done

echo "统一验证完成！"
