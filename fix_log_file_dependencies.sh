#!/bin/bash

# 批量修复模块文件中的LOG_FILE变量依赖问题

echo "=== 开始修复模块文件中的LOG_FILE依赖问题 ==="

# 需要修复的模块文件列表
modules=(
    "modules/api_documentation.sh"
    "modules/backup_restore.sh"
    "modules/bird_config.sh"
    "modules/client_auto_install.sh"
    "modules/client_management.sh"
    "modules/config_management.sh"
    "modules/error_handling.sh"
    "modules/firewall_management.sh"
    "modules/firewall_ports.sh"
    "modules/lazy_loading.sh"
    "modules/monitoring_alerting.sh"
    "modules/multi_tenant.sh"
    "modules/network_management.sh"
    "modules/network_topology.sh"
    "modules/oauth_authentication.sh"
    "modules/performance_enhancements.sh"
    "modules/performance_optimization.sh"
    "modules/repository_config.sh"
    "modules/resource_quota.sh"
    "modules/security_audit_monitoring.sh"
    "modules/system_detection.sh"
    "modules/update_management.sh"
    "modules/user_interface.sh"
    "modules/web_interface_enhanced.sh"
    "modules/web_management.sh"
    "modules/websocket_realtime.sh"
    "modules/wireguard_config.sh"
)

# 修复函数
fix_module() {
    local module_file="$1"
    echo "修复 $module_file..."
    
    # 检查是否已经导入了common_functions.sh
    if ! grep -q "source.*common_functions.sh" "$module_file"; then
        echo "  - 添加common_functions.sh导入"
        # 在文件开头添加导入
        sed -i '1a\
# 导入公共函数库\
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then\
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"\
fi' "$module_file"
    fi
    
    # 检查是否已经定义了LOG_FILE变量
    if ! grep -q "LOG_FILE=" "$module_file"; then
        echo "  - 添加LOG_FILE变量定义"
        # 在导入后添加LOG_FILE定义
        sed -i '/source.*common_functions.sh/a\
\
# 确保日志相关变量已定义\
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"\
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"' "$module_file"
    fi
    
    echo "  ✓ $module_file 修复完成"
}

# 批量修复所有模块
for module in "${modules[@]}"; do
    if [[ -f "$module" ]]; then
        fix_module "$module"
    else
        echo "⚠ 文件不存在: $module"
    fi
done

echo "=== 所有模块文件修复完成 ==="
